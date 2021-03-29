---
title: "Deploying Applications with Git and SSH"
url: "/deploying-applications-with-git-and-ssh"
date: "2016-01-08"
lastmod: "2016-05-14"
tags: ["git", "ssh", "linux-admin-for-beginners"]
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

I've [written about this before](/webfaction-git-deploy), but my methods have changed somewhat since then. Digital Ocean also makes it quite a bit easier than webfaction. Hopefully you have already gone though the [DNS Managment guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean). if you have not installed git and setup a CNAME for `git.DOMAIN.com`, you should do that now.

## Setting up the remote server

If you are just using SSH to connect to git, instead of HTTP, the setup is actually pretty simple. You just need a git workspace *somewhere* on your remote machine (droplet, our this case).

I recommend keeping all of your git workspaces in `~/git`.

    mkdir ~/git
    

For this guide I am going to be using my portfolio as an example. This is how you create a workspace.

    cd ~/git
    git init --bare portfolio.git
    

The `.git` suffix is conventional, not necessary. The `--bare` flag just tells git not to stick things into the standard `.git` hidden directory. Since we aren't using this directory to do work, the extra nesting doesn't help. Its still a full repo, but getting to the very useful `/hooks` directoy will be `/portfolio.git/hooks` instead of `/portfolio.git/.git/hooks`. Much cleaner.

That's... actually all you need to do on the server. This directory is ready to be pushed to over ssh.

## Confuring the local machine

Since we are pushing over ssh, we need to tell git where the server is at. This is done by configuring your **remote branches**. You usually only have one remote, `origin`, which is the default remote that receives your changes when you `git push`. If you are not using GitHub or some other public repository as your primary, you can alter this remote

    git remote set-url origin USER@git.DOMAIN.com:git/portfolio.git
    

However, you are probably using Github, and want to continue using it. In that case, you need to add a **new** remote branch. I am going to call this remote `digi`, for Digital Ocean

    git remote add digi USER@git.DOMAIN.com:git/portfolio.git
    

We can push to this remote with

    git push digi master
    

You will be prompted for your SSH password, and then the branch will push. Your droplet now has all your source code in it.

## Updating your server on push

Once your code has been pushed into the repository, you're probably going to want to do something with it. Like move it into the directory it is hosted from.

> Unfortunately this guide is going to hit a chicken/egg problem, since we haven't talked about that yet. If you haven't setup your application yet, you might want to hop over to the [Application Managment guide](/application-management-and-crontab) first. Otherwise, continue.

We can do this very easily by setting up a **post-receive** hook in git. This is a script that will run when a git receives a push. The perfect spot for copying files our of the repository, and running any setup commands our application requires.

I use one of two post receive hooks.

### The single branch hook

This hook will fire after *every* push, which implies that you are really only working with one branch. For applications that I host in GitHub, which contains all my branches and tags, I only ever push the `master` branch to my hosting server. In this case, a hook that fires every time is good enough, since only production code is ever going to be received.

Open a file editor to put our post receive hook into

    cd ~/git/portfolio.git/hooks
    nano post-receive
    

Then enter the script

    #!/bin/sh
    GIT_WORK_TREE=/home/tyrsius/webapps/portfolio/app git checkout -f master
    GIT_WORK_TREE=/home/tyrsius/webapps/portfolio/app git reset --hard
    . /home/tyrsius/webapps/portfolio/run/restart-install
    
    

This script assumes you are using the structure I use in the [Application Managment guide](/application-management-and-crontab), where `PROJECT/app` contians the application code, and `PROJECT/run` contains scripts for managing it.

This hook updates the `/app` directory with the latest code before running the `restart-install` script. This makes it easy to manage to the actual process of stopping the app, building the new code, and restarting it *from the app*, instead of from git. Once git is setup, we shouldn't ever have to come back here.

### The multiple branch hook

Some of my projects are not open source. Actually, right now just one. Its the project that runs my house (Nest, my Hue Lights, some other smart stuff). I don't have a solid grasp on how to secure these things yet, and I don't want anyone trolling my energy bill. You may also have the occasional need to keep your code off of GitHub. If you do, you probably still want your source code to live off of your home computer, and this means keeping the `master`**and**`dev` branch on your remote server.

The single branch hook is going to give you trouble in this situation. Luckily, we can make this script conditional on the branch name.

    #!/bin/sh
    while read oldrev newrev refname  
    do  
        branch=$(git rev-parse --symbolic --abbrev-ref $refname)
        if [ "master" == "$branch" ]; then
            GIT_WORK_TREE=/home/username/webapps/YOURAPP/app git checkout -f master
            GIT_WORK_TREE=/home/username/webapps/YOURAPP/app git reset --hard
            . /home/username/webapps/YOURAPP/run/restart
        fi
    done  
    

You may want to use this for all your hooks anyway, just to be safe.
