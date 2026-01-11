---
title: "Proxmox Storing from Backup"
pathname: "/proxmox-backup-restore"
publish_date: 2026-01-09
tags:
- homelab
- proxmox
- backup
---

This guide is a part of a series on Proxmox for Homelabs. You can find the [Series Overview here](/proxmox-series).

In this guide I'll cover my backup strategy for Proxmox containers and data, as well as how to run a restore.

# Backup Overview

A good goal for a backup system is to implement the [3-2-1 Backup Strategy](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/)

> The 3-2-1 backup rule is a simple, effective data backup strategy for keeping your data safe. It advises that you keep three copies of your data on two different media with one copy off-site

I'm not quite going to get there for everything because I'm trying to control spending on my homelab, but I will highlight the areas I am falling short and how you might get there yourself. There is some argument about whether one of the "copies" of the data is the production instance, but in this case I am going to count it. If you perform a backup of a container you have two copies: the container itself, and the backup image; an off-site backup of the backup image makes 3.

I'm interested in backing up 3 kinds of data, and they will each be handled slightly differently.

1. The containers (LXC and Docker). Their configuration and data. I want to be able to restore them onto a fresh Proxmox install without skipping a beat.
2. My NAS data. This is everything in my ZFS pool that is **my data**: notes, photos, personal backup (e.g. game saves), 3d Prints.
3. Media. This is everything in my ZFS pool that is **not my data**. 🏴‍☠️

## Pre-requisites

1. Proxmox, obviously
2. [Resticprofile](https://creativeprojects.github.io/resticprofile/installation/linux/index.html) installed
3. A remote repository for restic (I am using [BorgBase](https://www.borgbase.com/), but there are many options)

## Container Backup Strategy

If you followed along in the (ZFS mounts)[/proxmox-zfs-mounts] and (Servarr stack)[/proxmox-servarr-stack] guide you should have a ZFS dataset for `app_configs`. This lives on the ZFS Pool and is used directly by the respective Docker container. I extend this pattern to all Docker containers that I need persistent configuration for, not just the Servarr stack. This includes syncthing, scrypted, and the dedicated game servers that I run.

For the LXC containers I'm using a weekly backup schedule to a new ZFS dataset `/tank/container-backups`. This will be backed up by restic to Borgbase, fulfilling the 3-2-1 requirements.


### Creating the Proxmox Backup Schedule

1. In the Proxmox Web UI go to **Datacenter -> Backup**
2. Click **Add**
3. Create a schedule that includes the containers you want to backup (which may not be all of them)
4. (Optional) Setup retention. I am using 1, because restic will keep the last 3 and I don't want to multiply these snapshots.
5. Run the Backup Schedule with **Run now** to get an initial snapshot to work with

## Configuring Resticprofile

Resticprofile uses yaml for configuration.

This is my `profiles.yaml`

```yaml
version: "1"

default:
  # this is hard-coded in conf, but its secret so I've taken it out
  repository: "rest:https://SECRET_REPO_ID.repo.borgbase.com" 
  password-file: "~/restic-password"

  backup:
    verbose: true
    source:
      - "/tank/container-backups/dump"
      - "/tank/nas"
      - "/tank/apps"
      - "/tank/media_root/media/music"
    schedule: "Mon, 04:00"
  retention:
    group-by: ""
    before-backup: false
    after-backup: true
    keep-last: 3
    prune: true
    tag: true
    host: true
```

I create this and the `restic-password` file containing my borgbase repo password in the proxmox root user's home directory.

Once it exists running `resticprofile backup` once will create the initial backup and start the schedule to run it periodically.

### Backup up Media

You'll notice that I am not backing up everything in `/tank/media_root`, just the music. Here is where my cost control is factoring in: I want to stay in borgbase's cheap tier. I can do this by keeping everything under 20GB, and right now that covers everything above. I have Terabytes of other media that I am OK with losing, because it can be re-downloaded. So I don't back it up. If you want to do that, update the `source` to include all of your media. 


# Restoring

If you suffer a system drive failure you can recover your Proxmox containers like this

1. Install proxmox, including resticprofile (this is manual)
2. Import the ZFS pool: `zpool import tank`
3. Add the ZFS pool as Proxmox storage: `pvesm add dir tank-backup --path /tank/proxmox-backup --content backup,vztmpl,iso`
4. Restore the files from the latest snapshot
```
resticprofile restore latest:/tank/container-backups/dump --target="/tank/container-backups/dump"
```
5. Restore the snapshots by going to `tank-backups` in the Proxmox **Server View**, selecting the image, and clicking **Restore**

If you need the [ZFS Mounts](/proxmox-zfs-mounts) and [GPU passthrough](/proxmox-gpu-passthrough) for your containers, go through those steps again. I have these done through ansible, so they are part of my proxmox install, but they are relatively quick as manual steps.