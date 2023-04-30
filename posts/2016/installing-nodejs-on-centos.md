---
title: "Installing Nodejs on CentOS"
pathname: "/installing-nodejs-on-centos"
publish_date: 2016-01-08
tags: ["nodejs", "centOS", "linux-admin-for-beginners"]
---

This is part of my complete guide to [Setting up a CentOS Digital Ocean droplet with Nginx for beginners](/digital-ocean-for-beginners).

## Where to get it from

Yum has a Nodejs package. I don't recommend using it. It update slowly, and you are probably going to want to manage node and npm's version yourself. I highly recommend installing and updating node yourself, without a package manager (other than npm). Later on, being able to update Nodejs *though npm* is going to make your life a lot easier.

## Where to put it

There is [some confusion](http://askubuntu.com/questions/308045/differences-between-bin-sbin-usr-bin-usr-sbin-usr-local-bin-usr-local) over where it is best to install things on linux. I think [this answer](http://askubuntu.com/a/308048) gives a good overview of the purpose of the available options, but it still isn't clear to me if the recommended solution to this is `/usr/bin` or `/usr/local/bin`.

I don't use either.

I install Nodejs in `~/bin/node`. This does produce the rather redudnant `PATH=$PATH:$HOME/bin/node/bin`, but I still prefer to have it in a directory under `$HOME`. Nodejs, primarily because of npm, is kind of unique. It isn't a shareable binary, because it's "global" environment shouldn't be shared with other users. It's mutable, and I want to keep it completely isolated. `/usr/local/bin` would do that, but I want to make it extra special. This might seem crazy, and it might be. If you want to install under `/usr/local/bin`, just make the manual adjustment.

Whatever you do, ***do not install nodejs in a location that requires sudo access***. Not only will it make it pointlessly difficult to run your application later, sudo changes your path in ways that will turn npm into a bi-polar ax murderer.

## Manual Installation

I use this script, modified from [here]([https://gist.github.com/isaacs/579814](https://gist.github.com/isaacs/579814). It stuff it in `~/bin/node` and adds `$HOME/bin/node/bin` to your path. The `make install` is going to take a few minutes.

    echo 'export PATH=$PATH:$HOME/bin/node/bin' >> ~/.bashrc
    . ~/.bashrc
    mkdir bin -p
    cd ~/bin
    mkdir node -p
    rm -rf install-node 
    mkdir install-node -p
    cd install-node
    curl https://nodejs.org/dist/v4.2.0/node-v4.2.0.tar.gz | tar xz --strip-components=1
    ./configure --prefix=~/bin/node
    make install
    curl https://raw.githubusercontent.com/npm/npm/master/scripts/install.sh | sh
    cd ~/bin
    rm -rf install-node
    

You can run this super easily with this handy one-liner.

    curl https://gist.githubusercontent.com/tyrsius/7324aaa515ade384cb1c/raw/927e4cd87d54a64c7a4ffc3b14739e5437346c35/node-and-npm-in-30-seconds.sh | sh
    

If the length makes that linebreak in your browser (it will), just trust me. It's one line.
