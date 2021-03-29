---
title: "Relative Paths and PushState in Durandal"
url: "/pushstate-relative-paths"
date: "2013-12-12"
lastmod: "2013-12-12"
tags: ["durandal", "pushstate"]
---

Modern browsers support the `history.pushState` api for changing the URL without actually navigating on the page. This is a nice replacement for hash-based navigation (where a hash-route is used to change the page without navigating, due to the hash not going to the server) since the URL looks like a normal, clean url. Other than smoother navigation, the implementation is invisible to the user.

But the server has to support this. It can do this in a couple ways, but it really depends on how the client is handling things.

1. The server can respond to requests for individual pages by rendering them for the client in their final state.
2. The server can respond to all requests with the same initial page, leaving the work of rendering the correct page state to the client
3. The server can perform some half-breed solution.

Durandal expects the 2nd scenario. It's router is fully responsible for the client-side rendering as well as navigation. It will examine the URL and load the correct page via its own **composition** sytem. But you can run into a problem, as I did, with relative paths. Consider the following two requests:

1. `www.site.com`
2. `www.site.com/projects/first`

In this case, if the shell that Durandal gets from the server references is initial **css** and **js** files using paths like `lib/require` and `css/main.css`, the second request will look for those under the `projects` directory. And fail. If, like me, you were using a wildcard route in NodeJS, after it fails to find a static file, the wildcard will return the initail html for those css and js requests. All kinds of crazy errors will result.

As I found out from [this stackoverflow question](http://stackoverflow.com/questions/10392317/relative-paths-and-pushstates/10432646#10432646), the solution is simple. Just add `/` to the begining of paths to make them absolute. `/lib/require` and `/css/main.css`. Now both responses will correctly retrieve their static files.

Note: if you are hosting your project under a non-root directory, you will need to add it to all of these links.
