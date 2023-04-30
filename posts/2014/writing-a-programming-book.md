---
title: "Writing a Programming Book"
pathname: "/writing-a-programming-book"
publish_date: 2014-06-07
tags: ["knockout", "teaching", "writing", "programming"]
---

I am writing a book on [KnockoutJS](http://knockoutjs.com/index.html). I've taught JavaScript and Knockout at work before, but I have never tried to produce a book on programming. I ran into some pretty big challenges trying to put the first chapter together.

My first idea was drawn from experience teaching JavaScript at work, where I created interactive exercises for people to work through that were written alongside instructions and explanations. This was doomed to fail, since books are not interactive. After putting a bunch of code together I tried to break it down step-by-step, but could not find a good order to do so. I wanted readers to be able to add code as ideas were discussed, but bouncing back and forth between adding code and explaining it was jarring. It also created a poor organization, with ideas being discussed in the order they were used in the application instead of in an order that might be used to actually *teach* someone.

My next idea was to front-load all the knowledge needed to work through the entire 1st chapter exercise, and then add code piece by piece. This ended up with a mind-numbing 20 pages of nothing for the reader to actually see *running*, followed by a shotgun of code with little explanation nearby. This made a good future reference, but I think it would have made a terrible learning experience.

My third attempt was to follow a more straightforward organization, but end each explanation with a bit of working code that demonstrated only that one thing. Then, near the end of the chapter, show the full exercise application. Since all the individual ideas had already been covered, I could safely talk about how they fit together, instead of how they actually worked. I think this has worked out much better.

In hindsight the 3rd way seems obvious. It's how I remember textbooks being organized in High School. My problem was that I didn't learn to program like this: I learned to program by being thrown into a use case and learning each piece as I built it. I learn new languages and libraries by just making an application and figuring it out as I go. This doesn’t work when writing a book. I am a little worried that what works for writing a book won’t work for people who are trying to learn how to use Knockout.
