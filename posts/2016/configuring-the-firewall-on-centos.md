---
title: "Configuring the firewall on CentOS"
pathname: "/configuring-the-firewall-on-centos"
publish_date: 2016-01-07
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

If you just need the commands, here they are. Read on for an explanation of what is happening.

    sudo systemctl start firewalld
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --permanent --add-port=4444/tcp #if you changed default ssh port
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --permanent --add-service=smtp
    sudo firewall-cmd --reload
    sudo systemctl enable firewalld
    

I am not going to bother repeating the excellent explanation of these commands from their [source guide](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers). If you are interested, check it out.
