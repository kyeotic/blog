---
title: "Jasmine Spies Won't Load Outside Test Scope"
pathname: "/jasmine-spies"
publish_date: 2014-03-31
tags: ["jasmine spies", "unit-test", "jasmine"]
---

This is a pretty minor one, but it's not covered in [the documentation](http://jasmine.github.io/1.3/introduction.html). If you have a jasmine `spyOn` call inside of the `describe` but outside of a test or outside of a `beforeEach`**it will not run!**

This tripped me up for a bit today.
