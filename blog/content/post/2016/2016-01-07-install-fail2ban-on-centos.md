---
title: "Install Fail2Ban on CentOS"
url: "/install-fail2ban-on-centos"
date: "2016-01-07"
lastmod: "2016-05-14"
tags: ["centOS", "linux-admin-for-beginners", "fail2ban"]
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

If you just need the commands, here they are. Read on for an explanation of what is happening.

    yum install epel-release #if you haven't already
    yum install fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    nano /etc/fail2ban/jail.local #more on this below
    systemctl restart fail2ban.service
    systemctl enable fail2ban
    

Most of this information came from [this guide on servermom](http://www.servermom.org/install-fail2ban-centos/1809/), except the last line that ensures the service starts at boot. Weird.

The important bits are

    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local`
    

This copies the default config into a use file that can be edited without getting erased during updates. Standard fare.

    systemctl restart fail2ban.service
    systemctl enable fail2ban
    

These start the service and configure on-boot startup, respectively.

## The config file

    nano /etc/fail2ban/jail.local
    

The config file has some very reasonable defaults, but they are all commented out at the beginning. It confused me at first that the section at the top--"How to activate jails"-- didn't work if you just uncommented the bits. It doesn't have everythying it needs.

This file works like an `ini` file. It has sections denoted by square brackets, like `[DEFAULT]` that correspond to a **jail**. A jail is basically a configuration for how to handle bans. Don't worry too much about this, you only need the `[DEFAULT]` one.

Scroll down until you see this section

    # The DEFAULT allows a global definition of the options. They can be overridden
    # in each jail afterwards.
    
    [DEFAULT]
    
    #
    # MISCELLANEOUS OPTIONS
    #
    

Yours probably has `[DEFAULT]` commented out (A line starting with `#` is a comment). Uncomment this line (by removing the `#`). Then, find the lines starting with `bantime`, `findtime` and `maxretry` below it. Make sure they are uncommented as well.

Then scroll *way down* until you find this section.

    #
    # JAILS
    #
    
    #
    # SSH servers
    #
    
    [sshd]
    
    port    = ssh
    logpath = %(sshd_log)s
    enable = true
    

This is the ssh jail, which is our primary concern. Make sure yours is uncommented like the one above. If you have the default ssh port then `port = ssh` will work, otherwise you need to replace the `=ssh` with your ssh port number.

Once you have your configuration file the way you want it, restart fail2ban with

    systemctl restart fail2ban.service
    
