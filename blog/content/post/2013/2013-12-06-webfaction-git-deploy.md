---
title: "Setting up SSH Git deploy with Webfaction"
url: "/webfaction-git-deploy"
date: "2013-12-07"
lastmod: "2015-12-31"
tags: ["git", "deploy", "webfaction", "node", "ssh"]
---

I spent about three days trying to get this to work with an https server, but eventually gave in. There were too many issues related to the account the hook would run under for my limited linux experience to solve. So the SSH method will have to do for now.

### Setting up Git

If you follow [this guide](http://docs.webfaction.com/software/git.html) through the **Creating a new repository** section, you should be good. For the sake of history, here are the installation steps from it

> - Log in to the control panel.

- Click Domains / websites ‣ Applications. The list of applications appears.
- Click the Add new application button. The Create a new application form appears.
- In the Name field, enter a name for the Git application.
- In the App category menu, click to select Git.
- In the Extra info field, enter a password for the default user.
- Click the Save button.

### Creating the Deploy Hook

Once you have a git repo made, it will contain a `hooks` directory with a bunch of sample code in it. `cd` into the repo and run `rm -rf hooks/*` to clear it out.

You will want to make a file named `post-receive` (note that there is no file extensions). Using `nano` is my preferred way. Inside of this file you will want to do 2 things.

- Update your application with the most recent checkin
- Start the application with w/e process you are using

The first step is straightforward, just put this at the top of the file

    #!/bin/sh
    GIT_WORK_TREE=/home/username/webapps/YOURAPP/app git checkout -f master
    GIT_WORK_TREE=/home/username/webapps/YOURAPP/app git reset --hard
    

This will clear the application directory, and put it at the `HEAD` of your repo.

### Organizing your app code

Now, you can start your app however you want, but I took a page out of Ghost's book, and setup a `run` directory with three scripts in it: `restart`, `start`, and `stop`. I put this folder next to my application's actual code, under a root folder for the whole app.

     |ApplicationFolder
     -app
     --**actual contents of app**
     -run
     --**scripts to start and stop the app**
    

It contains things nicely, and seperates these scripts from the application code.

So, the scripts.`restart` calls `stop` then `start`. The reason for the other two are just consolidation: you need to start your app from the deploy hook, you probably want to have `crontab` start your app, and you may need to do it manually from time to time.

So what does `start` look like?

    #!/bin/sh
    procs=$(forever list | grep -F /home/username/webapps/YOURAPP/app/server.js)
    if [ -z "$procs" ]; then
        PORT=3000 forever start /home/username/webapps/YOURAPP/app/server.js
    fi
    

So lets break that down. We are going to scan for any current instances of the app. If we don't find any, we are doing to start it. This makes the `start` script safe to run. This is handy if you want your `crontab` entry to run every X minutes, instead of just on reboot.

To make a cron job for this, add this like to `crontab`, where `xx` is the interval in minutes.

    */XX * * * * ~/webapps/YOURAPP/run/start
    

Here is the `stop` script:

    #!/bin/sh
    forever stop /home/username/webapps/YOURAPP/app/server.js
    

Now, you can just call your `start` script at the end of your `post-receive` hook.

One more note on the scripts. For the `post-receive` hook, as well as the scripts, you will need to make them executable. The shell command for that is `chmod +x /path/to/file`

### Setting up the client

The last thing you will need to do is setup a new `remote` repository on your clients. It's pretty easy.

    git remote add NAME username@username.webfactional.com:/path/to/repo
    

Now you can just `push` to this remote, and your application should deploy and start up! Your done.

### Advanced Hook (specific branch)

If you only want to run off of a specific branch (like `master`), you can employ this `post-receive` hook

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
    
