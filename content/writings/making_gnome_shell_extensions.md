---
title: "Making GNOME Shell Extensions"
date: 2013-02-09T15:57:38+01:00
summary: |
  Getting into GNOME Shell extension development is hard and involves a lot of source-code reading.

  This post collects resources that helped me get into it as well as general advice. It aims to be a jump-off point, rather than a guide.
---

I like the GNOME Shell and I've liked it since it was in the "testing"-repo of ArchLinux. It's a fast and aesthetic desktop environment. But it's a long way from offering everything you'd like to have. Luckily, it can be extended.

> [!caution]
> The following advice, instructions or sources where compiled when **GNOME Shell 3.6.2** was the latest version.
> While specific information here might be outdated, the general idea still holds value today.

**Note that this is not a real step-by-step guide** on how to create your first extension. There are many of those out there and I would just repeat them. Instead, this is more like an advice-collection on different aspects of creating extensions. So, **be sure to check the links**.

## Basics

Getting into the development of GNOME Shell Extensions is a little hard. The documentation is mostly not available or outdated.

Here are some sources which helped me to get started (and through development):

* [**Basic stuff on extensions**](https://live.gnome.org/GnomeShell/Extensions)
* [Basic stuff on development](https://live.gnome.org/GnomeShell/Development)
* [Step-by-step tutorial](https://live.gnome.org/GnomeShell/Extensions/StepByStepTutorial)
* [**Inofficial documentation for the JavaScript bindings of many libraries**](https://www.roojs.com/seed/gir-1.2-gtk-3.0/gjs/index.html)
* [**Official (but partial) documentation for JavaScript bindings**](https://gjs-docs.gnome.org/)
* [Some inofficial guidelines to get your extension on extensions.gnome.org](https://blog.mecheye.net/2012/02/requirements-and-tips-for-getting-your-gnome-shell-extension-approved/)

Be sure to defiantly check out the bold links in the list.

## Getting stuff done

Above all, if you're serious about creating your extension: [**Learn to read the source, Luke**](https://www.codinghorror.com/blog/2012/04/learn-to-read-the-source-luke.html).

When trying to get actual work done on your extension, try consulting the docs (if existing) or search the [extension repos](https://extensions.gnome.org) for extensions which do similar things to what you want to do, and **look at their sources**. Most of them are hosted on GitHub or Bitbucket, but you can also install them and find the sources under `~/.local/share/gnome-shell/extensions/<extension-UUID>/`.

When searching for a specific function, or more documentation on a particular function, you can also consult manuals for bindings in different languages (thought the parameters and return-values might not match exactly).

### Making user interfaces

To get a native look-and-feel with the Shell, extensions can use St (= Shell Toolkit) to create UIs for everything that integrates with the Shell itself, and Gtk for the extension-preferences.

_Some_ Documentation is now available over at [the Gnome Docs](https://gjs-docs.gnome.org/st10~1.0_api/). It is however just a reference, which makes it hard to discover functionality. For some guidance, check out this (**older**) [explanation of the St components](https://mathematicalcoffee.blogspot.de/2012/09/gnome-shell-javascript-source.html). Reading **a lot of source-code** is still required. See the [GNOME Shell Sources](https://git.gnome.org/browse/gnome-shell/tree/js).

Documentation on Gtk's JavaScript binding (which you'll use for the extension-preferences) can be found in the [in-official library docs](http://www.roojs.com/seed/gir-1.2-gtk-3.0/gjs/Gtk.html).

## Debugging

**LookingGlass is not particularly helpful.** It only shows one line of an exception (the description) and only if they occur at startup time (when your extension is first started).

Instead, for full StackTraces and runtime-exceptions, **consult the session-logfile**. It might be very long and bloated, so I use this [handy script](https://bitbucket.org/LukasKnuth/backslide/src/561b1dbe542a/session-error.sh) to read it:

```bash
# Grabs the last session-errors from the current X11 session.
# This includes full Stack-Trace of gnome-shell-extension errors.
# See https://live.gnome.org/GnomeShell/Extensions/StepByStepTutorial#lookingGlass
tail -n100 ~/.cache/gdm/session.log | less
```

**Should your extension crash the whole Shell**, the `session.log`-file will not contain information on it, because when the shell restarts, a new log-file is created. Go get information on what crashed the shell, check the `~/.cache/gdm/session.log.old`-file.

For **debugging the prefs-part** of your extension, you can launch the preferences by using the `gnome-shell-extension-prefs`-tool from a terminal. Any exceptions will be output to the console. Additionally, you can also call the tool like `gnome-shell-extension-prefs [uuid]` to directly show your extensions preferences.

Since there is currently no real way of debugging with breakpoints (there is, but [it's tricky](https://live.gnome.org/GnomeShell/Debugging)), you can **log to the console**, using the `print()`-function. You will see the output as mentioned above (either in the session-logfile or on the terminal when starting `gnome-shell-extension-prefs`-tool).

## The future

At the "GNOME Developer Experience Hackfest" in Februrary 2013, JavaScript was chosen to be the "officially supported language" for creating applications for GNOME:

> **JavaScript**
>
> Practically any high-level, garbage-collected language is much better than plain C,
> in terms of productivity, once you get used to the idiosyncrasies of the bindings
> to the Gnome libraries.
>
> So, **I'm very happy that we have a high-level language [JavaScript] accepted as
> officially supported for Gnome.** I was kind of surprised that Python, our de-facto
> and historically "best supported binding" wasn't chosen, but if **this means that
> another high-level language can get as much work put into it**, then all the better.
>
> [(Source)](https://people.gnome.org/~federico/news-2013-02.html#dx-hackfest)

So, there is hope that the API documentation will improve very soon.

## Conclusion

* Above all: **Read the sources!**
* Check out other extension's sources and learn from them.
* Don't get frustrated by the documentation. Read sources instead.
* You can ask specific questions on [StackOverflow [gnome-shell-extensions]](https://stackoverflow.com/questions/tagged/gnome-shell-extensions)

Although it might be a little hard to get into it, the extension framework is quite powerful. Have **fun**!
