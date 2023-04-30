---
title: "Moving to Deno Deploy"
pathname: "/blog-deno-deploy"
publish_date: 2023-04-30
tags:
- deno
- "deno deploy"
- blog
---

[Deno Deploy](https://deno.com/deploy) is an edge hosting platform for Deno projects. It's got a generous free tier and just launched a [Deno Kv](https://deno.com/manual@v1.32.4/runtime/kv) Beta. After moving over my [snow tracker](https://snow.kye.dev/) I decided to try out the [deno blog kit](https://deno.land/x/blog@0.5.0). I'm very happy with it so far, but it did require some un-documented changes in order to get what I wanted out of it.

## Basic Setup

The [getting started guide](https://deno.land/x/blog@0.5.0#getting-started) covers what you need for the basics.

A minimal setup looks like this

```ts
import blog, { ga, redirects } from 'https://deno.land/x/blog@0.5.0/blog.tsx'

blog({
  title: 'T++',
  author: 'Tim Kye',
  avatar: './images/avatar.png',
  avatarClass: 'full',
  favicon: './images/favicon.ico',
  links: [
    { title: 'GitHub', url: 'https://github.com/kyeotic' },
    { title: 'Email', url: 'mailto:tim@kye.dev' },
  ],
})
```

Wow! Look how tiny that is! After doing this any markdown files in `/posts` will be turned into posts, and their [front matter](https://jekyllrb.com/docs/front-matter/) will be parsed using the (currently undocumented) options:

* `title`: title of the post, rendered at the top as an `<H1>`
* `pathname`: a url override. Without this the file name will be used for the url.
* `publish_date`: Date of the post, used for sorting on the home page
* `tags`: an array of string tags which will show on the post and can be used to filter the post list

Coming from Hugo all I had to do was copy my `/contents` directory into `/posts` and do some find-replace-all on the front matter tags. It took less than 5 minutes.

The big problem with this kit is the documentation. Beyond getting started there isn't any. Everything I did below I had to figure out by reading GitHub issues and source code.

## Things I changed

### Syntax Highlighting

Out of the gate Syntax Highlighting for fenced-code blocks works, but [only for C](https://github.com/denoland/deno_blog/issues/15). As [this issue](https://github.com/denoland/deno_blog/issues/15) explains in [a comment](https://github.com/denoland/deno_blog/issues/15#issuecomment-1181923643) you can add additional languages by importing the proper PrismJS lexer.

```ts
import "https://esm.sh/prismjs@1.27.0/components/prism-typescript";
import "https://esm.sh/prismjs@1.27.0/components/prism-ruby";
import "https://esm.sh/prismjs@1.27.0/components/prism-python";
import "https://esm.sh/prismjs@1.27.0/components/prism-go";
```

This needs to go anywhere that eventually gets loaded by your blog code. I put mine in `/config/highlight.ts`, where I also included a custom theme for Prism.

### PrismJS Theme

In order to use a custom PrismJS theme you need to include its CSS. I took a theme from [prism-themes](https://github.com/PrismJS/prism-themes) and put it in a template string which I pass to the `style` property of the `blog` function. 

```ts
import { xonokai } from './config/highlight.ts'

blog({
  // .. unchanged
  style: xonokai,
})
```

You can include any other style changes you want in this same fashion.

> There is an `unocss` option on `blog()`, but it takes a complete theme, not a partial override. This means if you provide anything there, you lose all the default styling. I couldn't find an export of the existing theme, so I wasn't able to extend it. Using `style` was the path of least resistance.

## Issues

As of time of writing there are two issues with the kit.

1. YAML does not parse correctly. This is a problem with the underlying markdown parser [deno-gfm](https://github.com/denoland/deno-gfm). I've opened a [GitHub issue](https://github.com/denoland/deno-gfm/issues/60) to track it.
2. Using a `pathname` breaks routing with a 404, because it tries to load a file by the name of the path. I've opened [a PR](https://github.com/denoland/deno_blog/pull/130) that fixes this, and am using this fork in my own blog in the meantime.