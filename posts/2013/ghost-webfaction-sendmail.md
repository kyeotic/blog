---
title: "Setting up Webfaction Sendmail with Ghost"
pathname: "/ghost-webfaction-sendmail"
publish_date: 2013-12-07
tags: ["sendmail", "email", "webfaction", "ghost"]
---

[Ghost's email guide](http://docs.ghost.org/mail/) leans pretty heavily on external services. It doesn't seem to think most people will want to use the server they are running on.

Setting up sendmail on Webfaction is pretty easy, since `sendmail` is installed on all their boxes. Just put this in your `config.js`

```js
mail: {
  transport: 'sendmail',
  fromaddress: 'no-reply@example.com',
  options: {}
},
```

There is a weird gotcha here though. This didn't work for me when I left off the `options` section entirely, and it also failed when I specified the full `path` to `sendmail`, as [this section](https://github.com/andris9/Nodemailer#setting-up-sendmail) encourages you to.
