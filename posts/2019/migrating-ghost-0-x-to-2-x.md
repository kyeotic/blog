---
title: "Migrating Ghost 0.x to 2.x (and a new domain!)"
pathname: "/migrating-ghost-0-x-to-2-x"
publish_date: 2019-05-15
tags: ["ghost", "dns"]
---

To accompany my recent [handle change](/kyeotic/) I took the time to upgrade this blog. 

Previously it had been running Ghost 0.4 on a [Digital Ocean CentOS 7](/digital-ocean-for-beginners) machine. To get from 0.x to 2.x requires that your exported data travel through 1.x first, which is a bit of a challenge. My first attempt was to upgrade the server in place, but issues with *yum *and *node* got so bad I gave up. Then I found [an easier way](https://robdodson.me/easily-upgrade-ghost-0-x-to-2-0/) that *mostly *worked for upgrading. For completeness I'll include those steps, and also show how to setup SSL/Certs and redirection from an old domain to Ghost primary domain.

> Note: I did not try to keep my theme or the attached Disqus comments.

## Backup

1. Go to the ****Labs**** section of your Ghost admin page (`yourblog.com/ghost`) and click export to get your JSON data. You'll use this to recreate your posts.
2. Download your images. The easiest way to do this is with scp. [Here's a little cheatsheet if you're unfamiliar with it](https://devhints.io/scp).

```shell
cd /var/www/ghost/content

sudo zip -r images.zip images

scp YOUR_USERNAME@YOUR_SERVER_IP:/var/www/ghost/content/images.zip /local/path/to/file
```

backup images
## Install Ghost 1.x Locally

The [guide I found](https://robdodson.me/easily-upgrade-ghost-0-x-to-2-0/) has this step, but the instructions provided didn't work for me. I modified them to use the "local" version of ghost, which still worked to import the 0.x backup and export a 1.x backup.

```shell
npm install -g ghost-cli
mkdir ghost-v1
cd ghost-v1
ghost install local --v1
```

This will start a `localhost` server where you can import the 0.x backup and export a 1.x backup.

## Create Ghost 2.x Server

Since I am working on **Digital Ocean** I used their perfectly simple [Ghost Marketplace Image](https://marketplace.digitalocean.com/apps/ghost) with the smallest ($5/month) droplet size. It took all of 5 minutes to create, after which I re-assigned the *floating IP* from the old 0.x droplet and was able to SSH in.

If you are working on another platform, or don't want to use the provided image (if you are on Digital Ocean you asbolutely should) then consult the official [Ghost Setup Docs](https://docs.ghost.org/setup/) for installation.

## Setup DNS

It's really important you do this step before you proceed with the Ghost setup, because the certificate registration through [Let's Encrypt](https://letsencrypt.org/)/[acme.sh](https://github.com/Neilpang/acme.sh) needs to route to your intended domain on the server to get your SSL cert.

Once your DNS `A` Record points at your server (which will be instant if you just reassigned a *floating IP*)*,* proceed.

**SSH into Ghost Server**

If you are using the **Digital Ocean Marketplace Image **then setup will automatically start, prompt you for some info, register your SSL cert, and complete. Once that is done open `yourblog.com/ghost` and import your 1.x backup. Then upload your images with `scp`

```shell
scp /local/path/to/file YOUR_USERNAME@YOUR_SERVER_IP:/var/www/ghost/content/images.zip

ssh YOUR_USERNAME@YOUR_SERVER_IP
cd /var/www/ghost/content
unzip images.zip
rm images.zip
```

backup images
When I did this the images ended up with the wrong permissions, but navigating back to the Ghost root and running `ghost doctor` twice gave me instructions to fix it. You may only need to run it once, if they improve the help steps in the future.

At this point your server should be ready to go, but if you want to keep your old domain up and have SSL Cert and redirections continue to function, keep reading.

## Adding Additional SSL Certs

To get `acme.sh` to create and renew certs for the old domain navigate back to your Ghost root and run

```shell
# Determine your secondary URL
ghost config url https://my-second-domain.com

# Get Ghost-CLI to generate an SSL setup for you:
ghost setup nginx ssl

# Repeat the above two steps for all domains you want certs for

# Change your config back to your canonical domain
ghost config url https://my-canonical-domain.com
```

Each time you run `ghost setup nginx ssl` a new SSL Cert directory in `/etc/letsencrypt` and pair of *nginx*`.conf` will be created in `$GHOST_ROOT/system/files` to house the *http* and *https* configuration. They include the correct references to the newly minted SSL Certs, but their `Location /` blocks don't redirect. They need to look like this (for *http*)

```
server {
    listen 80;
    listen [::]:80;

    server_name blog.kyeotic.com;
    root /var/www/ghost/system/nginx-root; # Used for acme.sh SSL verification (https://acme.sh)

    location / {
        return 301 https://blog.kye.dev$request_uri;
    }

    location ~ /.well-known {
        allow all;
    }

    client_max_body_size 50m;
}
```

The *ssl* variants have more code for loading the Certs, but its just the `Location /` block you need to change.

## Restart nginx

Once the SSL Certs are created and configured in nginx you can restart the service

```shell
# Get nginx to verify your config
sudo nginx -t

# Reload nginx with your new config
sudo nginx -s reload
```

You should be all set after that. Though you might want to[ harden your server](https://robferguson.org/blog/2017/08/12/migrating-from-ghost-0-x-to-ghost-1-x/#serverhardening), or setup ad-tracking-free comments with [Commento](/self-hosting-commento).
