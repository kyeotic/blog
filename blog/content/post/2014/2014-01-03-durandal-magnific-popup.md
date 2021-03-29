---
title: "Magnific Popup and Durandal's Router"
url: "/durandal-magnific-popup"
date: "2014-01-03"
lastmod: "2014-05-03"
tags: ["durandal", "jquery", "lightbox", "magnific-popup"]
---

[Magnific Popup](http://dimsemenov.com/plugins/magnific-popup/) is a great little jQuery plugin that creates responsive lightbox's for images. I've used a few lightboxes, but this one definitely has the fewest number of issues when moving between desktop and mobile sizes.

All of it's documentation and examples, though, assume that you will be wrapping your `<img>` tag with an `<a>` tag, where Magnific will actually be pulling the information for the lightbox for. There is an integration issue here with [Durandal](http://durandaljs.com/), because the router plugin will cause any `<a>` with an `href` attribute to cause the router to try to navigate. Magnific will cause this navigation to be to `undefined` which obviously won't work. The lighbox will still open, but you will get an unhandled route.

My solution to this is to use just the `<img>` tag, and write a little jQuery hack to copy the `src` and `alt` attributes to a matching `href` and `title` attributes that Magnific is expecting, before initializing Magnific on the `<img>` tag. It looks like this:

```js
$('.image-link').each(function() {
    $(this).attr('title', this.alt);
    $(this).attr('href', this.src);
});

$('.image-link').magnificPopup({
    type: 'image',
    gallery: { enabled: true }
});
```
