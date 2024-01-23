---
title: "Proxmox SMB Shares with Cockpit"
pathname: "/proxmox-cockpit"
publish_date: 2024-01-19
tags:
- homelab
- proxmox
- nas
- smb
- cockpit
---

This guide is a part of a series on Proxmox for Homelabs. You can find the [Series Overview here](/proxmox-series).

In the previous guide we covered how to [bind mount your ZFS Datasets with LXC Containers](/proxmox-zfs-mounts). This guide will cover setting up a Samba/SMB Share with Cockpit.

> This guide borrows heavily from [this one from casaursus](https://homelab.casaursus.net/a-light-weight-nas). If you have questions their version probably answers them. This is a much-condensed version.

## Creating a new Container

Create a new, unprivileged LXC Container (ideally using Debian, so the commands below work) and [bind mount the ZFS Datasets](/proxmox-zfs-mounts) you want to share. Make a note of the group name you created in the LXC (the linked guide used "nas_shares"), we will need it later.

Once that is done, boot up the container and open a shell.

```
apt update && apt dist-upgrade -y

# Install Cockpit
apt install cockpit --no-install-recommends

# Install the necessary extensions (check for new versions, if you like)
wget https://github.com/45Drives/cockpit-file-sharing/releases/download/v3.3.4/cockpit-file-sharing_3.3.4-1focal_all.deb
wget https://github.com/45Drives/cockpit-navigator/releases/download/v0.5.10/cockpit-navigator_0.5.10-1focal_all.deb
wget https://github.com/45Drives/cockpit-identities/releases/download/v0.1.12/cockpit-identities_0.1.12-1focal_all.deb

# Install them
apt install ./*.deb -y

# Cleanup the installers
rm *.deb
```

Now we need to allow root to login. run `nano /etc/cockpit/disallowed-users` and either remove or comment out the line with `root` on it.

Then open `https://<ct-ip>:9090` in a web browser, and login with root credentials.

## Creating users

Since you should not create SMB shares with the root user, even in a container, create one (or more) users by going to **Identities > Users** and clicking **New Users** (confusingly, this looks like a user named " New User).

**Make sure to add your Host-Mapped Group to the user!**. This was "nas_shares" for me, you may have changed the name. Without this group membership the share will not be usable.

Once the user is created go back to the users page and edit the user. It needs a **Samba Password** to use SMB Shares, so create one. It can be the same as their login password, but you still have to type it again anyway.

## Creating the Shares

First, go to File **Sharing > Samba**, open **Advanced Settings** and add `inherit permissions = yes`, then **Apply**.

Then, create then Shares you want.

* The `name` is what will appear to users.
* The `path` is the path to the bind mount, e.g. `mnt/media_root/media`
* Add the `nas_shares` group to **Valid Groups**
* Select either **Windows ACLs** or **Windows ACLs with Linux/MacOS Support**, depending on your primary users.

