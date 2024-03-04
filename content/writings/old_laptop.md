---
title: "Old Laptop"
date: 2024-03-04T15:45:25+01:00
draft: true
---

For out upcoming vacation I was looking for something to write a few articles on.
I didn't want to bring my fancy MacBook from work on a personal trip though.
So I found my old Laptop from when I was a University student and thought "I can make that work".

## The Hardware

I first bought this Lenovo IdeaPad U330p about 10 years ago on a student budget.
It has an Intel i5-4210U with a whooping 1.7GHz (boost up to 2.7GHz) with two cores (each with two threads).
The chip has a Intel HD Graphics 4400 on board as well.
It sports 4GB of RAM and a 256GB SSD.
The built-in Intel Wireless 7260 chip does 2.4 and 5 GHz WiFi up to the 802.11ac standard.

Back in the day, this was a good, middle-of-the-road laptop that a student could afford.
I payed 600€ for it.
Today, it's a relic that was sitting in a corner of my apartment for the last seven years.
Until a few days ago when I dusted it off and installed a fresh system.

## Problems

First off, the battery is entirely dead and the device won't run without a constant power connection.
Unplug it for even a moment and everything goes dark.
Not great, not terrible.

So I booted it up the the installed Windows 10 OS and... it took a good while.
Once I was in the system though... everything was still really slow.
This wasn't going to do at all.

## The joys of running an old laptop

I installed the current version of NixOS x86_64 on the device and got to configuring.

I always wanted to make system entirely running on Wayland.
It's a more modern replacement for the X11 window server that promises fewer moving parts.
Seems like a good fit for my low spec device.

I like to use keyboard shortcuts to place/move windows anyways, so I went for Sway as my Wayland Composer.
It's an i3 compatible tiling window manager which has a very small footprint and only does whats required.

Another upside of NixOS and components like these is that they allow you to configure them simply by writing plain text config files.
This eliminates the need to write UI tools to do the same.
I configured Sway with a simple config in my Home directory and got things to work well in a few hours.

In addition to Sway, I installed and customized Waybar to display more information in the bar at the top of my screen.
I also customized it's CSS somewhat to make everything look a _little_ more modern.

Lastly, I added tuigreet to make logging into the system a bit nicer.

To create actual content with this system, I simply setup git, vim and hugo.
Thats enough to write Blog posts and preview them.

## Configuration

As mentioned above, the components I chose are meant to be minimalistic and incur a low footprint.
This does mean that I have to do certain things in a Terminal instead of a UI.

For example, to connect to a WiFi AP I use the `nmcli` utility for NetworkManager:

```bash
$ nmcli device wifi rescan
$ nmcli device wifi list
# Pick your network
$ nmcli device wifi connect "<SSID>" password "<PSK>"
```

This is only marginally less convenient than using a UI.
I also don't have a file explorer on my system yet.
I simply don't have a usecase for it at the moment.
Once I do, I'd probably go looking for a good CLI file commander though.

## NixOS

I really enjoy setting things up with NixOS.
I write a single declarative configuration file, run a single command and then my new system is ready.

While setting up tuigreet, I missconfiured it slightly.
As a result, I couldn't boot to my default target anymore.
I simply selected the previous generation from the GRUB menu and my system was exactly like before I changed the configuration.

I haven't spent too much time making my configuration modular yet.
My entire system is a single 192 lines configuration file.
Thats still very managable.

I have avoided using HomeManager because I feel it adds too much complexity that I currently don't need.
Instead, I have started to manage my dotfiles and made them resuable even on my MacOS system.
This is a less Nix specific solution, but I like the portability it offers better.

## Fully encrypted

Since it's a laptop and I'm taking it on-tour with me, I setup full device encryption.
This was easy following [@ladinu's Guide](https://gist.github.com/ladinu/bfebdd90a5afd45dec811296016b2a3f) to get everything setup.
Now, the system prompts for the password right after boot.

While this setup probably isn't good enough to protect against governments and three letter agencies.
It is however good enough to protect against most people and even advanced nerds.
That covers my attack vector quite well.

## Closing thoughts

I now have a very nice, productive system that I can use to develop things or write on the go.
I didn't have to buy any new hardware which is good for the planet and my wallet.
Had I not found this new purpose for the device, I would have probably thrown it away sooner or later.
And that would have been a shame.

Aside from the battery, everything on this device still works and works quite well.
Once we're back from vacation, I'll buy a fresh battery and remove my single hardware gripe.

With this new system and it's lower resource footprint (compared to a basic Windows install), the device is snappy again.
I hand-picked most software for it's efficiency and low resource consumption.
The side-effect is that I ended up with a system that is really bloat free.

