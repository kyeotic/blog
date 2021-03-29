---
title: "Gulp in Windows"
url: "/gulp-in-windows"
date: "2014-04-17"
lastmod: "2014-05-02"
tags: ["windows", "gulp"]
---

Maybe you thought you were going to try out the new(ish) javascript build/task system [Gulp](http://gulpjs.com/). Maybe like me you are running Windows, the red-headed step child of the Node world. If so, you may have run into one or more of the following problems.

Gulp is pretty finnicky with its installer. The first problem I ran into is that my **NPM** was just ever so slighly out of date (about 4 months old). This caused an error, but unfortunately I forgot to record what it was. This is easy enough to fix, just upgrade NPM.

The next thing to fail was my lack of [Python](https://www.python.org/). I've never seen an **NPM** package require Python before, but oh well. I tried to install with [Chocolatey](https://chocolatey.org), but that installed Python 3.4. Gulp only works with Python 2.X. Ok, damnit. Uninstall Python, download an old version from their site, then install. I must be done... nope, the Python installer didn't add Python to the path! Ok, add that.

Next up is this beautiful error: `MSBuild error... Could not load Visual C++ Component "VCBuild.exe"`. The error goes on to tell me to install .NET 2.0, then Visual Studio 2005,*lol*, and add that to my path. At this point, after some Googling, I found out this was the real culprit: [node-gyp doesn't build things well on Windows 64 bit](http://stackoverflow.com/questions/14278417/cannot-install-node-modules-that-require-compilation-on-windows-7-x64-vs2012). That link has some resolutions, [I went with this one](http://stackoverflow.com/a/19736102/788260):

    (Install VS2102)
    npm install -g node-gyp --msvs_version=2012
    npm install -g gulp --msvs_version=2012
    

This got me past *that* error.

**Edit:** for Visual Studio 2013 use `msvs_version=2013e`

Next up was `CancelloEx: Identifier not found` when trying to install `gaze@0.6.3`. This ended up being resolved by rebooting my computer.

Gulp appears to be working now.
