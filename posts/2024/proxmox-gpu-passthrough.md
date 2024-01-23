---
title: "Proxmox GPU Passthrough on Unprivileged LXC Containers"
pathname: "/proxmox-gpu-passthrough"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
- smb
- cockpit
---

This is a part of a guide on Proxmox. You can find the [Series Overview here](/proxmox-series).

In the previous guide we covered how to [setup the Servarr Stack with docker compose](/proxmox-servarr-stack). It will use similar user/group mapping techniques as those covered in [bind mount your ZFS Datasets with LXC Containers](/proxmox-zfs-mounts), so completing that will be helpful.

This guide will cover how to configure GPU Passthrough for an Unprivileged LXC Container, as well as how to configure [Jellyfin](https://jellyfin.org/) to use it for Hardware Acceleration.

> This guide was inspired by this one [this guide](https://dustri.org/b/video-acceleration-in-jellyfin-inside-a-proxmox-container.html), which did not work for me as-is but was incredibly helpful in finding my solution.

**IMPORTANT NOTE**: Hardware Acceleration depends heavily on the kind of hardware you have. I am working with a AMD RyzenTM 5 7600, so these instructions are specific to AMD integrated graphics. For Intel you will need to do some tweaks, many of which are covered in the [Official Jellyfin Docs for Intel GPUs](https://jellyfin.org/docs/general/administration/hardware-acceleration/intel).

## GPU Passthrough

Ultimately we want to add something like this to our container configuration `/etc/pve/lxc/$$CT_ID.conf`

```
# Needed for GPU/transcoding, check the allow c values with stat /dev/DEVICE
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.cgroup2.devices.allow: c 235:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
lxc.mount.entry: /dev/dri/renderD128 dev/renderD128 none bind,optional,create=file
lxc.mount.entry: /dev/kfd dev/kfd none bind,optional,create=file
```

To get the right numbers for `lxc.cgroup2.devices.allow` lines we need to check the devices we are sharing. To do that we run `stat /dev/$$DEVICE` and look at the output. It will look something like this

```
root@homelab:~# stat /dev/dri/card0 
  File: /dev/dri/card0
  Size: 0               Blocks: 0          IO Block: 4096   character special file
Device: 0,5     Inode: 1048        Links: 1     Device type: 226,0
Access: (0666/crw-rw-rw-)  Uid: (    0/    root)   Gid: (   44/   video)
Access: 2024-01-19 08:10:39.936000372 -0800
Modify: 2024-01-19 08:10:39.936000372 -0800
Change: 2024-01-19 08:10:39.936000372 -0800
 Birth: 2024-01-19 08:10:39.928000372 -0800
```

In this example you can see that `/dev/dri/card0` has a `Device type: 226,0`. Hence the configuration example using `lxc.cgroup2.devices.allow: c 226:0 rwm`. These are the devices we care about

To get all the values we need, run these commands and note their `Device Type`

```
stat /dev/dri/card0
stat /dev/dri/renderD128
stat /dev/kfd
```

Adjust the device allow configuration to match the numbers you record. Here is the example again, which needs to go in the configuration for your LXC Container

```
# Needed for GPU/transcoding, check the allow c values with stat /dev/DEVICE
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.cgroup2.devices.allow: c 235:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
lxc.mount.entry: /dev/dri/renderD128 dev/renderD128 none bind,optional,create=file
lxc.mount.entry: /dev/kfd dev/kfd none bind,optional,create=file
```

> Note: The mount bindings are not all the same! One is `create=dir` and the others are `create=file`. Do not just copy/paste one line several times and edit the device, it wont work unless the create type matches!

Finally, we need to make these devices accessible. One way is to map users/groups with [these steps](https://pve.proxmox.com/wiki/Unprivileged_LXC_containers#Using_local_directory_bind_mount_points), but I find that configuration brittle and painful to work with. I prefer allowing full access to the containers. As [this guide](https://dustri.org/b/video-acceleration-in-jellyfin-inside-a-proxmox-container.html) notes

> It doesn't really worsen security, since: - the devices are only mounted inside my jellyfin container, which would have the same privileges as if I used gid mapping. - odds are that an attacker able to get a shell on the hypervisor wouldn't really need to have r/w access to the two devices to escalate their privileges anyway, since they would either be: - root already to escape from a container - root already to escape from a vm - whatever proxmox user and likely able to escalate to root trivially - other users are sandboxed via systemd and/or seccomp.

Anyway, run these commands to configure access:

> Note: Unlike other shell commands in this guide, these use a `$` to show where the command lines start and end

```
$ cat > /etc/udev/rules.d/99-gpu-chmod666.rules << 'EOF'
KERNEL=="renderD128", MODE="0666"
KERNEL=="kfd", MODE="0666"
KERNEL=="kfd", GROUP="render", MODE="0666" 
KERNEL=="card0", MODE="0666"
EOF
$ udevadm control --reload-rules && udevadm trigger
```

## Configuring Jellyfin

Restart LXC, then follow [this guide](https://jellyfin.org/docs/general/administration/hardware-acceleration/amd#configure-with-linux-virtualization).

In the LXC Shell:

```
getent group render | cut -d: -f3 # 106 for me
getent group video | cut -d: -f3 # 44 for me
```

Take the output and update your Jellyfin to use these values

```yaml
version: '3'
services:
  jellyfin:
    image: jellyfin/jellyfin
    user: 1000:1000
    group_add:
      - "122" # Change this to match your "render" host group id and remove this comment
      - "123" # Change this to match your "video" host group id and remove this comment
    network_mode: 'host'
    volumes:
      - /path/to/config:/config
      - /path/to/cache:/cache
      - /path/to/media:/media
    devices:
      - /dev/dri/renderD128:/dev/dri/renderD128
      - /dev/kfd:/dev/kfd # Remove this device if you don't use the OpenCL tone-mapping
    environment:
      - ROC_ENABLE_PRE_VEGA=1
```