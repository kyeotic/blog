---
title: "Writing Javascript tests that will run on Windows and Linux with Grunt"
pathname: "/grunt-phantomjs-windows-or-linux"
publish_date: 2014-02-07
tags: ["unit-test", "phantomjs"]
---

I primarily develop at home on my Windows machine, but all of my web projects live on a Webfaction-hosted linux machine. To create a smooth deployment process with Grunt that will run my tests on either machine I used the PhantomJS node package.

The trick here is that it can't be copied over with the deployment; it needs to be installed by npm on the target machine to run properly. You can make this happen pretty easily by ensuring it's installed globally on both machines, but still included in the `package.json` file. Npm is smart enough to not double up the installation when you run `npm install` from either box.

I am using the same Durandal/Jasmine setup I wrote about [here](/durandal-testing/). I am running the phantomjs `spec.js` file by using this Grunt setup

the `cwd` parameter is important, since the `spec.js` file uses path's relative to itself. Everything else is pretty self explanatory. If you want a more complete picture, you can check out my [portfolio project](https://github.com/tyrsius/portfolio/tree/fcf16721a79960e059a2f75de788bcdd9b97d461) as it was at the time this post was written.

I tried doing this with the actual `grunt-phantomjs` package, but the way it wraps things made it significantly harder to use. Since my `spec.js` was already fully setup, using PhantomJS directly was just easier.
