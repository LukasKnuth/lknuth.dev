---
title: "Android targeting system"
date: 2012-08-02T15:48:26+01:00
---

I recently started supporting API Level 9 in my current project, which brought a problem with the ActionBar along. I had used it extensively in development (which was targeting post-Honeycomb devices), but it's only available on API Level 11 and later.

Long story short, I started using [ActionBarSherlock](http://actionbarsherlock.com/) to get the ActionBar working on all devices and discovered an interesting fact about the Android building system and it's targeting mechanism.

<!--more-->

## Targeting in Android

When compiling a Java application with a Java 7 compiler, you can't use it with a Java 6 interpreter. The interpreter will tell you, that it can't interpret the produced byte-code, even if you're not using any Java 7 language features. If you want to compile with the latest compiler but make your byte-code executable on older JVM versions, you'll need to tell the compiler to do so (using the `-target`-flag).

In Android, you can declare what platform-versions you support in your manifest-file, using the `<uses-sdk>`-element and it's `android:minSdkVersion` and `android:targetSdkVersion`-attributes. The difference between those "targeting mechanisms" is, that Android does not care against which platform version the application was compiled.

If you declare your application to be compatible with API Level 4, Android will happily install it, even if you compiled it against Android 4.1 (API Level 16).

### Pro

This allows your application to use new API calls on newer platform, but still fully support older Android versions. It is possible to check the Android version and decide what features to use at runtime (as described [further below](#conditional-execution)).

This way, you can make use of newer functionality on Android devices with higher API Levels and use available fallback functionality on devices with lower API Levels.

### Contra

But the big problem with this system is, that you **loose a huge amount of compile-time security.**

When declaring your `minSdkVersion`, you effectively *promise*, that your App will run on this version or higher. The thing with promises is, they're easy to break.

If you declare your minimum SDK version to be API Level 6 and you use methods/classes which where added in API Level 11, the compiler will not complain at *compile-time*. But your App will crash at *execution-time*.

This is, where the [Android Lint](http://tools.android.com/tips/lint) tool comes in handy.

## Android Lint

The tool website gives the following summary about it's functionality:

> Android Lint is a new tool introduced in ADT 16 (and Tools 16) which **scans Android project sources for *potential* bugs
> (which can *not* be found at compile-time)**. It is available both as a command line tool, as well as integrated with
> Eclipse, and IntelliJ. [...]

As mentioned above, when building against a newer version of the platform, there is no way for the compiler to know on what versions the application needs to run. This is something the Linter can check for you.

### IntelliJ problems

<div class="important">
    <p>This section is heavily outdated! It's retained only for cohesion.</p>
</div>

In the quote above, the IntelliJ integration is mentioned, although in it's current state (IntelliJ 11.1.3), it's not really worth mentioning.

The IntelliJ settings include just a few of the many many checks that the Linter can perform. My particular problem is, that the `NewApi`-check (which we'll further discuss in just a minute) is not included *at all*.

Also, when manually performing any Lint-checking on an IntelliJ project, there is a second problem.

#### Checking IntelliJ projects on the command line

When trying to use the CLI version of Lint, this happens:

    $ lint BikeTrack/
    Scanning BikeTrack: ....................
    BikeTrack: Error: No .class files were found in project "BikeTrack", so none of the classfile based checks could be run. Does the project need to be built first? [LintError]

The problem here is, that the Linter searches a particular folder for the classfiles (See [issue "IDEA-88701"](http://youtrack.jetbrains.com/issue/IDEA-88701)), which is `bin/classes` (the standard in Eclipse). The standard IntelliJ output folder is `out/production/MyProject`.

An easy workaround for this problem is to make a symlink from the IntelliJ output folder to the `bin/`-folder. Another option is to change the output-folder of IntelliJ under "File -> Project Structure -> Project -> Project Compiler Output".

### Checking for compatibility problems

The Linter can check for [many things](http://tools.android.com/tips/lint-checks). To speed the whole thing up, you can tell it which particular checks it shall perform on your project. For the sake of this article, the "NewApi" check is of the biggest interest:

> Summary: **Finds API accesses to APIs that are not supported in all targeted API versions**
>
> [...]
>
> This check scans through all the Android API calls in the application and **warns about any calls that are not
> available on *all* versions targeted by this application (according to its minimum SDK attribute in the manifest).**

To run this single check on your project, use the commandline tool:

    $ lint --check NewApi BikeTrack/
    Scanning BikeTrack: .......................................................................
    No issues found.

This time, the Linter did not find anything, but if it finds something, it gives you plenty of information:

    $ lint --check NewApi BikeTrack/
    Scanning BikeTrack: .......................................................................
    src/org/knuth/biketrack/Main.java:246: Error: Call requires API level 11 (current min is 9): android.widget.ArrayAdapter#addAll [NewApi]
                tour_adapter.addAll(tours);
                             ^
    1 errors, 0 warnings

You can see the source file, the line, the called method and the reason why it is not supported (and when it was introduced) in the given error. 

You'll want to run this check before deploying your application or after every major change. When using a CI, this should always be part of your build process.

## Using features of newer APIs

So, if you *unintentionally* used an API call which is not supported in every targeted platform, you'll receive an error from the Linter. But what if you want to *intentionally* use newer APIs when they're available on the device that is running the application?

### Conditional execution

Consider the following situation:

There are two ways to implement a feature: The first is new and shiny but requires an API Level higher then the `minSdkVersion`. The other is old and... well, not so shiny. Now, on a platform which has the needed API Level, you want to use the new and shiny way, while on older devices, you want to fall back on the "not-so-shiny" variation. But how do you check if the needed APIs are available at runtime?

For that purpose, there is the `android.os.Build.VERSION`-class and it's [`SDK_INT`-field](http://developer.android.com/reference/android/os/Build.VERSION.html#SDK_INT). To check if a device is running (for example) Honeycomb or later, you can use this code:

```java
if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.HONEYCOMB) {
    // call something for API Level 11+
} else {
    // use something available before
}
```

The above code and the topic itself is further discussed in this [SO question](http://stackoverflow.com/q/9959990/717341).

### Declaring intentional usage of new APIs

So, now you can check if an API is available and if so, use it. However, the Linter does not understand this check and will complain. To fix this, we'll need to ensure the Linter that we understand the possible error scenario but have taken the necessary precautions:

> If your code is *deliberately* accessing newer APIs, and **you have ensured (e.g. with conditional execution) that this
> code will only ever be called on a supported platform, then you can annotate your class or method with the** `@TargetApi`
> **annotation** specifying the local minimum SDK to apply, such as `@TargetApi(11)`, such that this check considers 11
> rather than your manifest file's minimum SDK as the required API level.

So now, you'll want to move all your post-Honeycomb code into a method and annotate it:

```java
if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.HONEYCOMB) {
    doHoneycombStuff();
}

// ... Further down

@TargetApi(11)
private void doHoneycombStuff(){
    // Use API Level 11 functionality here...
}
```

After that, the Linter won't complain about your code in the `doHoneycombStuff()`-method and the running Android device will execute the code, depending on it's current platform.

An example on how I used this to get contextual menus to work with the native ActionBar (on post-Honeycomb) or the classic context-menu can be found in this commit: [BikeTrack - 3b60c31d85](https://github.com/LukasKnuth/bike-track/commit/3b60c31d85c2f9f45dbd70be30ada944a85dc5a8#diff-3)

## Conclusion

* If you want your application to work with the newest Android platform, build against it.
* Use `minSdkVersion` to declare the *lowest* API Level which is supported by your application.
* As your `targetSdkVersion`, use the API Level against which you compiled the application.
* Use Lint to check for (possibly) unsupported API calls.
* Use conditional execution and the `@TargetApi`-annotation to use newer APIs when available.
