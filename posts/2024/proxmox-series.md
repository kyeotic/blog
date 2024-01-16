---
title: "Proxmox Homelab Series"
pathname: "/proxmox-series"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
---

# Proxmox Homelab Series

I recently moved from TrueNAS to proxmox and after a lot of tough lessons I have a working homelab server again. Since I have everything working now I feel confident saying the move was worth it, but it was a painful journey that included the total corruption of my ZFS pool. I hope I can save you the same pain with this series of guides.

While experience with Linux (especially file permissions), ZFS, networking, and virtualization will be valuable I aim to provide instructions that anyone comfortable using a computer could follow. I will also do my best to explain what we are doing, though I cannot promise to always get the explanation right. I learned a lot of this myself as I was going, so some of it is sure to be cargo-cult-ed.

## Series Overview

* Proxmox Installation and Initial Setup
* [Comparison of TrueNAS and Proxmox](/proxmox-vs-truenas) (why I think the move was worth it)
* Creating a ZFS Pool with Proxmox (with a bonus story about how I corrupted my pool and how you can avoid it)
* Using Mountpoints to Share the ZFS pool with Unprivileged LXC containers (without user mapping!)
* Configuring Samba/SMB Shares with Cockpit
* Setting up the *arr stack
* Configuring GPU passthrough for hardware transcoding on Unprivileged LXC containers (without user mapping!)