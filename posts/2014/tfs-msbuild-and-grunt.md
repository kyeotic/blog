---
title: "TFS MSBuild and Grunt"
pathname: "/tfs-msbuild-and-grunt"
publish_date: 2014-03-10
tags: ["mdbuild", "grunt", "tfs"]
---

Getting [Grunt](http://gruntjs.com/) working with TFS and MSBuild was a pain in the ass this week. There were several problems that took me several hours to figure out, so hopefulyl I can save you some pain with this.

1. TFS's 260 character limit on path names is very likely going to cause you problems, since `npm` nests internal dependencies. You probably figured this out pretty quickly, since you won't be able to follow the best practice of checking in your NodeJS dependencies, but I wanted to spell this out since other problems on this list are caused by the first one.
2. MSBuild, in most setups, cleans the entire source directory before it builds, instead of updating via delta. This means that if you make manual modifications to the build directory that aren't in TFS, they will be lost. Again, your probably figured this out pretty quickly, but I wasted an attempt on this.
3. My next attempt was to try to install all of the dependencies as global on the build server, so that `grunt` would pick them up without them being in the source directory. This won't work either, as both `grunt` (not the `cli` version) and `phantomjs` require a local copy, not a global copy, to work. You will need real dependencies installed. My solution to this was to add a pre-build step to the project that copied the dependencies from a known location (`S:\`, in my case) into the project so that a local version existed.
4. Under linux, Grunt's `childProcess` properly isolates any changes to the `current working directory` from changing the build tasks. Not so on Windows. You will need to make sure and and `cd $(SolutionDir)` after your Grunt step if you have any further tasks to perform. This one stumped for the longest, as MSBuild's log file doesn't properly capture the error that results.

My solution was to create a post-build event that first copied all the `node_modules` dependencies from a known location (I stuck them on the `S:` drive) so that a local package could be found. Then I ran `cd $(SolutionDir)`, then `grunt`, then I re set the working folder by calling `cd $(SolutionDir)` again. Finally, I removed the `node_modules` folder so that msbuild didn't hang on the next build when it tried to clean the folder (it was hanging out the path name being too long, again).

The event looks like this

    cd $(SolutionDir)
    xcopy S:\Grunt /e
    grunt build
    cd $(SolutionDir)
    RD /S /Q "node_modules"
    

Hopefully this saves you some headache.
