---
title: "Self-Hosting Commento alongside Ghost 2.x"
pathname: "/self-hosting-commento"
publish_date: 2019-05-15
tags: ["ghost", "disqus", "commento", "digital-ocean"]
---

I recently upgraded this blog to Ghost 2.x and took the opportunity to abandon Disqus. It bloated the post page and came with something like 45 tracking scripts/cookies. To replace it I settled on [Commento](https://commento.io/), a small and privacy-focused open source solution. The minimum subscription is $3/month, which is a bit high for a blog that I only pay [$5/month](/migrating-ghost-0-x-to-2-x) for. Luckily they offer a self-hosted option. Here is how I got it setup.

Since I am [running this blog on Digital Ocean](/migrating-ghost-0-x-to-2-x) I chose to install and run Commento from the same Droplet (Virtual Machine). You don't need to do this, but the smallest Droplet is sufficient to run Ghost and Commento side-by-side if your traffic isn't too high.

## Prerequisites

- **PostgreSQL**: This is a *requirement*. [This is a good guide for installation](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-18-04#step-1-%E2%80%94-installing-postgresql). **Commento** requires its own database. I created a system user named "commento" (`adduser commento`), matched it to a databse role (`createuser --interactive`, name it "commento") and a database of the same name (`createdb commento`). When you are done make sure you `sudo systemctl enable postgresql` to keep it running.
- **smtp**: This is *optional*, but without it you wont be able to send activation or password reset emails. While its focused on gmail forwarding, my [mailgun guide](using-mailgun-to-route-gmail-for-free/) covers setting up smpt credentials which will be usable for Commento. I highly recommend getting this setup.
- **DNS**: Commento needs its own (sub)domain to run on. I used `commento.blog.kye.dev`, and pointed it to the same **floating IP** that Ghost is on.

## Install Commento

```shell
# Switch to the commento user
sudo -u commento

# Download
wget https://commento-release.s3.amazonaws.com/commento-linux-amd64-v1.7.0.tar.gz

# Unpack
mkdir commento-server
tar xvf commento-linux-amd64-v1.7.0.tar.gz -C ./commento-server
```

## Create SSL Cert

This is the same process used to [add certs for alternate/redirect domains](migrating-ghost-0-x-to-2-x/#adding-additional-ssl-certs).

```shell
# Switch user
sudo -u ghost-mgr

# Navigate to ghost install root
cd /var/www/ghost

# Set Commento URL
ghost config url https://commento.YOURBLOG.com

# Get Ghost-CLI to generate an SSL setup for you:
ghost setup nginx ssl

# Switch back to your Blog
ghost config url https://YOURBLOG.com
```

This will create certs with Lets Encrypt/acme.sh, as well as generate some NGINX conf files in `/var/www/ghost/system/files`. The conf files point to Ghost though, and we need to reverse proxy them to the Commento server.

## Update NGINX

We need to edit 3 files: the *ssl* and *http *conf files for Commento; and the *ssl-params* file used by NGINX.

We need to reverse proxy NGINX to the Commento server (that we will setup in the next step). In `/var/www/ghost/system/files` update the `commento*.conf` files. Their `Location /` block should look like this

```
location / {
    proxy_set_header Host $http_host;
    proxy_pass http://localhost:8081;
}
```

Then in `/etc/nginx/snippets/ssl-params.conf` remove/comment out the following line:

```
# Find and comment out this line
add_header X-Content-Type-Options nosniff;
```

> Note: this is necessary because of bad MIME type handling in Commento. Hopefully this will be fixed in the near-future.

## Create the Commento Service

Create the following file at `/etc/systemd/system/commento.service`

```ini
[Unit]
Description=Commento daemon service
After=network.target postgresql.service

[Service]
Type=simpleExecStart=/home/commento/commento-server/commento
Environment=COMMENTO_ORIGIN=https://commento.YOURBLOG.com
Environment=COMMENTO_PORT=8081
Environment=COMMENTO_POSTGRES=postgres://commento:commento@127.0.0.1:5432/commento?sslmode=disable
Environment=COMMENTO_SMTP_HOST=smtp.mailgun.org
Environment=COMMENTO_SMTP_USERNAME=YOUR_SMTP_USERNAME
Environment=COMMENTO_SMTP_PASSWORD=YOUR_SMTP_PASSOWRD
Environment=COMMENTO_SMTP_PORT=465
Environment=COMMENTO_SMTP_FROM_ADDRESS=no-reply@YOURBLOG.com

[Install]
WantedBy=multi-user.target
```

Then run

```shell
sudo chmod u+x /etc/systemd/system/commento.service
sudo systemctl start commento
sudo systemctl enable commento
```

To get NGINX routing to Commento you will need to restart it.

```shell
sudo nginx -s reload
```

## Register Domain in Commento

Commento should be running now. You need to complete the [domain setup](https://commento.gitlab.io/docs/installation/self-hosting/register-your-website/) in the Commento dashboard (the one running on your server, not the cloud one).

## Add Commento code to Ghost Template

Once your domain is registered in the dashboard a snippet is provided under the **installation** section. It looks like this

```html
<div id="commento"></div>
<script src="https://commento.blog.kye.dev/js/commento.js"></script>
```

You will need to add this to `/var/www/ghost/content/themes/casper/post.hbs`. The section is near the bottom, in a commented out block. Uncomment the container and replace the contents with the above snippet.

To get Ghost to compile and use the new template, restart Ghost

```shell
# Switch to the commento user
sudo -u commento

# Move to Ghost root
cd /var/www/ghost

#Restart
ghost restart
```

You should be all set. Comments should start showing up in your posts.
