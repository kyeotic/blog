---
title: "Setup swap file on CentOS"
pathname: "/setup-swap-file-on-centos"
publish_date: 2016-01-07
tags: ["centOS", "linux-admin-for-beginners"]
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

If you just need the commands, here they are. Read on for an explanation of what is happening.

    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
    

I am not going to bother repeating the excellent explanation of these commands from their [source guide](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers#create-a-swap-file). If you are interested, check it out.
