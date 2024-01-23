---
title: "Proxmox ZFS Mount Points"
pathname: "/proxmox-zfs-mounts"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
- zfs
---

This is a part of a guide on Proxmox. You can find the [Series Overview here](/proxmox-series).

In the previous guide we covered [Creating A Pool](/proxmox-zfs). This guide will cover setting up permissions so that LXC Containers can bind mount datasets in the pool for shared use. Since my use case is for a Homelab running the [Servarr Stack](https://wiki.servarr.com/) it will be from a NAS/Media perspective, but the steps are generalizable.

> This guide takes heavy inspiration from this forum post: [Tutorial: Unprivileged LXCs - Mount CIFS shares](https://forum.proxmox.com/threads/tutorial-unprivileged-lxcs-mount-cifs-shares.101795/). We are not using CIFS/NFS though, so our setup will be simpler.

## Features

Once we are done we will have

* A Dataset for App Configuration that is full-control for LXC Containers
* A Dataset for Media that is full-control for LXC Containers
* None of that messy [user/group mapping](https://pve.proxmox.com/wiki/Unprivileged_LXC_containers#Using_local_directory_bind_mount_points)
* A SMB Share for Media

### Why no user/group mapping?

Because it's painful to configure. I can't really overstate this. There is no GUI for doing this, the error messages you get when you do it wrong are not helpful, and changing one line of a valid config is rarely going to work since the entire map must form a contiguous range meaning changing one line will always require changing at least one other line.

I frankly can't understand how this API got out into the wild. It's so painful to use. It's not even that easy to understand. It's ugly. What exactly are the benefits? Anwyay, moving on.

## How it works

Proxmox maps the users and groups on the host (ie Proxmox itself) to users and groups on the LXC by adding 100_000. So The root user on an LXC is user 100000 on the host.

So we will create a group on the host with a gid of `110000` (maps to LXC `10000`) that will own the datasets we want to share.

## Setting up the Datasets

First we need Datasets to work with (A dataset is a special kind of directory in ZFS). Open a shell for the node and run

```
zfs create tank/apps
zfs create tank/media_root
```

> Why `media_root`? See [this guide](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/#folder-structure) on recommended folder structure for Servarr Stack. `media_root` will serve as "data" (which is just too generic to name a Dataset)


## Permissions on the Host

Now we need a group and a user that will map cleanly into LXC Container space. Open a shell for the host and run:

```
# Create the group that maps to nas_shares on the lxc
groupadd -g 110000 nas_shares

# Create the mapped user
useradd nas -u 101000 -g 110000 -m -s /bin/bash

# Move ownership to the mapped user
chown -R nas:nas_shares /tank/apps/
chown -R nas:nas_shares /tank/media_root/
```

## Permissions on the LXC

You will need to repeat these steps for each LXC you want to share with.

My setup has an LXC for Portainer (which runs all the Servarr apps) and one for Cockpit (which handles SMB sharing, more on [here](/proxmox-cockpit)). If you have a seperate LXC for each Servarr app, you will need to run this in each one.

Start the LXC and open a shell.

```
groupadd -g 10000 nas_shares

# name it whatever you want
# it doeesn't have to match the host or even other LXCs
useradd docker -u 1000 -g 10000 -m -s /bin/bash 
```

Then shut down the LXC.

## Bind Mounting the Datasets

The only thing left to do is add [bind mount points](https://pve.proxmox.com/wiki/Unprivileged_LXC_containers#Using_local_directory_bind_mount_points). This needs to be done for each LXC that needs a bind mount. The commands below assume the ID of the container is `105`, you will likely need to change it to match your container ID.

```
pct set 105 -mp0 /tank/media_root,mp=/mnt/media_root
pct set 105 -mp1 /tank/apps,mp=/mnt/app_config
```

> If you have other hardware mounted at mp0 or mp1 you will need to increment those values to ones that are not used.

Once this is done you can restart the LXC. The directories should now be visible and writable from inside the container. See the [next guide for setting up SMB Sharing](/proxmox-cockpit).