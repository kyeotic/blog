---
title: "Q Promise resolves immediately when .done() is called"
url: "/q-done-promise"
date: "2014-04-05"
lastmod: "2017-05-02"
tags: ["q", "promises", "javascript"]
---

I just spent ***way*** to much time on this problem, and it turned out to be a wayward `.done()` attached to a promise that was getting passed downstream. Because `done()` returns nothing the next handler in the chain was resolving immediately, instead of waiting for the chain `done()` was attached to.

Take a look at the code, the problem is pretty easy to miss.

#### A normal, functioning chain

#### A broken chain, with a `done()` in the middle
