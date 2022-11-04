---
title: "Tts and Usability"
date: 2014-06-13T16:02:43+01:00
description: An introduction to TTS on Android
draft: true
---

Belief it or not but there are actual use-cases for a Text to Speech engine in an application, other than just trying it out and never use it again or for annoying people with it.

An example for such a case is an application that has focus and is currently running, but doesn't require physical contact with the device. These applications still need to update the user, but shouldn't require physical contact to do so. An example of such an application is a Navigation-app or my own [BikeTrack](https://github.com/LukasKnuth/bike-track).

## Making Android talk

Android exposes it's Text to Speech abilities via the `TextToSpeech`-class since API Level 4 (Android 1.6), so it should be available on all devices.

```java
TextToSpeech tts = new TextToSpeech(context, new TextToSpeech.OnInitListener() {
    @Override
    public void onInit(int status) {
        if (status == TextToSpeech.SUCCESS){
            // Start talking...
        } else if (status == TextToSpeech.ERROR) {
            // Couldn't initialize TTS service
        }
    }
});
```

This example is straightforward enough, except for the `OnInitListener`-part: Starting the TTS service and connecting to it might take some time. Therefore, we need some sort of callback to tell us when initialisation is done.

What that means for our code is, that the following won't work:

```java
TextToSpeech tts = new TextToSpeech(context, new TextToSpeech.OnInitListener() {...});
int result = tts.speak("Testing", ...);
```

If `speak()` is called directly after the constructor returns, the service might not be started, so we're not able to speak yet.

### The silence before the initialisation

If we consult the Android Documentation on the [`speak()`-method](http://developer.android.com/reference/android/speech/tts/TextToSpeech.html#speak%28java.lang.String,%20int,%20java.util.HashMap%3Cjava.lang.String,%20java.lang.String%3E%29), it tells us that:

> [...] This method is asynchronous, i.e. **the method just adds the request to the queue of TTS requests and then returns**. The synthesis might not have finished (or even started!) at the time when this method returns.
>
>
> Returns: [`ERROR`](http://developer.android.com/reference/android/speech/tts/TextToSpeech.html#ERROR) or [`SUCCESS`](http://developer.android.com/reference/android/speech/tts/TextToSpeech.html#SUCCESS) **of <u>queuing</u> the speak operation**.

So we told the TTS service to *queue* this speak operation, but if the service is not yet initialized, it won't do so! If we check the return value, we'll see that queueing failed.

So, adding speak-operations to the TTS before it's done won't actually just wait until it's initialized and then process them, **they'll be discarded** instead.

### When initialisation fails

The biggest problem with Androids Documentation on Text to Speech is, that it's not really clear under which circumstances initialisation will fail, or what will happen if we try to use it, even if initialisation failed.

By looking at the code, these are the information I could gather on this topic:

* [Older versions](http://grepcode.com/file/repository.grepcode.com/java/ext/com.google.android/android/2.3.2_r1/android/speech/tts/TextToSpeech.java#TextToSpeech.initTts%28%29) (API Levels 4 (Android 1.6) to 9 (Android 2.3.2)) don't ever return `FAILED`. They simply don't handle the failure.
* On newer versions (since API Level 14 (Android 4.0.1)) it's a little more complicated:
  1. First, try the supplied engine (supplying an engine to use is optional)...
  2. then, try the default engine (returned by `getDefaultEngine()`) as a fallback (This can be deactivated since API Level 16 (Android 4.1.1))...
  3. lastly, try the engine with the "highest ranking", which will [*currently*](http://grepcode.com/file/repository.grepcode.com/java/ext/com.google.android/android/4.4.2_r1/android/speech/tts/TtsEngines.java#TtsEngines.getHighestRankedEngineName%28%29) just fall back to the first engine, if it shipped with the system.

In general: When `bindService()` returned `false` (that is, if we couldn't bind to the engine service) for all considered engines, a device with API Level 10 (Android 2.3.3) or higher will give you an `ERROR`-status.

That said, no implementation of `TextToSpeech` will throw exceptions or errors if you call `speak()` or `synthesizeToFile()` on them, when they're not completely initialized or failed to initialize. They'll fail gracefully and Log the error to LogCat.

## Talk to me

When the Service is successfully (and completely) initialized, meaning the `OnInitListener.onInit(status)`-method has been called with `SUCCESS` as the status, the service is ready and can be used.

Making the engine speak is pretty straight forward, so reading either the documentation on [`speak(String, int, HashMap)`](http://developer.android.com/reference/android/speech/tts/TextToSpeech.html#speak%28java.lang.String,%20int,%20java.util.HashMap%3Cjava.lang.String,%20java.lang.String%3E%29) or [`synthesizeToFile(String, int, HashMap)`](http://developer.android.com/reference/android/speech/tts/TextToSpeech.html#synthesizeToFile%28java.lang.String,%20java.util.HashMap%3Cjava.lang.String,%20java.lang.String%3E,%20java.lang.String%29) will get you there.

Instead, let us talk about *when* to speak and when to just shut up.

### Silence is golden. *Sometimes*

"Don't annoy the user" is a good principal in general, but with Text to Speech it's even more important. Here are a few general rules:

* Allow users to deactivate TTS completely.
* If you find yourself adding a lot of spoken updates to your application, try grouping all of them into levels of verbosity and let the user choose a level.
* Be adaptive to the current situation...
* Keep spoken messages short

As a general advice, take into consideration that you can not just quickly skim a spoken update or just stop reading once you have the relevant information, like you can with text. Also, you can't highlight things when speaking (at least not as clearly as with text), so **keep the messages short and to the point**.

### Talking, the adaptive way

By default, when you call the `speak()`-method, the text will be spoken on the same stream that most applications use for playback (for example games or the music player). Therefore, if the user is playing music on his device, TTS will just "talk over it", making it hard to understand the spoken text.

In his excellent presentation ["Android Protips"](http://youtu.be/twmuBbC_oB8) from Google I/O 2011, Reto Meier talks about making applications "adaptive" (the part relevant to TTS starts at around [45:00](http://youtu.be/twmuBbC_oB8?t=45m)): By requesting audio focus for a short time (in which we'll speak via TTS), we can pause everything that's on the stream or lower the streams volume (called "ducking"), so that the user can hear what's being said.

Here is a short example that *asks* the apps currently using the music stream to duck for a short while, so we can talk to the user:

```java
// -- Setup (just need to do this once) --
// Get access to the AudioManager:
AudioManager am = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
AudioManager.OnAudioFocusChangeListener afl = new AudioManager.OnAudioFocusChangeListener() {
    @Override
    public void onAudioFocusChange(int focusChange) {
        // Specify how YOUR app will handle audio-focus loss (optional)
    }
};
// We need to abandon the audio-focus as soon as we're done talking:
tts.setOnUtteranceCompletedListener(new TextToSpeech.OnUtteranceCompletedListener() {
    @Override
    public void onUtteranceCompleted(String s) {
        am.abandonAudioFocus(afl);
    }
});

// ...

// Ask others to lower their volume for a short time, while we're talking:
int focus_res = am.requestAudioFocus(
        afl, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
);
// Talk:
if (focus_res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED){
    tts.speak(text, TextToSpeech.QUEUE_ADD, this.tts_params);
}
```

Now, when we want to talk to the user, no other (if any) currently playing applications should interfere. Depending on how important our message is, we can change the way we want the `AudioManager` to behave:

* Use [`AUDIOFOCUS_GAIN`](http://developer.android.com/reference/android/media/AudioManager.html#AUDIOFOCUS_GAIN) if we request focus (will pause other applications) for an unspecific period of time (but not short).
* Use [`AUDIOFOCUS_GAIN_TRANSIENT`](http://developer.android.com/reference/android/media/AudioManager.html#AUDIOFOCUS_GAIN_TRANSIENT) to pause other applications for a short period of time, or
* use [`AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`](http://developer.android.com/reference/android/media/AudioManager.html#AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK) if it's something short and other applications may lower their volume for that period (this might indicate, that this message is not *critically* important).

**NOTE**: By requesting the audio focus we *ask* other applications to pause/lower their volume, **they have no obligations to do so**. For example, requesting transient focus with ducking might work as expected for one media player ("Google Play Music" for example) but differently for another (the HTC standard music player just pauses for the time).

We can set this behavior for our own application by reacting to audio-focus changes in the `OnAudioFocusChangeListener` (as shown in the presentation).

A decent, but not complete example of a wrapper that handles all these things can be found [here](https://gist.github.com/LukasKnuth/0c0d17b343483d25aca2).

## Cleaning up

It's important to call [`shutdown()`](http://developer.android.com/reference/android/speech/tts/TextToSpeech.html#shutdown%28%29) on the `TextToSpeech` object, once you're done with it!

> Releases the resources used by the TextToSpeech engine. **It is good practice for instance to call this method in the onDestroy() method of an Activity** so the TextToSpeech engine can be cleanly stopped.

If you fail to do so, the application will leak resources and a `ServiceConnectionLeaked` error will appear in the LogCat.

## Conclusion

* You'll need to wait for the call to `onInit()` with a status of `SUCCESS`, until you can start talking
* It's easy to annoy users with TTS. Give them options to reduce the verbosity or to deactivate it completely and **keep spoken messages short and to the point**
* Make your application adaptive by requesting audio-focus before talking
* Remember to shut down the TTS service, once you're done