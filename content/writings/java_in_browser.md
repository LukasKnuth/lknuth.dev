---
title: "Java in the Browser"
date: 2025-03-31T18:40:09+02:00
---

Like most computer engineers, I wanted to work with games.
But not _creating_ new games, that was boring to me.
And since I fancied myself a capable engineer, I wanted to write a game engine.

So I stole somebody else's game.
I wanted something that was simple-ish, but not too simple.
So I picked pacman.

I read through the (excellent) [PAC-MAN Dossier](https://pacman.holenet.info/).
The document has _everything_ you need to build your own version of the game.
It details the basic game rules, the point system and how the Ghost AI works.
It's also not too technical, so you get to make the interesting decisions for yourself.

So I went to work.
I stole all the assets.
And I built a game engine.
From scratch.
In Java.

<!-- Worked on it from April 12 2012 until June 3rd 2012 -->
It took me about two months to get the game into a state that I was satisfied with.
It has the faithful implementation of all four ghost AIs.
You can control pacman through the original maze and collect points.
The game resets the level when you clear it, but it keeps your score.

The project lived at [github.com/LukasKnuth/pacman](https://github.com/LukasKnuth/pacman/) for 13 years...

Until I was recently cleaning out my old repositories and stumbled upon it.

## Digital Exhibit

The goal for this project was to make my version of the game more accessible.
Up until this point, the repository didn't even have a build script.
But even with that, people would still be expected to install Java on their machines to run it.

It would be soo much nicer if I could just run the game in a browser.
If I lower the barrier for entry this much, people might even play the game for a few rounds.

Crucially, what I _didn't want_ was to make a large rewrite of the game.
I could improve the game, fix some of its bugs and add some features I left out.
I decided that wasn't in the spirit of the project.

The goal is to make my old Java game run in the browser while keeping as much of its charm/jank intact.

## Java in the Browser

My first idea was to compile it to WASM.
Surely these days every programming language compiles to WASM, right?

There is actually a project, [JWebAssembly](https://github.com/i-net-software/JWebAssembly), that does this.
However, their repository didn't have a commit in the last two years - which either means it's complete or abandoned.

Next I found [CheerpJ](https://cheerpj.com/).
As far as I can tell, this is a full re-implementation of the entire JDK in Web Assembly.
It's a drop-in solution, just take your old `.jar` files and some JavaScript boilerplate and done.
The applications run without modification.
Boring.

The last project I found was [TeaVM](https://teavm.org/).
It is an ahead-of-time compiler for Java that can generate Web Assembly or JavaScript.
The project is well integrated but does require you to adapt code to work with it.
Perfect.

## Support multiple platforms

The game uses Java Swing to render itself to a desktop window.
It also uses some AWT classes (another Java Desktop toolkit) as well.
None of these classes are [available in TeaVM](https://teavm.org/jcl-report/recent/jcl.html).

The plan is as follows then:

1. Find any `javax.swing.*` or `java.awt.*` references in the code
2. Create interfaces for this functionality 
3. Implement the interfaces for Desktop with the `javax.swing.*` and `java.awt.*` classes
4. Implement the interfaces for Web with the [TeaVM JSO APIs](https://javadoc.io/doc/org.teavm/teavm-jso-apis/latest/index.html)
5. Profit

I create a basic Gradle project layout: a `game` project with the game logic and all my abstractions.
A second `desktop` project that depends on `game` where all the desktop specific code will be moved to.
Then, a new `web` project, also depends on `game`, which will then have the web specific code built with TeaVM.

### Rendering and Resource Loading

Because I didn't want to spend too much time on the boring stuff, I decided to make the abstraction as thin as possible.
For most things, that meant literally copy-and-pasting the Swing/AWT calls out of the codebase and creating an interface function with the same name and parameter signature.

For the renderer for example, I ended up with the following minimum set of draw calls:

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

For any AWT specific classes, such as `Color` and `Font`, I made my own (much simpler) versions.
The abstract `Canvas` expects my versions and the platform specific implementations are expected to convert between the types.
The rest of the **Desktop** implementation is just forwarding calls:

```java
/**
 * A Pacman canvas to draw the game on using Swing/AWT as the underlying
 *  render method.
 */
public class SwingCanvas implements Canvas {
	public void drawString(String text, int x, int y) {
	  this.graphics.drawString(text, x, y);
	}

	public void drawImage(ImageResource resource, int x, int y) {
		this.graphics.drawImage(this.resourceCache.get(resource), x, y, null);
	}

	public void fillOval(int x, int y, int width, int height) {
	  this.graphics.fillOval(x, y, width, height);
	}
  // ...
}
```

I also decided to solve **resource loading** in the specific platforms.
For the desktop for example, I can simply load images/sounds from the folders/jar file.

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
  // ...

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
Now most of the game was using my interfaces, except...

### Game Loop

The original game used Javas Executors to spawn a thread that re-evaluated the game every 16ms.
Under ideal circumstances, that means the game simulates and renders at a stable 60 FPS.
However, the executors are also not available in TeaVM.

Rather than throwing interfaces at the problem again, I decided the _loop_ part of "Game Loop" was a platform specific issue.
This turned out to be a very good call later.
I moved most of the games initialization code from the `main()`-method to a new `Bootstrap` class in the game project, to be reused by other platforms.

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
  GameLoop.INSTANCE.lock();
  game_loop_executor = Executors.newSingleThreadScheduledExecutor();
  game_loop_handler = game_loop_executor.scheduleAtFixedRate(
    game_loop, 0L, 16L, TimeUnit.MILLISECONDS
  );
}
```

The code above also shows another platform-specific tech: The double buffer.
This is a technique to reduce flickering by painting the next frame to an off-screen buffer first, then swapping the whole buffer out.
It must be done manually on some platforms while others do it automatically.

Lastly, we use the `getJoystickState()`-method to read any game inputs.
This, again, is platform specific.
The desktop platform only supports the keyboard for controlling pacman.

Because both the `Canvas` and the `JoystickState` are changing each frame, they are simply arguments to the `step()`-method.
The platform can poll this information on every loop iteration and pass it to the game loop.
With this, we're done for the desktop.

## Porting to the Web

Now comes the interesting part: implementing our new interfaces for the **web** platform.

### The `<canvas>` element

For rendering the frames on the website, I chose the simple [HTML Canvas](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement) element.
So again, we implement our `Canvas` interface, but this time we use the TeaVM bindings for [`CanvasRenderingContext2D`](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D) to implement it.
The API is _similar_ to the `java.awt.Graphics` API we used on the desktop - with some surprises.

```java
public void setColor(Color color) {
	// NOTE: The original Swing implementation uses one color for both - so we
	// emulate this behaviour
	this.render.setFillStyle("rgb(" + color.r + "," + color.g + "," + color.b + ")");
	this.render.setStrokeStyle("rgb(" + color.r + "," + color.g + "," + color.b + ")");
}
```

This example is straightforward, although we already have a subtle difference.
Since the interface (and the game code by extension) is very close to the AWT draw calls, we will just emulate their behavior.
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

### GameLoop with animation frames

There isn't really a good equivalent to a thread in a browser.
At least not for games.
Instead, usually the [`Window.requestAnimationFrame()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame)-method is used.
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

The first call to `Window.requestAnimationFrame()` registers our loop to be started.
The browser will call the method on its next repaint.
Then, as part of rendering the next frame, we immediately register ourselves _again_ to be called on the next repaint.
This is our loop done.

There is one problem with this approach: We don't control how often `step()` is called anymore.
Depending on the hardware (and many more factors) the browser automatically decides the appropriate frame-rate of our game.
On my MacBook with my 120Hz monitor attached, the game now runs at 120 FPS instead of the expected 60 FPS.
This means that everything in the game is now twice as fast.

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

With the gameloop now done, we can see the game in action for the first time in the browser!
Well, partially.
Since we can't draw images yet, we only see the edible dots, the score and pacman.
Everything else is not showing up.
Lets fix that next.

### Resource Loading

To render an image bitmap to an HTML canvas, we can use the [`drawImage()`-method](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage).
It can draw an image from multiple sources, but I want to keep it _very_ simple.

1. No async code. It adds complexity, especially when using TeaVM.
2. No loading over the network. I don't want to build a loading screen or deal with network failure.

Ideally, the resources would just be downloaded together with the code and the game would just start when _everything_ is ready.
How about Base64 encoded data URIs?
The image resources are tiny (a few bytes each), so the bloat won't be too bad.
But if we don't want to load the images over the network, we need to somehow include them in the code at compile time...

```groovy
task genBase64Resources(dependsOn: ":game:build") {
  # NOTE: Simplified slightly a bit for readability...
  doLast {
    # Load the games compiled classes into the Gradle runner JRE
    def classLoader = new URLClassLoader(classpath.collect { it.toURI().toURL() } as URL[])
    # Inspect the specific Enum that lists all our resources
    def containerClass = classLoader.loadClass("org.ita23.pacman.res.ImageResource");

    # Lets generate some Java source code
    def code = StringBuilder.newInstance()
    code << "public final class Base64Resource {\n"
    code << " public static String getResource(String path){\n"
    code << "  switch (path) {\n"

    containerClass.getEnumConstants().each {
      # One `case` for each ImageResource Enum constant
      code << "case \"" << it.resource_path << "\": "
      code << "return \"data:image/png;base64,"
      # Load the resource file and encode its content as Base64
      new File(respath, it.resource_path).withInputStream {
        code << Base64.encoder.encodeToString(it.readAllBytes())
      }
      code << "\";\n"
    }
    code << "}}}\n"

    # Write everything to the source file
    outputFile.text = code.toString()
  }
}
```

This custom Gradle task generates Java source code for a new `Base64Resource` class.
The class has a single `getResource(String)`-method that accepts the resource path to be loaded.
In the method, a switch-case statement returns the Base64 encoded data URI for the given resource.

The generated code is then added to the compile step and can now be used in our web platform.
I could have used something more fancy to create the source code, but a simple `StringBuilder` is good enough, too.
It looks like this (properly formatted):

```java
public final class Base64Resource {
  public static String getResource(String path){
    switch (path) {
      case "/graphics/maze.png": return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAboAAAGzBAMAAACr1s9+AA...";
      case "/graphics/cherry.png": return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR..."
      // ...
      default: throw new RuntimeException("unknown resource_path: "+path);
    }
  }
}
```

Now we can make use of this in our web specific `Canvas` implementation by simply creating new `HTMLImageElement` and supplying the `src` attribute.

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
> We don't add the newly created `HTMLImageElement` to the DOM, which means its never rendered on the HTML page.
> We simply use the browsers' ability to decode an Image from the Base64 data URI and then hold on to the result in memory.

The solution is quite simple, does not use any async/promise code, and we don't need to handle any network failures.
The game screen is simply black until the code is fully loaded and the game launches.
This is fast enough that we also don't need a loading screen.

### Game Input

The last step now is to implement polling the browser for game inputs.
I won't go into how this works for keyboard because it is quite boring.

Since this project is all about making the game accessible, we can't ignore mobile devices.
And most of these don't ship with keyboards [anymore](https://en.wikipedia.org/wiki/HTC_Dream).

TODO is this interresting/relevant?

## Finishing Up

Finally, we have a playable game.
I wrote a bit of Github Actions code to have it build and deploy the page to Github Pages.
You can [play the game for yourself](https://lukasknuth.github.io/pacman/) if you're curious.

For now, I've opted not to implement sound in the web version for simplicity’s sake.

TODO bit more polish on web version (don't start immediately, download link, github link, explanations)
