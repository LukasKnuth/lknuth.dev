---
title: "UDP Multicast on Android"
date: 2012-09-04T15:51:15+01:00
---

I started working on a small inventory system, that keeps track of all the things I buy. To enter new items quickly into the system, I needed a barcode-scanner to scan new articles, transfer them to my computer and allow me to (for example) paste them into a focused input-field.

I wrote a small Android application, that uses [zxing](https://github.com/zxing/zxing) to scan the barcodes and a simple multicasted UDP network connection to broadcast the contents of the code to all listening network devices. This way, I don't need to enter any IP addresses or host-names in the app to reach the listening server application on my computer. The `MulticastSocket` of the java standard library seemed perfect for this purpose.

<!--more-->

## When Android interferes

After the application was created, I tried it out, just to realize that... well, nothing happened. After some research on the internet, I found out that Android itself was the source of the problem:

> public class [**WifiManager.MulticastLock**](http://developer.android.com/reference/android/net/wifi/WifiManager.MulticastLock.html)
>
> **Allows an application to *receive* Wifi Multicast packets. Normally the Wifi stack filters out packets not explicitly
> addressed to this device. Acquring a MulticastLock will cause the stack to receive packets addressed to multicast
> addresses.** Processing these extra packets can cause a noticable battery drain and should be disabled when not needed.

Even though the documentation only talks about *receiving* multicast packages, the same applies for *sending* them: You need to obtain the `MulticastLock` in order to work with multicast packages.

### Acquiring a lock

Actually getting the required lock isn't that much trouble at all. Declared the following permissions in your manifest:

```xml
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
```

Then use the `WifiManager` to acquire the lock:

```java
WifiManager wifi = (WifiManager)getSystemService( Context.WIFI_SERVICE );
if(wifi != null){
    WifiManager.MulticastLock lock = wifi.createMulticastLock("Log_Tag");
    lock.acquire();
}
```

The multicast-lock is [acquired until](http://developer.android.com/reference/android/net/wifi/WifiManager.MulticastLock.html#acquire%28%29):

> Locks Wifi Multicast on **until `release()` is called.**
> [...]
> When an **app exits or crashes**, any Multicast locks will [also] be released.

Sending/receiving should work now. Unless...

## Device problems

... you run into the situation where you have a device that just *can't do it*.

Reading multiple topics, blog-posts and bug-reports, it turns out that some devices don't (or don't fully) support multicast. Whether they do or don't depends on both the vendor (because they build/optimize the kernel) and the Android version.

To quote from an [Issue regarding Android 1.5 - 2.1](http://code.google.com/p/android/issues/detail?id=2917#c48)

> I've spent quite a bit of time debugging mDNS issues with JmDNS on my Evo and HTC Hero (CDMA). What I found is **there
> appears to be a filter in place in the broadcom wireless driver on the Evo** (and since I'm getting a similar report
> from an HTC Desire user - with the same chipset, presumably that handset as well). **The filter, by default, blocks any
> non-unicast or network broadcast traffic, including multicast.** Apparently the theory was it's a battery saver.
> <br><br>
> **The problem appears to be the `wpa_supplicant` on the Evo does *not* support removing those filters when you get a
> MulticastLock.** (Check the log output right after you get the lock and you'll see what I mean). Unfortunately what
> has happened is the hardware vendors have fragmented multicast support.... :(

It has been reported that switching the `/system/bin/wpa_supplicant`-binary to a newer version has fixed the issue for those devices, but this comes with two big downsides:

1. The phone needs to be rooted
2. You can't rely on your users to provide a working environment for your application

If you're curious, the Issue with the suggested workaround can be found here: [Android Issue #8407](http://code.google.com/p/android/issues/detail?id=8407)

Another possible cause might be a problem with the implementation of IGMP on those devices, as suggested in Isaac Taylor's blog-post: [Multicast and Android – A Big Headache ](http://www.programmingmobile.com/2012/01/multicast-and-android-big-headache.html)

### Check if it works

Well, if it's broken on *some* devices, there should be a way to tell if it isn't working on the current one, or is there? The answer here is **no**.

There seems to be no reliable way of telling if multicast works on the current device. Some devices give error-messages in their log-cat output, some simply fail silently (like my HTC Desire HD).

What makes determining a working environment even harder is, that the problem results from multiple sources. It might be the lower-level network implementation, the kernels network drivers or the IGMP implementation. And there is currently no reliable way of testing for all those cases.

The same code that fails on my HTC Desire HD (Android 2.3.5) works fine on my Motorola Xoom (Android 4.0.4).

## Conclusion

* Try avoiding multicast in deployed applications for end-users or provide alternatives (direct communication still works fine).
* Acquire the `MulticastLock` so the system does not ignore the packages send/received
* If you're having problems, check the network-traffic with tools like [WireShark](http://www.wireshark.org/) or [tcpdump](http://www.tcpdump.org/).
