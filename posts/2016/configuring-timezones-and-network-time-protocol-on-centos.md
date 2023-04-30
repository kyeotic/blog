---
title: "Configuring TimeZones and Network Time Protocol on CentOS"
pathname: "/configuring-timezones-and-network-time-protocol-on-centos"
publish_date: 2016-01-07
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

If you just need the commands, here they are. Read on for an explanation of what is happening.

    sudo timedatectl list-timezones #copy your zone
    sudo timedatectl set-timezone region/timezone
    sudo yum install ntp
    sudo systemctl start ntpd
    sudo systemctl enable ntpd
    

I am not going to bother repeating the excellent explanation of these commands from their [source guide](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers). If you are interested, check it out.
