---
title: "Center DIV Vertically and Horizontally with full width and height"
pathname: "/center-div-vertically-and-horizontally-with-full-width-and-height"
publish_date: 2016-01-29
tags: ["css"]
---

There are way too many solutions to this online that just don't work. I want a full-page absolutely centered DIV. It needs to center in the browser, which means forcing the correct height and width.

This uses flexbox, so it doesn't work in Internet Explorer (yes, even IE11... I thought we were passed this?)

```css
.center-on-page {
	height: 100vh;
	width: 100vw;
	display: flex;
	justify-content: center;
	align-items: center;
}
```

`vh` and `vw` are **viewport** relative units, which will cause this `div` to be the size of the entire browser.
