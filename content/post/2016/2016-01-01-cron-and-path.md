---
title: "Cron and $PATH"
url: "/cron-and-path"
date: "2016-01-02"
lastmod: "2016-01-02"
tags: ["linux", "cron"]
---

Linux has a handy tool for runing jobs on a schedule: cron. This is great for things like ensuring your webserver is up, especially in a shared environment like WebFaction where your server may periodically reboot.

If you try to add scripts to it that rely on your users `$PATH`, things will fail. Cron runs with its own, very limited path. To get around this, just `echo $PATH` and stuff the result at the top of your crontab entry

    PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/tyrsius/bin
    

This will ensure that the scripts you run have access to things like [Forever](https://github.com/foreverjs/forever).
