---
title: "Building Durandal with Grunt"
url: "/building-durandal-with-grunt"
date: "2014-01-17"
lastmod: "2014-05-03"
tags: ["gruntjs"]
---

Durandal is a great framework, but if you are moving your application to a production environment chances are you want to build it. Building a RequireJS app can be done with R.JS, with Durandal's build tool [Weyland](https://github.com/BlueSpire/Weyland), or with a task runner like [Mimosa](http://mimosa.io/) or [Grunt](http://gruntjs.com/).

Weyland is a good option if you don't plan to do anything else, but I am interested in a lot of the plugins available for more general tools like Grunt. Things like JSHint and an the test runner when coupled with the Grunt watcher can make development feedback easy and instantaneous. Grunt also allows you a lot more control over the build process, allowing you to write your own tasks to do just about anything.

When decided between Mimosa and Grunt, I chose primarily based on perceived popularity. I have just seen more `Gruntfile`'s in the wild than Mimosa ones.

## Getting your project ready

Before you start using Grunt, give some thought to how you want your project to looks when you are done. Grunt is going to require a `package.json` and `Gruntfile.js` in the directory is runs from, and it will install a `node_modules` directory to store the tasks in. If your application is using a NodeJS server, this is going to create some tension, as your server needs its own `package.json` and `node_modules`. You could put Grunt into a seperate folder, but I took a page out of [KnockoutJS's](https://github.com/knockout/knockout) book, and put my entire project inside of a `src` folder at root, and put Grunt in the root directory. This allows you to step right into the root directory of the project and just run `grunt` from the command line, which is pretty handy.

## Setting up Grunt

Grunt needs 3 things to work

1. **The Grunt-cli** - the command line component

- **package.json** - The file detailing for Grunt which modules it needs
- **Gruntfile.js** - The file that Grunt actually runs

### Installing the CLI

Grunt is an `npm` package, so installing the cli is done through `npm`.

    npm install -g grunt-cli
    

### Creating your `package.json`

Just make a file in your project root with this

    {
        "name" : "[ProjectName]",
        "version" : "0.1.0",
        "author" : "Timothy Moran",
        "private" : true,
    
        "devDependencies" : {
            "grunt" :						"~0.4.0",
            "grunt-contrib-watch":			"*",
            "grunt-contrib-jshint":			"*",
            "grunt-htmlhint":			    "*",
            "grunt-durandal":				"*",
            "matchdep":						"*"
        } 
    }
    

The `devDependencies` specify which Grunt packages to install. To install these packages just run `npm install` from your project root. This will also install the Grunt runner for you.

### Creating your `GruntFile`

Your `Gruntfile` is the configuration and task list for Grunt. I am going to be using JSHint to check my javascript (excluding the compiled js file which will end up in the same directory), using HTMLhint on all my views, and then using `grunt-durandal` to concatenate and optimize all the Javascript (it uses `r.js` and `uglify2` internally). This is my `Gruntfile`.

## Using Grunt

You can do a couple things with this setup. If you just run `grunt` from the command line, all of the steps will be carrier out in sequence. If you run `grunt watch`, JSHint and HTMLHint will be run and the re-run anytime one of the wacthed files changes. Lastly, you can run an individual command like `grunt jshint` to just one that one section.

That's it!
