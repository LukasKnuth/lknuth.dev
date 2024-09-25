---
title: "More with less"
date: 2024-03-04T15:45:25+01:00
draft: true
---

For our upcoming vacation I was looking for something to write a few articles on.
I didn't want to bring my fancy MacBook from work on a personal trip though.
I did find my old Laptop from when I was a University student; "I can make that work".

## The Hardware

I first bought this Lenovo IdeaPad U330p about 10 years ago on a student budget.
It has an Intel i5-4210U with a whooping 1.7GHz (boost up to 2.7GHz) with two cores (two threads each).
The chip has an Intel HD Graphics 4400 on board as well.
It sports 4GB of RAM and a 256GB SSD.
The built-in Intel Wireless 7260 chip does 2.4 and 5 GHz WiFi up to the 802.11ac standard.

Back in the day, this was a good, middle-of-the-road laptop that a student could afford.
I paid 600€ for it.

## Problems

The battery is entirely dead and the device won't do anything without a wired power supply.
Unplug it for even a second and everything goes dark.
Not great, not terrible.

So I booted it up the installed Windows 10 OS and... waited. A while.
Once I was in the system though... everything was still really slow.
This wasn't going to do at all.

## The joys of running an old laptop

I installed the current version of NixOS x86_64 on the device and got to configuring.

I like to use keyboard shortcuts to place/move windows, so I went for Sway as my Wayland Composer.
It's an i3 compatible tiling window manager which has a very small footprint.
It does what I need and not much more.

I picked Wayland over X11 because I wanted to be as light on my resources as possible.
Also, I was curious how production ready the system is nowadays.

In addition to Sway, I installed and customized Waybar to add some important info to the menubar.
I also customized its CSS somewhat to make everything look a _little_ more modern.

Lastly, I added tuigreet to make logging into the system a bit nicer.

To create actual content with this system, I simply set up git, helix and hugo.
That's enough to write Blog posts and preview them.

## Back to the terminal

The components I chose are meant to be minimalistic and incur a low resource footprint.
This does mean that I have to do certain things in a Terminal instead of a UI.

For example, to connect to a WiFi AP I use the `nmcli` utility for NetworkManager:

```bash
$ nmcli device wifi rescan
$ nmcli device wifi list
# Pick your network
$ nmcli device wifi connect "<SSID>" password "<PSK>"
```

This is only marginally less convenient than using a UI.
I use ranger instead of a visual file-manager.
Its small, fast an has sane keyboard shortcuts.

In general, I could probably get about 90% of the way just by using the terminal.
The Browser is really the only component that makes a desktop environment event required.

## NixOS

I really enjoy setting things up with NixOS.
I write a single declarative configuration file, run a single command and then my new system is ready.

While setting up tuigreet, I misconfigured it slightly.
As a result, I couldn't boot to my default target anymore.
I simply selected the previous generation from the GRUB menu and my system was exactly like before I changed the configuration.

I haven't spent too much time making my configuration modular yet.
My entire system is a single 192 line configuration file.
That's still very manageable.

## Configuration

I have avoided using HomeManager because I feel it adds too much complexity that I currently don't need.
Instead, I used this opportunity and moved most of my system configuration into a new [dotfiles repository](https://github.com/LukasKnuth/dotfiles).

This is a less Nix specific solution, but I like this unopinionated solution better.
It's portable and works on both my macOS and Linux systems.

I picked GNU stow to manage the symlinks for me and added the config from my existing system.
This allowed me to also look at my current config and clean it up.

## Fully encrypted

Since it's a laptop and I'm taking it on-tour with me, I set up full device encryption.
This was easy following [@ladinu's Guide](https://gist.github.com/ladinu/bfebdd90a5afd45dec811296016b2a3f) to get everything setup.
Now, the system prompts for the password right after boot.

This setup probably isn't good enough to protect against governments and three letter agencies.
It is however good enough to protect against most people and even advanced nerds.
That covers my attack vector.

## Closing thoughts

I now have a very nice, productive system that I can use to develop things or write.
I didn't have to buy any new hardware which is good for the planet and my wallet.
Had I not found this new purpose for the device, I would have probably thrown it away.
And that would have been a shame.

Aside from the battery, everything on this device still works and quite well.
Once we're back from vacation, I'll buy a fresh battery and remove my single hardware gripe.

With this new system and it's lower resource footprint (compared to a basic Windows install), the device is snappy again.
I hand-picked most software for exactly this reason.
The side effect is that I have really bloat free system.

I found a special joy in doing more with less.

