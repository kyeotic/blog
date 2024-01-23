---
title: "Proxmox Installation"
pathname: "/proxmox-install"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
---

This is a part of a guide on Proxmox. You can find the [Series Overview here](/proxmox-series).

This guide will cover the basic installation of Proxmox (8.1). It will be short, since it's fairly straightforward.

## Installing from USB

1. Download the [ISO](https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso)
2. Install it on a USB Drive with a tool like [Ventoy](https://www.ventoy.net/en/index.html) or [Etcher](https://etcher.balena.io/)
3. Boot from the USB on your server

This should get you to the Proxmox Installer. To continue:

1. Install Proxmox VE (Graphical)
2. Accept EULA
3. Select Target Disk (This will erase the disk)
4. Select TimeZone
5. Set Password and Email


This brings us to the Network Configuration. If you don't know what you are doing here, these options are fine, but you probably want to go find a larger guide on home networking.

**Hostname**: `homelab.homelab.local` (See [this thread](https://forum.proxmox.com/threads/hostname-fqdn-huh.63667/) for some info)
**IP Address**: `192.168.0.10` (This needs to be unused and part of your subnet, which might be `192.168.1.x` or any other private subnet)
**Gateway**: `192.168.0.1` (This needs to be your router)
**DNS Server**: `1.1.1.1` (Any valid DNS Server is fine)

The continue, and **Install** (You can remove the USB drive after it reboots)

## Additional Setup

After rebooting the console will show you the IP and Port the Web UI is available at. It will look something like

```
https://192.168.0.10:8006
```

Navigate to this URL and enter `username: root` along with the password you created.

**Welcome to Proxmox**

Some basic first-time configuration has been wrapped up in a handy helper script (from [this site](https://tteck.github.io/Proxmox/))

Open a shell by selecting the node in the treeview (Datacenter -> Homelab, if you used the name above). THen select **Shell** from the list that shows up, and run (follow all prompts)

```
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
```

Then reboot. You're all set!