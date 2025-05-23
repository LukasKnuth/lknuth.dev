---
title: "Java in the Browser"
date: 2025-03-31T18:40:09+02:00
---

Like most aspiring software engineers, I wanted to program games.
Back in 2012 I had been learning to program for two years.
I was basically a senior developer.
Java was the only programming language that I knew.
And because I fancied myself a capable engineer, I wanted to build the game engine myself, from scratch.

So I stole somebody else's game - I read through the (excellent) [PAC-MAN Dossier](https://pacman.holenet.info/).
The document has _everything_ you need to build your own version of the game.
It details the basic game rules, the point system and how the ghost AI works.
And it's also not too technical, so you get to make the interesting decisions for yourself.

It took me about two months to get the game into a state that I was satisfied with.
And then I left it alone for 13 years.
Until I found the repository again a few weeks ago.

<!--more-->

Sadly, the barrier to play the game is just too high - there wasn't even a build script.
And, any interested players would have to install Java on their machines.
Ideally, I can make my old Java game run in the browser, while preserving its charm/jank.
No fixing of bugs, no adding of features or polishing mechanics.
That wouldn't be in the spirit of the project - a **digital exhibit**.

## Java in the Browser

My first idea was to compile it to WASM.
Surely these days every programming language compiles to WASM, right?
There is actually a project, [JWebAssembly](https://github.com/i-net-software/JWebAssembly), that does this.
However, their repository didn't have a commit in the last two years - which either means it's completed or abandoned.

Next I found [CheerpJ](https://cheerpj.com/).
As far as I can tell, this is a full re-implementation of the entire JDK in Web Assembly.
It's a drop-in solution, just take your old `.jar` files and some JavaScript boilerplate, and you're done.
The applications run without modification.
Boring.

The last project I found was [TeaVM](https://teavm.org/).
It is an ahead-of-time compiler for Java that can generate Web Assembly or JavaScript.
The project brings everything you need but does require you to adapt code to work with it.
Perfect.

## Support multiple platforms

The game uses Java Swing to render itself to a desktop window.
It also uses some AWT classes (the older Java Desktop toolkit that Swing builds on top of).
None of which are [available in TeaVM](https://teavm.org/jcl-report/recent/jcl.html).
The plan is as follows then:

1. Find any `javax.swing.*` or `java.awt.*` references in the code
2. Create interfaces to abstract the functionality 
3. Implement the interfaces for Desktop with the original `javax.swing.*` and `java.awt.*` classes
4. Implement the interfaces for Web with the [TeaVM JSO APIs](https://javadoc.io/doc/org.teavm/teavm-jso-apis/latest/index.html)
5. Profit

I created a basic Gradle project layout: a `game` project with the game logic and all my interfaces.
A second `desktop` project that depends on `game` where all the desktop specific code will be moved to.
Then, a new `web` project (also depends on `game`) which will have the web specific code built with TeaVM.

### Rendering and Resource Loading

Because I didn't want to spend too much time on chores, I decided to make the abstraction as thin as possible.
For most things, that meant literally copy-and-pasting the Swing/AWT calls out of the codebase and creating a function in the interface with the same name and parameter signature.

To render the game for example, I ended up with the following minimum set of draw calls:

```java
/**
 * A canvas to draw things onto. The actual drawing logic is implemented for each
 * supported platform in their respective project.
 */
public interface Canvas {
  public void setColor(Color color);
  public void setFont(Font font);
  public void drawString(String text, int x, int y);
  public void drawImage(ImageResource resource, int x, int y);
  public void drawImage(ImageResource resource, int x, int y, int width, int height);
  public void fillOval(int x, int y, int width, int height);
  public void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle);
  public void drawRect(int x, int y, int width, int height);
  public void fillRect(int x, int y, int width, int height);
  public void setStrokeWidth(float width);
  public float getStrokeWidth();
}
```

For any AWT specific classes, such as `Color` and `Font`, I made my own (much simpler) versions in the `game` project.
The abstract `Canvas` expects my versions and the platform specific implementations are expected to convert between the types.
The rest of the **Desktop** implementation is just forwarding calls:

```java
private final Graphics graphics;

public void drawString(String text, int x, int y) {
  this.graphics.drawString(text, x, y);
}

public void setColor(Color color) {
	this.graphics.setColor(new java.awt.Color(color.r, color.g, color.b));
}

public void drawImage(ImageResource resource, int x, int y) {
	this.graphics.drawImage(this.resourceCache.get(resource), x, y, null);
}
// ...
```

I also decided to solve **resource loading** in each specific platform.
For the desktop, I can simply load images/sounds from the folders/jar file.
But later, on the web, a different strategy will be required.

I removed any resource loading from the game and instead replaced it with a simple Enumeration:

```java
/**
 * A collection of all known graphical resouces used in the game.
 * Can be passed to {@code Renderer} to render on-screen.
 */
public enum ImageResource {
  MAZE("/graphics/maze.png"),
  CHERRY("/graphics/cherry.png"),

  INKY_DOWN_1("/graphics/inky/inky_down_1.png"),
  INKY_DOWN_2("/graphics/inky/inky_down_2.png"),
  // many, many more...

  public final String resource_path;
  private ImageResource(String resource_path) {
    this.resource_path = resource_path;
  }
}
```

Each enum constant has the path to its resource hard coded.
The platform specific `Canvas` implementation is then expected to load these files.
The desktop platform does this by iterating all constants and using a classpath loader:

```java
private final Map<ImageResource, Image> resourceCache;

private void preloadCache() {
	for (ImageResource resource : ImageResource.values()) {
		Image image = ClasspathResourceLoader.loadImage(resource);
		this.resourceCache.put(resource, image);
	}
}
```

I did the same for the sound system and its resources as well.
Now most of the game code is using the abstractions, except...

### Game Loop

The original game used Java Executors to spawn a thread that re-evaluated the game every 16ms.
Under ideal circumstances, that means the game simulates and renders at a stable 60 FPS.
However, Executors are also not available in TeaVM.

Rather than throwing interfaces at the problem again, I decided the _loop_ part of "Game Loop" was a platform specific issue.
This turned out to be a very good call later.
I moved most of the games initialization code from the `main()`-method to a new `Bootstrap` class in the game project, to be reused by each platform.

I then refactored the `GameLoop` class to expose a simple `step`-method that would simulate and render _one frame_ of the game.
All the platform has to do is setup the game loop and canvas, then call `step` repeatedly:

```java
private Runnable game_loop = new Runnable() {
  public void run() {
    Graphics off_screen_buffer = double_buffer.getDrawGraphics();
    JoystickState input = getJoystickState();

    GameLoop.INSTANCE.step(input, new SwingCanvas(off_screen_buffer));

    off_screen_buffer.dispose();
    double_buffer.show();
  }
};

private void startLoop() {
  Bootstrap.bootstrap(getWidth(), getHeight());
  GameLoop.INSTANCE.lock();
  // Execute the Runnable
  game_loop_executor = Executors.newSingleThreadScheduledExecutor();
  game_loop_handler = game_loop_executor.scheduleAtFixedRate(
    game_loop, 0L, 16L, TimeUnit.MILLISECONDS
  );
}
```

The code above also shows another platform-specific concern: The double buffer.
This is a technique to reduce flickering by painting the next frame to an off-screen buffer first, then swapping the whole buffer out.
It must be done manually on some platforms while others do it automatically.

Lastly, the `getJoystickState()`-method is called to get any game inputs.
This, again, is platform specific.
The desktop platform only supports the keyboard for controlling pacman.

Because both the `Canvas` and the `JoystickState` are changing each frame, they are simply arguments to the `step()`-method.
The platform can poll this information on every loop iteration and pass it to the game loop.
With this, we're done for the desktop.

## Porting to the Web

With the chores out of the way, now comes the interesting part: implementing our new interfaces for the **web** platform.
TeaVM has a bundled-in extension it calls [JSO](https://teavm.org/docs/runtime/jso.html) which offers Java bindings for JavaScript functions available in browsers.
This allows us to research an approach for JavaScript and then translate it almost 1:1 to Java code.

### The `<canvas>` element

For rendering the frames on the website, I chose the simple [HTML Canvas](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement) element.
So again, let's implement the `Canvas` interface, but this time using the TeaVM bindings for [`CanvasRenderingContext2D`](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D).
The API is _similar_ to the `java.awt.Graphics` API from the desktop - with some surprises.

```java
public void setColor(Color color) {
	// NOTE: The original Swing implementation uses one color for both - so we
	// emulate this behaviour
	this.render.setFillStyle("rgb(" + color.r + "," + color.g + "," + color.b + ")");
	this.render.setStrokeStyle("rgb(" + color.r + "," + color.g + "," + color.b + ")");
}
```

This example is straightforward, although there is already a subtle difference.
Since the interface (and the game code by extension) is very close to the AWT draw calls, we'll just emulate this behavior.
For other draw calls, this was more complicated though:

```java
public void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle) {
	int radius = width / 2;
	// Adjust X/Y from top-left (in Swing) to center (HTML canvas)
	int centerX = x + radius;
	int centerY = y + radius;
	// This value can briefly become negative, which flashes on Web.
	// It does nothing in the Swing implementation, go figure...
	arcAngle = Math.max(arcAngle, 0);
	// Positive angles means COUNTER-clockwise rotation in Swing...
	startAngle = -startAngle;
	arcAngle = -arcAngle;
	// Convert from degrees to radians
	double startRad = Math.toRadians(startAngle);
	double endRad = Math.toRadians(startAngle + arcAngle);

	this.render.beginPath();
	// NOTE: last "true" to draw counter-clockwise!
	this.render.arc(centerX, centerY, radius, startRad, endRad, true);
	this.render.lineTo(centerX, centerY);
	this.render.closePath();
	this.render.fill();
}
```

Through much trail and error, I finally got the `fillArc()` to work.
Luckily, most other functions weren't this complicated to port.
I made the conscious choice to not implement the `drawImage()`-methods - _yet_.
Instead, to get early feedback, I went ahead and worked on...

### GameLoop without looping

There isn't really a good equivalent to a thread in a browser.
At least not for games.
Instead, one can use the [`Window.requestAnimationFrame()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame)-method.
It tells the browser to call the given callback before it repaints.

```java
private void startLoop() {
  HTMLDocument document = Window.current().getDocument();
  HTMLCanvasElement canvas = (HTMLCanvasElement) document.getElementById("pacman_canvas");
  CanvasRenderingContext2D context = (CanvasRenderingContext2D) canvas.getContext("2d");
  this.web_canvas = new WebCanvas(context);

  GameLoop.INSTANCE.lock();
  Window.requestAnimationFrame(this);
}

public void onAnimationFrame(double timestamp) {
  // register for next frame
  Window.requestAnimationFrame(this);

  JoystickState input = getJoystickState();
  GameLoop.INSTANCE.step(last_input_state, web_canvas);

  // Clear for next frame
  last_input_state = JoystickState.NEUTRAL;
}
```

The first call to `Window.requestAnimationFrame()` "starts" the loop.
The browser will call the method on the next repaint.
Then, as part of rendering the next frame, the callback immediately registers itself _again_ to be called on the next repaint.
And we're looping!

There is one problem with this approach: We don't control how often `step()` is called anymore.
Depending on the hardware (and some other factors) the browser automatically decides the appropriate frame-rate itself.
On my MacBook with my 120Hz monitor attached, the game now runs at 120 FPS instead of the expected 60 FPS - meaning everything in the game is now twice as fast.

Let's not do that and instead only call `step()` at the expected interval (taken from [this SO answer](https://stackoverflow.com/a/19772220/717341)):

```java
private static final double TARGET_FPS_INTERVAL = 1000 / 60;

public void onAnimationFrame(double timestamp) {
  Window.requestAnimationFrame(this);

  // Ensure we render/simulate at 60FPS
  double elapsed = timestamp - this.last_frame_time;
  if (elapsed > TARGET_FPS_INTERVAL) {
    // NOTE: subtract any time we waited "too long" on the current frame as well
    this.last_frame_time = timestamp - (elapsed % TARGET_FPS_INTERVAL);

    JoystickState input = getJoystickState();
    GameLoop.INSTANCE.step(last_input_state, web_canvas);
  }
}
```

There are other (and better) ways to deal with this.
One option is to separate game simulation from rendering and calculate the time delta between two frames.
If you're interested in learning more, there is an [excellent chapter](https://gameprogrammingpatterns.com/game-loop.html#sample-code) from the book "Game Programming Patterns" by Robert Nystrom that is available online **for free**.

With the gameloop done, I could see the game in action for the first time in the browser!
Well, partially.
Since images aren't drawn yet, you only see the edible dots, the score and pacman.
Everything else is not showing up.
Let's fix that next.

### Resource Loading

To render an image bitmap to an HTML canvas, one uses the [`drawImage()`-method](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage).
It can draw an image from multiple sources, but I wanted to keep it _very_ simple.

1. No async code. It adds complexity, especially when using TeaVM.
2. No loading over the network. I don't want to build a loading screen or deal with network failure.

Ideally, the resources would just be downloaded together with the code and the game would just start when _everything_ is ready.
The image resources are tiny (a few bytes each), so the bloat won't be too bad.
But if we don't want to load the images over the network, we need to somehow include them in the code at compile time.
How about Base64 encoded data URIs?

```groovy
task genBase64Resources(dependsOn: ":game:build") {
  // NOTE: Simplified for readability, see link below for full code...
  doLast {
    // Load the previously compiled `game` classes into the Gradle build runner
    def classLoader = new URLClassLoader(classpath.collect { it.toURI().toURL() } as URL[])
    // Inspect the `ImageResource` Enum that lists all image resources
    def containerClass = classLoader.loadClass("org.ita23.pacman.res.ImageResource");

    // Lets generate some Java source code
    def code = StringBuilder.newInstance()
    code << "public final class Base64Resource {\n"
    code << " public static String getResource(String path){\n"
    code << "  switch (path) {\n"

    containerClass.getEnumConstants().each {
      // One `case` for each ImageResource Enum constant
      code << "case \"" << it.resource_path << "\": "
      code << "return \"data:image/png;base64,"
      // Load the resource file and encode its content as Base64
      new File(respath, it.resource_path).withInputStream {
        code << Base64.encoder.encodeToString(it.readAllBytes())
      }
      code << "\";\n"
    }
    code << "}}}\n"

    // Write everything to the source file
    outputFile.text = code.toString()
  }
}

// Add the genreated code to be compiled along with `web` platform
sourceSets.main.java {
  srcDir(genBase64Resources)
}
```

This [custom Gradle task](https://github.com/LukasKnuth/pacman/blob/619a3b6b30830e9ab7ba524ad150f3f594e59fb5/web/build.gradle#L28-L71) generates Java source code for a new `Base64Resource` class.
The class has a single `getResource(String)`-method that accepts the resource path to be loaded.
In the method, a switch-case statement returns the Base64 encoded data URI for the given resource.
The result looks like this (properly formatted):

```java
public final class Base64Resource {
  public static String getResource(String path){
    switch (path) {
      case "/graphics/maze.png": return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAboAAAGzBAMAAACr1s9+AA...";
      case "/graphics/cherry.png": return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR..."
      // ...
    }
  }
}
```

I could have used something more fancy to create the source code, but for this simple case, `StringBuilder` is good enough.

The generated code is added to the compile step for `web`.
Now we can make use of this in the web-specific `Canvas` implementation by simply creating new `HTMLImageElement` and supplying the `src` attribute.

```java
private void loadImages() {
  for (ImageResource resource : ImageResource.values()) {
    HTMLImageElement image = Window.getDocument().createElement("img");
    image.setSrc(Base64Resource.getResource(resource.resource_path));
    this.imageCache.put(resource, image);
  }
}

public void drawImage(ImageResource resource, int x, int y) {
  this.render.drawImage(this.imageCache.get(resource), x, y);
}
```

> [!tip]
> Because the created `HTMLImageElement` is never added to the DOM, it's never rendered on the HTML page.
> I simply use the browsers' ability to decode an Image from the Base64 data URI and then hold on to the result in memory.

The solution is quite simple, does not use any async/promise code, and I don't need to handle any network failures.
The game screen is simply black until the code is fully loaded and the game launches.
This is fast enough that a loading screen isn't necessary either.

### Game Input

The last step now is to implement polling the browser for game inputs.
I won't go into how this works for keyboard because it is quite boring.
But, since this project is all about making the game accessible, I can't ignore mobile devices.
And most of these don't ship with keyboards [anymore](https://en.wikipedia.org/wiki/HTC_Dream).

The [touch input API](https://developer.mozilla.org/en-US/docs/Games/Techniques/Control_mechanisms/Mobile_touch) in the browser uses a _push_ system, where we register a listener on an Element and receive callbacks:

```java
private JoystickState last_input_state = JoystickState.NEUTRAL;
private TouchInput touch_input = new TouchInput();

canvas.addEventListener("touchmove", new EventListener<TouchEvent>() {
	public void handleEvent(TouchEvent evt) {
	  last_input_state = touch_input.onTouchMove(evt);
	}
});
// Repeat for `touchstart`, `touchend` and `touchcancel`
```

The actual touch gesture detection is in the `TouchInput` class.
Here, I simply subscribed to all touch specific events on the `<canvas>` element and forward them.
The `JoystickState` is another very simple enum with five constants: `UP|DOWN|LEFT|RIGHT` and `NEUTRAL` - meaning no input is currently given.

My goal was to support two distinct input methods:
Flicking on the screen in a direction **and** holding down and swiping direction changes as pacman moves along.
The latter means I can't just use `touchdown` and `touchup` and calculate the distance/direction - instead this must be done continuously on every `touchmove` event:

```java
private static final double NOT_SET = -1.0;

private double previous_x = NOT_SET;
private double previous_y = NOT_SET;
private JoystickState state = JoystickState.NEUTRAL;

public JoystickState onTouchMove(TouchEvent event) {
  event.preventDefault();
  // We only support fling/swipe, so we only need one finger
  Touch first_finger = event.getChangedTouches().get(0);
  if (first_finger == null) {
    // No touch input currently, can't determine a direction
    return JoystickState.NEUTRAL;
  } else {
    double new_x = first_finger.getClientX();
    double new_y = first_finger.getClientY();
    this.state = handleChange(previous_x, previous_y, new_x, new_y);
    // Only update if we have a new direction
    if (this.state != JoystickState.NEUTRAL) {
	    this.previous_x = new_x;
	    this.previous_y = new_y;
    }
    return this.state;
  }
}

// The same logic happens for `touchend` and `touchstart` handlers.
public JoystickState onTouchCancel(TouchEvent event) {
  event.preventDefault();
  // When the fling is complete or the swipe is ended, reset
  this.previous_x = NOT_SET;
  this.previous_y = NOT_SET;
  this.state = JoystickState.NEUTRAL;
  return this.state;
}
```

Keep a running `X|Y` coordinate of the last _complete_ gesture (either swipe or fling).
When the touch gesture is ended/cancelled or a new one is started, reset the whole state.
Now for determining the direction of the gesture:

```java
private static final double MIN_DISTANCE = 45.0;

private static JoystickState handleChange(double previous_x, double previous_y, double new_x, double new_y) {
  // How _far_ did the user swipe/fling?
  double change_x = previous_x - new_x;
  double change_y = previous_y - new_y;
  if (Math.abs(change_x) >= MIN_DISTANCE) {
    // We're past the threshold, which direction though?
    return (change_x < 0.0) ? JoystickState.RIGHT : JoystickState.LEFT;
  } else if (Math.abs(change_y) >= MIN_DISTANCE) {
    return (change_y < 0.0) ? JoystickState.DOWN : JoystickState.UP;
  } else {
    // We're not past the movement threshold, can't determine a direction yet.
    return JoystickState.NEUTRAL;
  }
}
```

From the last completed gestures coordinate, calculate the distance to the current touch coordinate.
If the absolute distance exceeds the threshold/deadzone/minimum, continue.
In the browsers coordinate system, `0|0` is the top-left of the screen/element.
Determine the direction by looking at the leading sign of the previously calculated distance.

This code is simple and easy to understand, but it does have problems.
If the gesture is perfectly diagonal, the horizontal direction is just always preferred.
A developer with a stronger mathematical background might use `atan2` for this problem, but my experiments didn't yield _better_ game feel.
I decided to keep the code I understood and moved on.

### Bonus points: Gamepad

Because modern browsers are basically operating systems at this point, of course they have [Gamepad support](https://developer.mozilla.org/en-US/docs/Games/Techniques/Control_mechanisms/Desktop_with_gamepad).
First, there are listeners that are called when a Gamepad is connected to the computer (if the browser supports it).

```java
gamepad_input = new GamepadInput();
// IMPORTANT: These events are always dispatched on `Window`!
Window.current().addEventListener("gamepadconnected", new EventListener<GamepadEvent>() {
	public void handleEvent(GamepadEvent evt) {
	  gamepad_input.onConnected(evt);
	}
});
Window.current().addEventListener("gamepaddisconnected", new EventListener<GamepadEvent>() {
	public void handleEvent(GamepadEvent evt) {
	  gamepad_input.onDisconnected(evt);
	}
});
```

Again I moved the actual Gamepad handling code into its own `GamepadInput` class.
Since pacman is a single player game, only a single gamepad instance is supported.
Also, the player doesn't want to switch to a newly connected gamepad while they are still playing on the old one.

```java
private static final int NOT_CONNECTED = -1;
private static final String STANDARD_MAPPING = "standard";
private int current_gamepad_index = NOT_CONNECTED;

public void onConnected(GamepadEvent evt) {
  int gamepad_index = evt.getGamepad().getIndex();
  String mapping = evt.getGamepad().getMapping();
  // Only allow one gamepad - keep the same gamepad if a new one is connected
  // Only allow gamepads using the standard button mapping
  if (this.current_gamepad_index == NOT_CONNECTED && mapping == STANDARD_MAPPING) {
    this.current_gamepad_index = gamepad_index;
  }
}

public void onDisconnected(GamepadEvent evt) {
  int gamepad_index = evt.getGamepad().getIndex();
  // Only reset if the disconnected gamepad is the one we where using
  if (gamepad_index == this.current_gamepad_index) {
    this.current_gamepad_index = NOT_CONNECTED;
  }
}
```

The `GamepadEvent` has a `getIndex()` method that allows tracking a specific gamepad.
This input is a _poll_ based input, meaning there is no listener that is called when a button is pressed.
Instead, the game will ask for the whole gamepads state _right now_ as part of the gameloop.

```java
// Canonical Index on Standard Gamepad
private static final int IDX_DIGI_L = 14;
private static final int IDX_DIGI_R = 15;
private static final int IDX_DIGI_U = 12;
private static final int IDX_DIGI_D = 13;

public JoystickState getDirection() {
  if (this.current_gamepad_index != NOT_CONNECTED) {
    Gamepad pad = Navigator.getGamepads()[this.current_gamepad_index];
    if (pad.isConnected()) {
      // Check all relevant buttons (shortened for the article)
      GamepadButton[] btns = gamepad.getButtons();
      if (btns[IDX_DIGI_D].isPressed()) {
        return JoystickState.DOWN;
      } else if (btns[IDX_DIGI_U].isPressed()) {
        return JoystickState.UP;
      } else if (btns[IDX_DIGI_L].isPressed()) {
        return JoystickState.LEFT;
      } else if (btns[IDX_DIGI_R].isPressed()) {
        return JoystickState.RIGHT;
      }
    }
  }
  return JoystickState.NEUTRAL;
}
```

The W3C standard describes a ["Standard Gamepad"](https://w3c.github.io/gamepad/#dfn-standard-gamepad) that all _known_ gamepads should be remapped to.
I verify that the current gamepad has this mapping in our `onConnected` method above.
This allows includes most commonly used gamepads like PlayStation and Xbox with one configuration.

```java
public void onAnimationFrame(double timestamp) {
  // ... other gameloop code

  if (this.last_input_state == JoystickState.NEUTRAL) {
    // Poll gamepad if we don't have a direction from other inputs yet...
    this.last_input_state = gamepad_input.getDirection();
  }

  GameLoop.INSTANCE.step(this.last_input_state, web_canvas);

  // Clear for next frame
  this.last_input_state = JoystickState.NEUTRAL;
}
```

With the gameloop updated, the game can now be controlled with a gamepad as well.

## Finishing Up

Finally, we have an easily playable game.
For now, I've opted not to implement sound in the web version for simplicity’s sake.

I set up a CI to have it build and deploy everything to GitHub Pages.
You can [play the game for yourself](https://lukasknuth.github.io/pacman/) if you're curious.
The result is a single, minified JavaScript file at **94 kB** compressed.
This file contains the code, and all the assets.
It runs well on Safari, Firefox and Chrome - even the mobile versions.

Overall, this was a very fun project without any big technical hurdles.
The little debugging I had to do was simply `System.out.println`, which shows up in the browsers developer console.
Working with TeaVM was very easy, although I needed to read a good bit of example source code to understand how it works.
The documentation is sparse, but the following resources helped me a lot:

- [List of available classes](https://teavm.org/jcl-report/recent/jcl.html)
- [JavaDocs for TeaVM](https://javadoc.io/doc/org.teavm/)
- [Samples from the TeaVM repo](https://github.com/konsoletyper/teavm/tree/master/samples)
- [Google Groups/Mailing list](https://groups.google.com/g/teavm)

What helps it tremendously is that you can simply research something for JavaScript and the ideas and most of the code will translate almost 1:1 to TeaVM.
Any prior experience with web APIs still applies.

I was impressed that the code I wrote as a beginner 13 years ago now runs (with little changes) on a different platform.
It's a testament to the Java platforms backward compatibility and the diverse and mature tooling that exists around it.

