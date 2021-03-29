---
title: "Setting up a CentOS Digital Ocean droplet with Nginx for beginners"
url: "/digital-ocean-for-beginners"
date: "2016-01-07"
lastmod: "2016-01-28"
tags: ["digital-ocean", "centOS", "nginx", "ssh"]
---

If you want to get to the meat of the post, jump down to [the guide](#theguide).

### Intro

I recently made the move from [WebFaction](https://www.webfaction.com/), which offers a shared/managed host with SSH access, to [Digital Ocean](https://www.digitalocean.com/), which offers virtual private servers with SSH access. They are both billed as being "for developers", but WebFaction does more work for you. The tradeoff is you don't get root/sudo access.

This wasn't a problem for me until I wanted to automate SSL key installation with [Let's Encrypt](https://letsencrypt.org/). Even without sudo access you can obtain keys, but WebFaction required that I open a support ticket to get the certs installed. Since Let's Encrypt's certs only last 90 days, this was going to be an issue. Hence to the move.

Moving from a managed host to one that I had to fully manage meant learning a lot of sys admin stuff in a short period of time. To catalog this process for other developers who know how to build applications but not run servers, I am putting together a series on 1st time setup. Since I came from WebFaction I chose to stick with CentOS, which has made things slightly harder on me since most guides seem to be written for Ubuntu/Debian. Hopefully this helps you out.

# The Guide

I'll assume you have already created your droplet, since it's pretty simple. I was able to find most of this information from Digital Ocean Community posts, but I wanted to centralize it. Searching for this is hard, and you can find a lot of bad information before you find the good stuff. I will cite the original guides where appropriate, since they contain great additional information.

I am breaking this guide into 2 parts, because it's going to be very large. OS Configuration, and Hosting Configuration. Each section will get its own post, but they will all be linked to from here so that there is a canonical source.

## OS Configuration

1. [Setting up a remote user](/setting-up-a-remote-ssh-user-on-centos)
2. [Configuring the firewall](/configuring-the-firewall-on-centos)
3. [Configuring TimeZones and Network Time Protocol (NTP)](/configuring-timezones-and-network-time-protocol-on-centos)
4. [Setup swap file](/setup-swap-file-on-centos)
5. [Installing Fail2Ban](/install-fail2ban-on-centos)

## Hosting Configuration

1. [Installing Yum tools](/installing-developer-dependencies-on-centos)
2. [Installing Node](/installing-nodejs-on-centos)
3. [Configuring Nginx as a Reverse Proxy](/configuring-nginx-as-a-reverse-proxy)
4. [Digital Ocean DNS Management](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean)
5. [Deploying Applications with Git and SSH](/deploying-applications-with-git-and-ssh)
6. [Application Management and Crontab](/application-management-and-crontab)
7. SSL Certs and Keys with Let's Encrypt (You can find Ubuntu instructions [here](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04), for now. CentOS "webroot" style guide coming soon)
8. [Setting up email with Mailgun and Gmail](/using-mailgun-to-route-gmail-for-free)
