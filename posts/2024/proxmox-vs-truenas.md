---
title: "Comparing Proxmox and TrueNAS"
pathname: "/proxmox-vs-truenas"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
- TrueNAS
---

# Intro

This post is part of my series on setting up a [Proxmox Homelab](/proxmox-series). Unlike the other posts in this series that are _how-to_ guides, this post is my personal opinion on using [Proxmox](https://www.proxmox.com) and [TrueNAS Scale](https://www.truenas.com/truenas-scale/) as home server OSs, and why I am happy with my move to Proxmox. If you aren't interested and want to get back to the guide head to the [Series Overview](/proxmox-series#series-overview).

## Why use either of them?

Proxmox and TrueNAS Scale (TrueNAS from here on) are free, open-source hypervisors. They can both run [Virtual Machines](https://azure.microsoft.com/en-us/resources/cloud-computing-dictionary/what-is-a-virtual-machine) as well as containers (though they run different kinds of containers natively). This makes them both popular choices as home server OSs.

Proxmox is more general in its approach. It has a web UI that makes it easy to spin up VMs and [LXC containers](https://linuxcontainers.org/lxc/), manage storage/disks, and not much else.

TrueNAS is more geared towards being a NAS. It has a web UI that makes it easy to create and manage a ZFS pool, its datasets, and share those datasets as SMB or NFS shares. It has a web UI for managing VMs, and a separate one for managing [Docker containers](https://www.docker.com/resources/what-container/). It uses k3os to run docker containers and helm charts.

## My Journey

I started with TrueNAS Scale at the beginning of 2023 on my first homelab server. It was easy enough to get installed and get the basic setup done. I created a pool of 3 disks, made users for SMB sharing, setup Certbot for an SSL cert for the web UI, installed a game for playing with friends, installed [Home Assistant](https://www.home-assistant.io/) on a VM, PiHole from the official charts, and installed some personal apps as docker containers.

Then I sunk weeks into figuring out how to make networking function in any kind of reasonable way. TrueNAS has a UI for networking, but its finnicky and I'm not a fan. If you want to assign a VM an IP address its easy. The only way to assign IP addresses to docker apps, though, is to break out the MetalLB for K8s and that's like 3 kinds of *not supported*.

You have to use a reverse proxy, but there is no way to centrally manage it. You have to do port mapping on each app, but there is no consistency to this. "Custom Docker App" has one way, official chart apps have another, and TrueCharts has a 3 (I think, maybe 4?): Traefik via chart config, port mapping, or their *external service* app. Thats 5 (or 6?) different ways networking needs to be configured, and the documentation on it is all over the place (if it even exists).

TrueNAS sells itself as an *appliance*, which is how they justify tightly locking down everything. The tradeoff here should be that there is only one way to do something, but its at least straightforward if not outright easy. TrueNAS's networking is locked and *and terrible*. 

## The Proxmox Way

Proxmox lets you assign IP addresses to VMs. It also lets you assign them to LXC containers. You can install Nginx Proxy Manager and do reverse proxy configuration *with SSL certs from Lets Encrypt*, and you can do it *all from one slick UI*. If you use this [wonderful helper scripts](https://tteck.github.io/Proxmox/) kit there is a one-line copy/pasta for installing it. Once you do that and configure your DNS Plugin *your networking is done*.

I cannot overstate how simple it is in comparison to TrueNAS. I got it done on the first day, not long after getting Proxmox installed. This was in between reading various posts for ideas, and finding the helper scripts kit above. It *just works*.

Now you might be thinking: come on now, LXC containers are just easier than docker and K8s. If you had to do this for docker you would be in the same place as TrueNAS is. You would be wrong though, because installing a docker container in its own LXC is easy. It even has another one-line script in the [helper scripts repo](https://tteck.github.io/Proxmox/). That same script even gives you the option to layer [Portainer](https://www.portainer.io/) on top so you have a UI for manager multiple docker containers. All of this still plays nicely with the same Nginx Proxy Manager thats fronting your LXC container apps and VMs.

Its all the same. You don't have to learn 5 different ways of doing things, fight with any of the pandoras box that is the K8s API or CLI. It's so easy I'm more than a little disappointed in myself for putting it off for so long while I "tried to learn the TrueNAS way".

## Other Thoughts

It might seem silly to pick Proxmox over TrueNAS just because *networking* is easier in Proxmox. Networking is only one part of what you have to do with a home server. However, it is a big one and getting it right is important.

It more than that, though. Proxmox has the advantage of age, and its settled on a simple way to do most things (except user mapping, that's a nightmare that I have worked to avoid). TrueNAS is so focused on *being an appliance* that it seems like its constantly trying to *get in your way*.

The documentation is just... bad. In my experience the community forums are not a good place to get help, which would be the only way to save any grace from bad documentation. Proxmox's documentation is OK, but their community forums and sub-reddit are quite responsive and friendly. I've had good luck in both.

Ignoring VMs, since that's "do everything yourself from scratch" on both platforms, TrueNAS is an inferior hypervisor for running personal apps and community apps alike. Helm Charts are the most heavyweight application configuration framework I know of, and that's the most favored method on TrueNAS. You can run docker apps, but there is no Docker Compose or K8s integration that would simplify things. You also have to do click-ops through there sidebar-only UI to create a docker Apps. TrueCharts is mentioned frequently in the TrueNAS forums, yet occupies a superposition of "the only way to get some stuff done" and "not affiliated with TrueNAS in any way, if you use them you're on your own". It's maddening, and TrueChart's attitude towards breaking changes is frankly the most hostile I have *ever seen*.

Proxmox has a one-liner to deploy docker or portainer. Not in a resource-heavy VM either, in a lightweight LXC that can easily share resources with the host or other LXCs as compute demands it. You get Docker Compose, which is my preferred way to work anything more complicated than a single image (K8s is a nightmare and every time I have to touch it I hate it more).

It all adds up. Proxmox has been wonderful to work with. Except for that time I corrupted my entire ZFS pool, but that was entirely my own fault and a story for another time.