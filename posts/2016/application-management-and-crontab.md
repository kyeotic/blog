---
title: "Application Management and Crontab"
pathname: "/application-management-and-crontab"
publish_date: 2016-01-08
tags: ["nodejs", "centOS", "linux-admin-for-beginners"]
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

When working with Nodejs starting your applications and keeping them running is not always straightforward. There are tools to help you with this, like [forever](https://www.npmjs.com/package/forever) and [pm2](https://www.npmjs.com/package/pm2), but if you are doing any kind of [deploy-and-build](/deploying-applications-with-git-and-ssh) step you will need to have more of a plan than "run the application."

My application server management consists of five pieces

1. The application directory structure
2. Shell scripts to manage the individual application
3. A git repository with a post-receive hook
4. A shell script to manage all applications
5. Cron to make sure everything stays up and starts after a reboot

## Application structure on the server

A consistent directory structure will help keep you sane as the number of projects on your server grows. Here is what I use

    ~/
    |- /git
    |   +- /project.git
    +- /webapps
        +- /project
            |- /app
            +- /run
    

The git repository holds the source code. The `/webapps` directory has a project folder for every project. The `/project/app` directory holds the actual application code. The `/project/run` directory holds several scripts that control the application.

## Shell scripts for the application

I use five shell scripts to manage every application. If I ever take some time to learn bash better, I will condense them down to one script with flags, but I am not there yet. To simplify project setup, all five can be downloaded and Regexed (sed) into place with this command.

    curl https://raw.githubusercontent.com/tyrsius/scripts/master/linux/node-hooks/download-all | sh -s APPDIR APPPORT
    

I have these scripts to encapsulate application control. They are called from various places, and if individual applications have special constraints, or all applications need to change, I only need to make changes to these scripts. Some of them, like the one-line `stop` may seem like overkill, but if I ever switch from **forever** to **pm2** its going to save me a lot of headaches to only update a couple `stop` scripts.

These are the scripts.

### ./start

The `start` script is a safe-for-cron script. It can be run and re-run without any negative side-effects, because it checks to see if the app that it's about to start is running before trying to actually start it.

    #!/bin/sh
    procs=$(forever list | grep -F /home/tyrsius/webapps/portfolio/app/server.js)
    if [ -z "$procs" ]; then
      PORT=32101 NODE_ENV=production forever start \
        /home/tyrsius/webapps/portfolio/app/server.js
    fi
    

### ./stop

    #!/bin/sh
    forever stop /home/tyrsius/webapps/portfolio/app/server.js
    

Just stop the app. Moving on.

### ./restart

    #!/bin/sh
    . /home/tyrsius/webapps/portfolio/run/stop
    . /home/tyrsius/webapps/portfolio/run/start
    

If any of these scripts are redudant or able to be dropped, it's restart.

### ./install

    #!/bin/sh
    cd /home/tyrsius/webapps/portfolio/app
    #npm install
    npm run setup
    npm run build
    

This is a pretty important one: it controls how the app is built. It will be used when the app is updated by git's `post-receive` hook.

### ./restart-install

    #!/bin/sh
    . /home/tyrsius/webapps/portfolio/run/stop
    . /home/tyrsius/webapps/portfolio/run/install
    . /home/tyrsius/webapps/portfolio/run/start
    

Since the app needs to install *in-between*`stop` and `start`, the `restart` script can't be used (which is part of what really limits its utility). This is the script that is *actually* called from git's `post-receive` hook.

## Git post-receive hook

I cover this topic in my [Deploying with SSH post](/deploying-applications-with-git-and-ssh). In short, this script runs after `git push`.

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
    

## A shell script for all applications

Now some people skip this step and just load the `start` script for each application into their cron jobs. I don't like doing this, because I want to run cron every fifteen minutes ***and*** after reboot. This would mean writing the call to the start script **twice**, for **each application**. Instead, I wrap all of them into one script.

    apps=(
     "blog"
     "portfolio"
     "home"
      #etc...
    )
    for i in "${apps[@]}"
    do
      /home/tyrsius/webapps/$i/run/start
    done
    

This has the added advantage of the very clean "one app per line" format that the `apps` array loop gives us. Also, because each `start` script is safe to run multiple times, so is this script.

## Cron jobs

Last, but certainly not least, is the cron job that makes sure the apps are always running.

    PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/tyrsius/bin/node/bin
    
    @reboot /home/tyrsius/webapps/start-all-apps
    */15 * * * * /home/tyrsius/webapps/start-all-apps
    

It's simple, and it never needs to grow. When new apps are added, they go into `start-all-apps`.

The `PATH` for cron jobs won't include node normally, which I why I have to manually set the path at the top; otherwise, the `start` script calls to `forever` will fail.

# Spinning up new apps

This can all be done manually, without *too* much effort. However, as a developer, I prefer to automate as much as possible. WIth that in mind, I have a script that will create a new project directory, a new git repo, and even add an entry to `start-all-script` for me. Its long, and uses scripts I have stored on GitHub, but you might find it interesting.

    #!/bin/sh
    # $1 app directory
    # $2 app port
    # $3 git repo
    # $4 subdomain
    cd /home/tyrsius/webapps
    mkdir $1
    cd $1
    mkdir app
    mkdir run
    cd run
    curl https://raw.githubusercontent.com/tyrsius/scripts/master/linux/node-hooks/download-all | sh -s $1 $2
    cd /home/tyrsius/git
    git init --bare $3.git
    cd $3.git/hooks
    rm *
    curl https://raw.githubusercontent.com/tyrsius/scripts/master/linux/post-receive | sh -s $1
    sed -i "s/)/# \"$1\"\n)/g" /home/tyrsius/webapps/start-all-apps
    

The comments at the top show you what arguments it needs to be called with.

There is a line at the bottom that I have omitted that also adds configuration to nginx for this newly created app, but explaining it would require another blog post. Maybe next time.
