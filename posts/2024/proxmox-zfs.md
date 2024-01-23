---
title: "Setup ZFS on Proxmox"
pathname: "/proxmox-zfs"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
- zfs
---

This is a part of a guide on Proxmox. You can find the [Series Overview here](/proxmox-series).

This guide will cover creating a ZFS Pool on Proxmox, intended to be used by LXC Containers via Mount Points (which is covered by [this guide](/proxmox-zfs-mountpoints)).

## The elephant in the room

> Want to get straight to setup? Skip ahead to [Creating a Pool](#creating-a-pool).

If you have used ZFS its likely on FreeNAS or TrueNAS. You may have even seen TrueNAS virtualized on Proxmox in order to manage ZFS. While that remains a popular option, Proxmox now natively supports ZFS. Letting Proxmox own the pool has two major advantages over running TrueNAS in a VM.

1. You can use normal bind mounts points, instead of CIFS/NFS, for LXC Containers. This provides better performance, and avoids issues like [SQLite corruption](https://stackoverflow.com/questions/9907429/locking-sqlite-file-on-nfs-filesystem-possible).
2. You avoid reserving the Disk and RAM necessary to run the TrueNAS VM (min 8GB RAM).

Number 1 is absolutely critical for all sorts of workloads your LXC containers might be running, but I think 2 is still important to consider. TrueNAS is [famously resource hungry](https://www.truenas.com/community/threads/home-setup-memory-requirements.74443/), and your paying an additional cost for Proxmox (or multiple containers), to run NFS as a secondary filesystem just to access the ZFS Pool you are also managing.

I have other thoughts on why you should just use [Proxmox over TrueNAS](/proxmox-vs-truenas), for the curious.

## Creating a Pool

You can do all of this from [the CLI](https://pve.proxmox.com/wiki/ZFS_on_Linux), but there is a GUI and I think its easier to use. To find it:

1. Select the Node from the Server View
2. Select **Disks > ZFS**
3. Click **Create: ZFS** in the top left

This will open the ZFS Pool creator. Here is a screenshot (using virtualized storage, because its a demo)

![Create ZFS Pool](/2024/proxmox/zfs-gui.png)

Some things to note:

* The name is `tank`. This is a very common name for a singular pool; yes, its a water pun.
* The **RAID LEVEL** is RaidZ (aka RaidZ1). You may want to change this. RaidZ1 gives a single disk of fault tolerance; select RaidZ2 for two disks of faul tolerance. See [this primer](https://www.truenas.com/docs/references/zfsprimer/#zfs-redundancy-and-raid) for more information.
* The **compression** is lz4. I am not an expert here, this is the [recommendation from TrueNAS](https://www.truenas.com/docs/_includes/storagecompressionlevelsscale/).

After you press **Create** it will initialize the pool.

That's pretty much it. For more on how to share with LXC Containers, including file permissions, see the next guide on [ZFS Mount Points](/proxmox-zfs-mounts).

## A story about how I corrupted my pool by being an idiot

The `-f` (for "force") flag on `zfs import` should not be used lightly. It's there to protect you from two hosts managing the same pool simultaneously, which will lead to total pool corruption in short order.

My first pass at a homelab was built on TrueNAS, and while I had [some issues](/proxmox-vs-truenas) with it, I thought the ZFS and SMB UI's were solid. So I decided to put TrueNAS Scale in a VM on proxmox and import the pool I had created from the bare metal TrueNAS install on a previous server.

However, I ran into a lot of issues. I sorted out most of them with [some help](https://forum.proxmox.com/threads/tutorial-unprivileged-lxcs-mount-cifs-shares.101795/), but when I get some apps running that used SQLite I started seeing db corruptions and discovered you can't do this kind of stuff on NFS.

How else was I going to manage this ZFS Pool in TrueNAS and run apps on proxmox? Well, I thought, I'll just import the pool on Proxmox and share it with bind mounts. Of course, I couldn't just import it because TrueNAS was still managing it. So I exported it from TrueNAS first, and then tried to import to Proxmox. This worked once, but as I was tinkering I noticed an issue, so I imported it back into TrueNAS, fixed the issue, and re-exported.

This time though, Proxmox still wouldn't let me import it. I even turned off the TrueNAS VM, and then rebooted Proxmox. Still blocked. So I used the `-f` flag, and everything worked.

For a day at least. At some point the TrueNAS VM got turned back on, and then things started to lock up. Went I went poking around I discovered that both TrueNAS and Proxmox had the pool mounted. I exported it from both, but was then no longer able to import it into either. I tried everything I could think of, think I asked [Reddit for help](https://www.reddit.com/r/zfs/comments/194bg3z/cannot_import_one_or_more_devices_is_currently/).

It was too late though. Two active hosts had been trying to administer the pool, and it was irrevocably corrupt. I had to trash it and start over.

Be careul with `zfs import -f` kids. Its named "force" for a reason.