---
title: "Installing Servarr Stack with Docker Compose"
pathname: "/proxmox-servarr-stack"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
- servarr
---

This guide is a part of a series on Proxmox for Homelabs. You can find the [Series Overview here](/proxmox-series).

This guide will cover setting up the [Servarr Stack](https://wiki.servarr.com/) using Docker Compose. It requires that you have setup bind mounts for the LXC Container, which is covered in [this guide](/proxmox-zfs-mounts).

## Docker Compose

If you are using Proxmox there is a [helper script](https://tteck.github.io/Proxmox/) that will install Docker in an LXC, and give you the option to add Portainer. I used this, since it exposes a nice UI for managing Docker Compose "stacks". I recommend it.

Once that is up and running you just need a good compose file. I had a ton of trouble finding one, but eventually found one that was almost perfect. You can [find it here](https://github.com/geekau/media-stack), along with a helpful step-by-step [companion guide](https://www.synoforum.com/resources/ultimate-starter-page-1-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.184/). I ended up trimming out a lot that I didn't need, and had to make several tweaks to get things working, so I will put my compose and env files below.

This should get you most of the way, and the [Trash Guides](https://trash-guides.info/) cover folder structure and quality profiles well.

> Yeah, this guide is pretty light on details, but the step-by-step guide is so thorough I don't have much to add.

**Compose Yaml**
```yaml
version: "3.8"

networks:
  media-network:
    name: media-network
    driver: bridge

###########################################################################
##  Docker Compose File:    Gluetun (qmcgaw)
##  Function:               VPN Client
##  Documentation:          https://github.com/qdm12/gluetun-wiki
###########################################################################
services:
  gluetun:
    image: qmcgaw/gluetun:v3.35.0
    container_name: gluetun
    restart: always
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - "8888:8888/tcp"                         # Gluetun Local Network HTTP proxy
      - "8388:8388/tcp"                         # Gluetun Local Network Shadowsocks
      - "8388:8388/udp"                         # Gluetun Local Network Shadowsocks
      - "${WEBUI_PORT_QBITTORRENT:?err}:${WEBUI_PORT_QBITTORRENT:?err}"   # WebUI Portal: qBittorrent
      - "${QBIT_PORT_TCP:?err}:6881/tcp"        # Transmission Torrent Port TCP
      - "${QBIT_PORT_UDP:?err}:6881/udp"        # Transmission Torrent Port UDP

    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/gluetun:/gluetun
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - TZ=${TIMEZONE:?err}
      - VPN_SERVICE_PROVIDER=${VPN_SERVICE_PROVIDER:?err}
      # - OPENVPN_USER=${VPN_USERNAME}
      # - OPENVPN_PASSWORD=${VPN_PASSWORD}
      - SERVER_REGIONS=${SERVER_REGIONS:?err}
      - SERVER_COUNTRIES=${SERVER_COUNTRIES}
      - SERVER_CITIES=${SERVER_CITIES}
      - SERVER_HOSTNAMES=${SERVER_HOSTNAMES}
      - FIREWALL_OUTBOUND_SUBNETS=${LOCAL_SUBNET:?err}
      - OPENVPN_CUSTOM_CONFIG=${OPENVPN_CUSTOM_CONFIG}
      - VPN_TYPE=${VPN_TYPE}
      - VPN_ENDPOINT_IP=${VPN_ENDPOINT_IP}
      - VPN_ENDPOINT_PORT=${VPN_ENDPOINT_PORT}
      - WIREGUARD_PUBLIC_KEY=${WIREGUARD_PUBLIC_KEY}
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_PRESHARED_KEY=${WIREGUARD_PRESHARED_KEY}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
      - HTTPPROXY=on
      - SHADOWSOCKS=on

# NOTE: Gluetun VPN container MUST ONLY connect to the media-network

    networks:
      - media-network

###########################################################################
##  Docker Compose File:  qBittorrent (LinuxServer.io)
##  Function:             Torrent Download Client
##  Documentation:        https://docs.linuxserver.io/images/docker-qbittorrent
###########################################################################
  qbittorrent:
    image: linuxserver/qbittorrent:4.6.0
    container_name: qbittorrent
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/qbittorrent:/config
      - ${FOLDER_FOR_MEDIA:?err}:/data
    # depends_on:
    #   gluetun:
    #     condition: service_healthy
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - UMASK=${UMASK:?err}
      - TZ=${TIMEZONE:?err}
      - WEBUI_PORT=${WEBUI_PORT_QBITTORRENT:?err}
      # - DOCKER_MODS=ghcr.io/gilbn/theme.park:qbittorrent
      # - TP_THEME=${TP_THEME:?err}

## Do Not Change Network for qBittorrent
## qBittorrent MUST always use a VPN / Secure Internet connection

    network_mode: "service:gluetun"

###########################################################################
##  Docker Compose File:  SABnzbd (LinuxServer.io)
##  Function:             Usenet Download Client
##  Documentation:        https://docs.linuxserver.io/images/docker-sabnzbd
###########################################################################
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/sabnzbd:/config
      - ${FOLDER_FOR_MEDIA:?err}:/data

    ports:
      - "${WEBUI_PORT_SABNZBD:?err}:8080"
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - TZ=${TIMEZONE:?err}
      - DOCKER_MODS=ghcr.io/gilbn/theme.park:sabnzbd
      - TP_THEME=${TP_THEME:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Bazarr (LinuxServer.io)
##  Function:             Download subtitles for Radarr and Sonarr
##  Documentation:        https://docs.linuxserver.io/images/docker-bazarr
###########################################################################
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/bazarr:/config
      - ${FOLDER_FOR_MEDIA:?err}:/data
    ports:
      - "${WEBUI_PORT_BAZARR:?err}:6767"
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - TZ=${TIMEZONE:?err}
      # - DOCKER_MODS=ghcr.io/gilbn/theme.park:bazarr
      # - TP_THEME=${TP_THEME:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Jellyfin (LinuxServer.io)
##  Function:             Media Server
##  Documentation:        https://jellyfin.org/docs/general/administration/installing#docker
##                        https://jellyfin.org/docs/general/administration/hardware-acceleration/
###########################################################################
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    # Hardware Acceleration
    devices:
      - /dev/dri:/dev/dri
      - /dev/kfd:/dev/kfd
    group_add:
      - "106" # Change this to match your "render" host group id and remove this comment
      - "44" # Change this to match your "video" host group id and remove this comment
    # End Hardware Acceleration
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/jellyfin:/config
      - ${FOLDER_FOR_MEDIA:?err}/media:/data/media
    ports:
      - "${WEBUI_PORT_JELLYFIN:?err}:8096"
#      - 7359:7359/udp      # Enable for DLNA - Only works on HOST Network Mode
#      - 1900:1900/udp      # Enable for DLNA - Only works on HOST Network Mode
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - UMASK=${UMASK:?err}
      - TZ=${TIMEZONE:?err}
      - ROC_ENABLE_PRE_VEGA=1 # Hardware Acceleration
      - DOCKER_MODS=linuxserver/mods:jellyfin-amd
#      - JELLYFIN_PublishedServerUrl=${LOCAL_DOCKER_IP:?err}  # Enable for DLNA - Only works on HOST Network Mode
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Jellyseerr (fallenbagel)
##  Function:             Media Request Manager
##  Documentation:        https://hub.docker.com/r/fallenbagel/jellyseerr
###########################################################################
  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/jellyseerr:/app/config
    ports:
      - "${WEBUI_PORT_JELLYSEERR:?err}:5055"
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - UMASK=${UMASK:?err}
      - TZ=${TIMEZONE:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Lidarr (LinuxServer.io)
##  Function:             Music Library Manager
##  Documentation:        https://docs.linuxserver.io/images/docker-lidarr
###########################################################################
  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    container_name: lidarr
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/lidarr:/config
      - ${FOLDER_FOR_MEDIA:?err}:/data
    ports:
      - "${WEBUI_PORT_LIDARR:?err}:8686"
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - TZ=${TIMEZONE:?err}
      - DOCKER_MODS=ghcr.io/gilbn/theme.park:lidarr
      - TP_THEME=${TP_THEME:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Prowlarr (LinuxServer.io)
##  Function:             Indexer and Search Manager
##  Documentation:        https://docs.linuxserver.io/images/docker-prowlarr
###########################################################################
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/prowlarr:/config
    ports:
      - "${WEBUI_PORT_PROWLARR:?err}:9696"
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - TZ=${TIMEZONE:?err}
      - DOCKER_MODS=ghcr.io/gilbn/theme.park:prowlarr
      - TP_THEME=${TP_THEME:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Radarr (LinuxServer.io)
##  Function:             Movie Library Manager
##  Documentation:        https://docs.linuxserver.io/images/docker-radarr
###########################################################################
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/radarr:/config
      - ${FOLDER_FOR_MEDIA:?err}:/data
    ports:
      - "${WEBUI_PORT_RADARR:?err}:7878"
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - TZ=${TIMEZONE:?err}
      - DOCKER_MODS=ghcr.io/gilbn/theme.park:radarr
      - TP_THEME=${TP_THEME:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Sonarr (LinuxServer.io)
##  Function:             Series Library Manager (TV Shows)
##  Documentation:        https://docs.linuxserver.io/images/docker-sonarr
###########################################################################
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/sonarr:/config
      - ${FOLDER_FOR_MEDIA:?err}:/data
    ports:
      - "${WEBUI_PORT_SONARR:?err}:8989"
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - TZ=${TIMEZONE:?err}
      - DOCKER_MODS=ghcr.io/gilbn/theme.park:sonarr
      - TP_THEME=${TP_THEME:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Flaresolverr (Flaresolverr)
##  Function:             Cloudflare Proxy Server
##  Documentation:        https://github.com/FlareSolverr/FlareSolverr
###########################################################################
  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flaresolverr
    restart: unless-stopped
    ports:
      - "${FLARESOLVERR_PORT:?err}:8191"
    environment:
      - LOG_LEVEL=info
      - LOG_HTML=false
      - CAPTCHA_SOLVER=none
      - TZ=${TIMEZONE:?err}
    networks:
      - media-network

###########################################################################
##  Docker Compose File:  Unpackerr (Hotio.Dev)
##  Function:             Archive Media Extraction
##  Documentation:        https://github.com/davidnewhall/unpackerr
##                        https://github.com/davidnewhall/unpackerr/blob/master/examples/docker-compose.yml
###########################################################################
  unpackerr:
    image: golift/unpackerr:latest
    container_name: unpackerr
    restart: unless-stopped
    volumes:
      - ${FOLDER_FOR_CONFIGS:?err}/unpackerr:/config
      - ${FOLDER_FOR_MEDIA:?err}/:/data
    environment:
      - PUID=${PUID:?err}
      - PGID=${PGID:?err}
      - UMASK=${UMASK:?err}
      - TZ=${TIMEZONE:?err}
# Documentation on all Environment Variables can be found at:
# https://github.com/davidnewhall/unpackerr#docker-env-variables
      - UN_DEBUG=false
      - UN_LOG_FILE=
      - UN_LOG_FILES=10
      - UN_LOG_FILE_MB=10
      - UN_INTERVAL=2m
      - UN_START_DELAY=1m
      - UN_RETRY_DELAY=5m
      - UN_MAX_RETRIES=3
      - UN_PARALLEL=1
      - UN_FILE_MODE=0664
      - UN_DIR_MODE=0775
      # Sonarr Config - Copy API Key from: http://sonarr:8989/general/settings
      - UN_SONARR_0_URL=http://sonarr:8989
      - UN_SONARR_0_API_KEY=${SONARR_API_KEY}
      - UN_SONARR_0_PATHS_0=/data/torrents/anime
      - UN_SONARR_0_PATHS_1=/data/torrents/series
      - UN_SONARR_0_PROTOCOLS=torrent
      - UN_SONARR_0_TIMEOUT=10s
      - UN_SONARR_0_DELETE_ORIG=false
      - UN_SONARR_0_DELETE_DELAY=5m
      # Radarr Config - Copy API Key from: http://radarr:7878/general/settings
      - UN_RADARR_0_URL=http://radarr:7878
      - UN_RADARR_0_API_KEY=${RADARR_API_KEY}
      - UN_RADARR_0_PATHS_0=/data/torrents/movies
      - UN_RADARR_0_PROTOCOLS=torrent
      - UN_RADARR_0_TIMEOUT=10s
      - UN_RADARR_0_DELETE_ORIG=false
      - UN_RADARR_0_DELETE_DELAY=5m
      # Lidarr Config - Copy API Key from: http://lidarr:8686/general/settings
      - UN_LIDARR_0_URL=http://lidarr:8686
      - UN_LIDARR_0_API_KEY=${LIDARR_API_KEY}
      - UN_LIDARR_0_PATHS_0=/data/torrents/music
      - UN_LIDARR_0_PROTOCOLS=torrent
      - UN_LIDARR_0_TIMEOUT=10s
      - UN_LIDARR_0_DELETE_ORIG=false
      - UN_LIDARR_0_DELETE_DELAY=5m
    security_opt:
      - no-new-privileges:true
    network_mode: none
```

Env File
```toml
#Name of the project in Docker
COMPOSE_PROJECT_NAME=media-stack

# This is the network subnet which will be used inside the docker "media_network", change as required.
# LOCAL_SUBNET is your home network and is needed so the VPN client allows access to your home computers.
DOCKER_SUBNET=172.28.10.0/24
DOCKER_GATEWAY=172.28.10.1
LOCAL_SUBNET=192.168.0.0/24
LOCAL_DOCKER_IP=10.168.1.10

# Each of the "*ARR" applications have been configured so the theme can be changed to your needs.
# Refer to Theme Park for more info / options: https://docs.theme-park.dev/theme-options/aquamarine/
TP_THEME=organizr

# These are the folders on your local host computer / NAS running docker, they MUST exist
# and have correct permissions for PUID and PGUI prior to running the docker-compose.
#
# Use the commands in the Guide to create all the sub-folders in each of these folders.

# Host Data Folders - Will accept Linux, Windows, NAS folders
FOLDER_FOR_CONFIGS=/mnt/app_config
FOLDER_FOR_MEDIA=/mnt/media_root

# File access, date and time details for the containers / applications to use.
# Run "sudo id docker" on host computer to find PUID / PGID and update these to suit.
PUID=1000
PGID=10000
UMASK=0002
TIMEZONE=America/Los_Angeles

# Update your own Internet VPN provide details below
VPN_TYPE=wireguard
VPN_SERVICE_PROVIDER=nordvpn
SERVER_REGIONS=America
SERVER_COUNTRIES=United States
SERVER_CITIES=Seattle
SERVER_HOSTNAMES=

# Fill in this item ONLY if you're using a custom OpenVPN configuration
# Should be inside gluetun data folder - Example: /gluetun/custom-openvpn.conf
# You can then edit it inside the FOLDER_FOR_CONFIGS location for gluetun.
VPN_USERNAME=
VPN_PASSWORD=
OPENVPN_CUSTOM_CONFIG=

# Fill in these items ONLY if you change VPN_TYPE to "wireguard"
VPN_ENDPOINT_IP=
VPN_ENDPOINT_PORT=
WIREGUARD_PUBLIC_KEY=
WIREGUARD_PRIVATE_KEY=_PUT YOUR KEY HERE_
WIREGUARD_PRESHARED_KEY=
WIREGUARD_ADDRESSES=

# These are the default ports used to access each of the application in your web browser.
# You can safely change these if you need, but they can't conflict with other active ports.
QBIT_PORT_TCP=6881
QBIT_PORT_UDP=6881
FLARESOLVERR_PORT=8191

TDARR_SERVER_PORT=8266
WEBUI_PORT_TDARR=8265

WEBUI_PORT_BAZARR=6767
WEBUI_PORT_DDNS_UPDATER=6500
WEBUI_PORT_JELLYFIN=8096
WEBUI_PORT_JELLYSEERR=5055
WEBUI_PORT_LIDARR=8686
WEBUI_PORT_MYLAR3=8090
WEBUI_PORT_PORTAINER=9443
WEBUI_PORT_PROWLARR=9696
WEBUI_PORT_QBITTORRENT=8200
WEBUI_PORT_RADARR=7878
WEBUI_PORT_READARR=8787
WEBUI_PORT_SONARR=8989
WEBUI_PORT_SABNZBD=8100
WEBUI_PORT_WHISPARR=6969

RADARR_API_KEY=_GET THIS FROM THE RADARR UI_
SONARR_API_KEY=_GET THIS FROM THE SONARR UI_
LIDARR_API_KEY=_GET THIS FROM THE LIDARR UI_
```

## Configuring Apps

I highly recommend checking out [Trash Guides](https://trash-guides.info/) for details on setting up the Servarr Apps. For official docs check the [Servarr wiki](https://wiki.servarr.com/)