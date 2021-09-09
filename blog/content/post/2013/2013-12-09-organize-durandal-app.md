---
title: "Organizing a Durandal Application"
url: "/organize-durandal-app"
date: "2013-12-09"
lastmod: "2014-04-16"
tags: ["durandal"]
---

[Durandal](http://durandaljs.com) is currently my Javascript MV* framework of choice. It's flexible, powerful, and written by the same guys who did the WPF MVVM framework Caliburn.Micro.

## Conventional Organization

In it's tutorial, and by way of using `app.useConvention()`, it opines on an organization for your client code that looks like this:

    client
    |--app
    |	|--views
    |	|	+--shell.html
    |	|--viewmodels
    |	|	+shell.js
    |	+-main.js
    +--lib
    	+--durandal


When you compose a viewmodel, Durandal locates the view for it by replacing the `viewmodels` section of its path with `views`. If your viewmodel is at `app/viewmodels/shell.js`, it will look for the view at `app/views/shell.html`.

This is great for small projects. HTML goes in the view folder, JS goes in the viewmodels folder. Once you start getting even a medium sized project though, this organization becomes cumbersome. You will either have two flat folders full of files, or two mirrored trees. Trying to open one pair means opening half in one tree, and half in another. I don't think this scales very well.

## Module Organization

If you leave off the `app.useConvention()` call, you end up with a scheme I very much prefer. No path replacement will occur. If your viewmodel is at `app/shell/shell.js`, it will look for the view at `app/shell/shell.html`. Basically, you get organization of modules by folder. An example layout might look like this:

    client
    |--app
    |	|--shell
    |	|	|--shell.html
    |	|	+--shell.html
    |	|--home
    |	|	|--index.html
    |	|	|--index.js
    |	|	|--login.html
    |	|	+--login.js
    |	|--user
    |	|	|--settings.html
    |	|	|--settings.js
    |	|	|--profile.html
    |	|	+--profile.js
    |	+-main.js
    +--lib
    	+--durandal


I think this organization scales much better. It matches conventional filesystem organization, which is I think easier to understand, and easier to navigate. When I want to work on something related to user, not only is each viewmodel/view pair located next to each other, but related viewmodel/view pairs are also right there. If I want to reuse a module in another project, I just copy the whole folder.

## Additional Modules

Where do you put code that doesn't go inside of a viewmodel (i.e. business logic, shared web service code, utilities)?

These seems like a simple answer, but I have seen [this question asked](http://stackoverflow.com/questions/16547279/why-is-there-no-suggested-model-folder-in-a-durandal-app/16569553#16569553) before, so I wanted to address it here. You just make a folder for them. The project structure provided by Durandal is a starting point, not a rigid skeleton.

I generally have a `services` folder which contians classes that abstract any web service calls, or other data access, a `models` folder where non-viewmodel objects go, and a `util` folder for common code.

## Tests

So far, all my Durandal projects have had a NodeJS backend (except the ones at work, which are in .NET). The standard answer here is that your whole application should be in one directory, and your tests should be in a sibling directory. Which means your app would look like this:

    Project
    |--source
    |	|--client
    |	|--node_modules
    |	|--views
    |	+--server.js
    +--test
    	|--unit tests
        +--integration tests


> A project seed using the organization in the post, with BootStrap 3.0 and the plugins I used can be found [here](https://github.com/kyeotic/durandal-seed).
