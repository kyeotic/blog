---
title: "Setting up ConEmu with Git Bash on Windows"
url: "/setting-up-conemu-with-git-bash-on-windows"
date: "2014-12-04"
lastmod: "2014-12-04"
---

The Windows command prompt sucks. It just does. Every other terminal in every other operating system is better than it, and Microsoft doesn't seem to care.

[ConEmu](https://code.google.com/p/conemu-maximus5/) is here for you. If you want to know what it's all about, Scott Hanselman has [a blog on it](http://www.hanselman.com/blog/ConEmuTheWindowsTerminalConsolePromptWeveBeenWaitingFor.aspx) with the details.

That's not what this bog is about. This blog is about getting ConEmu setup with Git Bash on Windows, because for some reason that is a pain in the ass.

For starters I recommend installing it from Chocolatey, with this [package](https://chocolatey.org/packages/Devbox-ConEmu). After you have it installed, play around with it a bit. You can get to the settings by right-clicking the window bar (why this isn't on a [gear] icon is beyond me). If you want it to take over as the default command prompt, the option you want is under **Integration > Default Term**, its the first checkbox.

Now, to get the MySysGit Bash to open:

1. Go to **Startup > Tasks**
2. Hit the [+] Button to create a new task
3. Give it a name
4. Set the task parameters to
`/single /Dir "[YourStartupDir]" /icon "%ProgramFiles(x86)%\Git\etc\git.ico"`

5. Set the shell with the command
`%systemroot%\SysWOW64\cmd.exe /c ""%ProgramFiles(x86)%\Git\bin\sh.exe" --login -i" "-cur_console:t:Git Bash" `

This task can now open then git bash, which will include any tab-completion or branch prefixes you have set up. You can set your startup window to this task in **Startup** by selecting it on the 3rd radio.

I had to play around with the task parameters quite a bit to get it to behave the way I expected it to. I wanted it to open on startup, but I also wanted it to always open a new tab when the task was used with a **task hotkey**. The `/single` is supposed to do this on its own, but I had inconsistent luck when opening multiple tabs. The shell command's last parameter, the `cur_console` one worked, but only when combined with single. I honestly don't understand entirely how these two work in conjuction, so let me know if you do.
