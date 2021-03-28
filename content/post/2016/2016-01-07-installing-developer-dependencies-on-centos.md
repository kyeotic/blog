---
title: "Installing developer dependencies on CentOS"
url: "/installing-developer-dependencies-on-centos"
date: "2016-01-07"
lastmod: "2016-01-07"
tags: ["centOS", "linux-admin-for-beginners", "yum"]
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

If you are going to be installing NodeJS and working with git on CentOS, there are a lot of things you are going to need installed. Like a c++ compiler. And Git.

You could go through all of these one by one, but there is an easier way. You will get nearly everything you need with

    sudo yum group install "Development Tools"
    

In additiona, a lot of package that you might need later, like Fail2Ban, exist in an "extended" repository for yum. You can install that repository with

    yum install epel-release
    
