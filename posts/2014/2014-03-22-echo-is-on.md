---
title: "Echo is on."
pathname: "/echo-is-on"
publish_date: 2014-03-22
tags: ["batch", "script"]
---

Batch script is old. Batch script is quirky, and has the syntax of the aborted love child of bash and perl. This shouldn't be news to anyone, but if you use batch script as infrequently as I do I have something that might be news. Consider the following block of code

    if %PORT% == 80 (
        CALL someScript.bat
        set error=%errorlevel%
        if %error% neq 0 exit /b %error%
    )
    

Batch script parses blocks, like the blocks inside an `if` statement, before it executes them. Under normal operation it also assigns the value of any declared variables at the time it parses, instead of during execution like it would outside of a block. That means under normal operation batch script will not allow you to declare *and* access a variable inside the same block; the variable will just be empty. If you are trying to debug this crazy scenario by `ECHO`ing the variable you declared, you will get this message:

> Echo is on.

This is because the variable has no value. The script is trying to read `error`*before* it actually sets `error`.

**I cannot imagine any scenario in which this behavior is desired**.

But batch script is old, and quirky, and in all likliehood is responsible for your parent's death.

The fix to this is simple, but its necessity is still aggravating. [Delayed Expansion](http://ss64.com/nt/delayedexpansion.html), which causes the batch script to assign variables inside blocks during execution instead of parsing, if you access the variable by using `!error!` instead of `%error%`. That's right: even in a special mode designed to fix an insane default behavior, you still have to use a special access syntax. The correct block would look like this:

    if %PORT% == 80 (
      CALL someScript.bat
      set error=!errorlevel!
      if !error! neq 0 exit /b !error!
    )
    

Fuck batch script.
