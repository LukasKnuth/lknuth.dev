---
title: "Webfont and Performance"
date: 2025-06-25T18:22:18+02:00
---

A few days ago I ran the [PageSpeed Insights](https://pagespeed.web.dev/) tool on my Blog and got a lower score than I expected.
Especially in the "Performance" category, where I scored below 90%.
Obviously, I can't let that stand.

The biggest contributor to the low score was a "Cumulative Layout Shift".
So what is that, and how do I get rid of it?

<!-- more -->

## Layout and shifts

A layout shift happens when the browser layouts the content on the page and then - as more content arrives - has to re-layout the page again.

Imagine an `<img>` tag without a predefined size.
When the image isn't loaded yet, the browser has no idea of the space it will take up on the page.
It could layout the image by assigning it 1x1 pixels.
Later, when the image is loaded, it turns out its actually 800x600 pixels.
The browser must then layout the page _again_, this time with the correct space for the image.

This is not a problem per se, **unless** the page was already rendered to the user because the re-layout will make the content jump around visibly.
This is irritating when you're already reading the page.
So the later this re-layout happens, the worse the user experience and the score.

## FOUT

To find the exact timings and _what_ was causing the issue, I used the "Performance" tab in the Chrome Developer Tools.
The main perpetrator of the late layout shift was the webfont I use.

Text rendered with _iA Writer Quattro_ is wider than the fallback font that I specified.
Additionally, I'm using `font-display: swap`, which instructs the browser to not wait for the webfont to load.
Instead, the text is rendered using the fallback font first and then replaced when the webfont is fully loaded.
There are other options to this behavior, all [with their own drawbacks](https://simonhearne.com/2021/layout-shifts-webfonts/#prevent-layout-shifts-with-font-display).

Replacing the font causes the re-layout, which is significant because the text is much wider this time.
It can cause whole paragraphs to shift around.
This phenomenon is so common, it has an acronym: FOUT; or "Flash of unstyled Text".
There are some options to combat it.

### Approximate the Font

This is more of a cool concept than a practical tactic as it turns out.
The idea is to use CSS properties that influence text rendering to make the fallback font look _more_ like the final webfont.
The goal is to reduce the amount of space that is shifted on the re-layout later.
The excellent [Font style matcher](https://meowni.ca/font-style-matcher/) tool helps to do exactly that.
It overlaps the same text in two fonts of your choice and helps you visually align them as close as possible.

While I like this idea quite a bit, it has one drawback that I can't overcome: it requires JavaScript.
Because the CSS properties must be set on the text _containers_, you want them removed once the final webfont has loaded.
This is only possible by using JavaScript and the [Font Loading API](https://developer.mozilla.org/en-US/docs/Web/API/Document/fonts#doing_operation_after_fonts_are_loaded).
And I want to keep this blog free of any client-side scripting.

### Optimize the Font files

Each font consists of four files that have to be loaded, one for each font style: Regular, Italic, Bold and BoldItalic.
The simplest option then is to only use the Regular style and let the browser guesstimate the other styles.
But there are [good reasons against that](https://alistapart.com/article/say-no-to-faux-bold/).

The webfont files I'm using are not large, but they aren't small either.
Both _iA Writer Quattro_ and _JetBrains Mono_ clock in at about 45kb per file.
That means the browser must load **360kb** of fonts before it can compute the final layout - for a page with _just text_.
The impact of this is reduced on repeated views when fonts are cached.
But for a blog like this, one-off traffic from visitors coming via HackerNews and friends is important.

So how to make these files smaller?
One option is to [create a subset](https://walterebert.com/blog/subsetting-web-fonts/) of symbols that are needed to render everything.
As an example, _JetBrains Mono_ contains the whole Greek and Cyrillic alphabet.
I don't speak either of these languages, so odds that I'll ever need all these characters are pretty low.

## Subsetting fonts

I use [fonttools](https://github.com/fonttools/fonttools) to do this.
The [`subset`](https://fonttools.readthedocs.io/en/latest/subset/index.html) command does exactly what I want with the following arguments:

```sh
fonttools subset _fonts/iAWriterQuattroS-Regular.ttf \
 --flavor=woff2 \
 --output-file="static/fonts/iAWriterQuattroS-Regular.woff2" \
 --unicodes-file="_fonts/iAWriterQuattroS-unicodes.txt" \
 --layout-features='zero'
```

I use a unicodes file instead of specifying them with the `--unicodes` argument because the file allows for comments.
To pick the ranges I used [a unicode table](https://jrgraphix.net/r/Unicode/).
I then verified the output font using [Wakami Fondue](https://wakamaifondue.com/), which shows all symbols and features of the given font file.
Here is my final unicodes file for the text font:

```
# Basic Latin characters
U+0020-007F
# German ß
U+00DF
# German Umlauts
U+00E4
U+00F6
U+00FC
U+00C4
U+00D6
U+00DC
# Greek letter used in my headlines
U+039E
# Dashes
U+2010-2015
# Extra quotation
U+2018-201F
# Dots and ellipses
U+2022-2026
# &nbsp; HTML sequence
U+A0
```

The last part is the `--layout-features` argument, which lets me keep only the font features I want.
Some fonts have features that can be enabled on demand, such as `frac` to render real fractions of numbers.
The only one I want is `zero` which renders the zero with a slash through it.
Note that this must be enabled via CSS to actually show up:

```css
font-feature-settings: "zero" on;
```

The procedure for the _JetBrains Mono_ font is similar, although fewer characters are needed.
The whole configuration is available in the [repository of this blog](https://github.com/LukasKnuth/lknuth.dev/blob/6ac1f161419b838c958492e322accab0673a417b/justfile#L1-L7).

I run the above commands in my static page build process.
The subset `woff2` output fonts are then bundled with the page while the original `ttf` fonts are not.
This whole spiel reduces the file size of the fonts quite significantly:
_iA Writer Quattro_ files are now 12kb each, the _JetBrains Mono_ files are 29kb each.
In total the size is down from 360kb originally to now **164kb** for everything.

### Unicode CSS hint

Most articles on this topic suggest adding the `unicode-range` property on the `@font-family` of the subset font.
This tells the browser exactly which codepoints are in the font file.
The browser can then decide, based on the content its asked to render, which webfont files it needs to download.
This is helpful for international websites with content in different languages that use different alphabets.
Instead of just outright removing an alphabet, the font is _split_ into multiple files - one per alphabet.

I decided _not_ to do this for two reasons:
First, the `unicode-range` must be updated when new symbols are added.
I have this information already in my `[font]-unicodes.txt` file.
Remembering to do it in two places feels brittle.
Second, this only influences which font is _downloaded_.
If the browser encounters a symbol that is not present in the font, it will always use the fallback font.
Speaking of which...

### Forgetting something?

Now, what happens if a symbol I have removed from the font is actually used on the page?
The browser will fall back to any of the fallback fonts, which in my case is `system-ui`.
That can look _odd_, especially if a single sentence has letters from different fonts.

To verify that I haven't removed anything important, I use [subfont](https://github.com/Munter/subfont):

```sh
subfont public/index.html \
 --dry-run \
 --recursive \
 --canonicalroot https://lknuth.dev
```

I only use `--dry-run` because the way the tool integrates the fonts is too opinionated for my taste.
The command above will print any unicodes in the HTML output of the blog that are **not** part of the font.
This is content aware, so it knows which block of text is rendered using which font.
I use the output manually to verify that the font has everything necessary.

## Loading earlier

Fonts are now much lighter, but the Chrome performance debugger still shows a late re-layout.
It turns out Webfonts are **not** loaded when the `@font-family` is declared, but only when the first element on the page actually _uses_ the font.
This means that fonts won't be loaded until much of the CSS is already parsed.

[Google suggests](https://web.dev/learn/performance/optimize-web-fonts#inline_font-face_declarations) to inline the `@font-face` declarations.
They also note that in this case, all critical CSS must be inlined as well.
Otherwise, the browser will wait for the CSS file again.
I like my simpler setup better, so instead I use a `preload` directive:

```html
<link rel="preload" as="font" type="font/woff2" href="/fonts/iAWriterQuattroS-Regular.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/fonts/JetBrainsMono-Regular.woff2" crossorigin>
```

> [!warning]
> The `crossorigin` attribute is **required**, even when loading the font from the same origin.
> Fonts are CORS objects, so they need to specify this.

This goes at the top of the `<head>` of the page, before any stylesheets or scripts.
It instructs the browser to download the specified fonts _now_, promising they'll be needed soon.

Note that I **only** preload the Regular font variant.
This is on purpose.
The preload will block any further assets from being loaded, so it should be as small as possible.
If the Regular variant of the font is available, the layout will use faux bold/italic for the initial layout.
These are close enough so that when the rest of the font variants are loaded, the layout shift isn't noticeable.

### Consistency

Previously, I had a lot of `local()` functions in my `@font-family` definition.
The idea was to load the font from the users machine, if present.
At least for _JetBrains Mono_ I figured the chances were good with my audience.

The problem with this is that on _my_ machine, both fonts are installed locally.
This is the reason why I never saw these layout shifts when developing - not even when simulating slow internet.
Another problem is that when I use a new symbol that isn't in my font subset, I won't be able to tell.
The locally installed font has _everything_, missing symbols won't be missing _on my machine_.

So I have removed any `local()` font loading.
This sacrifices a small performance win for a few users to gain consistent loading and rendering behavior across all of them.

## Results

I was already following most of the [best practices](https://web.dev/articles/font-best-practices), so this was just the last 10% for me.
With the new subset fonts, my "Performance" score is at 100%.
Now, even for visitors on slow mobile internet, there are no more visible re-layouts.

Its one of these things where I was surprised by the depth behind a seemingly small topic.
Falsehoods developers believe about the simplicity of "just rendering text".
