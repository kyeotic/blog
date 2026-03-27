---
title: "Proxmox SMB Shares with Debian"
url: "/proxmox-samba"
date: 2026-02-01
tags:
- homelab
- proxmox
- nas
- smb
---

This guide is a part of a series on Proxmox for Homelabs. You can find the [Series Overview here](/proxmox-series).

The [original version of this guide](/proxmox-cockpit) used cockpit. It has a nice UI, but the installation process requires downloading several files, necessary addons, and then doing configuration through that UI. It also uses more system resources than necessary to run that UI server.

When I moved to a more infrastructure-as-code approach for my homelab, heavily using [ansible](https://docs.ansible.com/projects/ansible/latest/index.html), the UI configuration of cockpit was a problem. Luckily setting up samba on debian "bare metal" isn't that hard, can be fully scripted, and doesn't need a web server to run the cockpit UI.

If you want to skip to the ansible roles I use to [create the LXC on proxmox](https://github.com/kyeotic/homelab/tree/main/infra/proxmox/roles/samba-lxc) and [setup samba](https://github.com/kyeotic/homelab/tree/main/infra/proxmox/roles/samba-config), theres the source code.

# The Plan

1. Create an LXC container with debian to run samba
2. Use mount points to get the folders-to-share into samba
3. Create a mapped user that can access the shares
4. Install Samba and Configure it

## 1. Creating the LXC

This is pretty standard, I wont bog you down with the details. Make an LXC with debian as the template.

This is what I used, but you can probably get away with 1 core and 4GB disk.

```
CORES=2
MEMORY=1024
SWAP=512
DISK=8
```

## 2. Create Mount Points

Run this on the proxmox host. Replace with your own directories, and set the `VMID`

```bash
pct set "$VMID" --mp0 /tank/nas,mp=/mnt/nas
pct set "$VMID" --mp1 /tank/apps,mp=/mnt/apps
pct set "$VMID" --mp2 /tank/media_root,mp=/mnt/media_root
```

# 3. Create a mapped user

As the [mount points guide](/proxmox-zfs-mounts) explains we want a user with the right ID and GID to access the mounts.

Run these commands on the samba LXC to create that user.

> If you setup your mount points with different mappings, replace the IDs and group name below

```bash
groupadd -g "10000" "nas_shares" 2>/dev/null || true
useradd -u "1000" -s /usr/sbin/nologin -M -G "nas_shares" "$USERNAME_FOR_SAMBA" 2>/dev/null || true
```

# 4. Install Samba and configure it

Run these on the Samba LXC

```bash
SAMBA_USER="tkye"
SAMBA_PASSWORD="changeme"

apt-get update
apt-get install -y samba acl

printf '%s\n%s\n' "$SAMBA_PASSWORD" "$SAMBA_PASSWORD" | smbpasswd -s -a "$SAMBA_USER"

# Create share directories with correct ownership
for dir in /mnt/nas /mnt/media_root /mnt/apps; do
  mkdir -p "$dir"
  chown "${SAMBA_USER}:${SAMBA_USER}" "$dir"
  chmod 0775 "$dir"
done

# Write smb.conf
cat > /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   log file = /var/log/samba/log.%m
   max log size = 50
   dns proxy = no
   map to guest = never
   min protocol = SMB2

   # macOS compatibility (fruit VFS)
   vfs objects = fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:posix_rename = yes
   fruit:veto_appledouble = no
   fruit:nfs_aces = no
   fruit:wipe_intentionally_left_blank_rfork = yes
   fruit:delete_empty_adfiles = yes

[nas]
   path = /mnt/nas
   comment = NAS Share
   read only = no
   browseable = yes
   valid users = tkye
   force user = tkye
   force group = nas_shares
   create mask = 0664
   directory mask = 0775

[media]
   path = /mnt/media_root
   comment = Media Share
   read only = no
   browseable = yes
   valid users = tkye
   force user = tkye
   force group = nas_shares
   create mask = 0664
   directory mask = 0775

[apps]
   path = /mnt/apps
   comment = App Config Share
   read only = no
   browseable = yes
   valid users = tkye
   force user = tkye
   force group = nas_shares
   create mask = 0664
   directory mask = 0775
EOF

# Enable and start samba
systemctl enable smbd
systemctl start smbd

echo "Samba is configured and running."
```