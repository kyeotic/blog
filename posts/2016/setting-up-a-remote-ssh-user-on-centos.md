---
title: "Setting up a remote SSH user on CentOS"
pathname: "/setting-up-a-remote-ssh-user-on-centos"
publish_date: 2016-01-07
tags: ["centOS", "digital-ocean", "nginx-for-beginners"]
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

I am assuming that your droplet/server is already created. The best practice here is to create an SSH key and have digital ocean install it during creation. This will ensure you can connect to your server as root immediately, without a root password existing. It is much safer than having a temporary root password. If you didn't do this, [follow this guide](https://www.digitalocean.com/community/tutorials/how-to-connect-to-your-droplet-with-ssh) to get connected to your server. Otherwise, connect as root with your ssh key.

## Creating a new User

If you just need the commands, here they are. Read on for an explanation of what is happening.

    adduser __username__
    passwd __username__
    gpasswd -a __username__ wheel
    su - __username__
    mkdir .ssh
    chmod 700 .ssh
    nano .ssh/authorized_keys #put your ssh key in here, 1 per line
    chmod 600 .ssh/authorized_keys
    exit
    nano /etc/ssh/sshd_config # uncommend and edit -> PermitRootLogin no
    systemctl reload sshd
    

I am not going to bother repeating the excellent explanation of these commands from [their source guide](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-centos-7). If you are interested, check it out.
