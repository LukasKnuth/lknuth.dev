---
title: "Font Performance"
date: 2025-06-15T18:22:18+02:00
---

We're at 100!

- Optimize font loading to prevent "Flash of unstyled text"
  - Validate with Lighthouse and add this as part of CI!
  - Create subset of my two fonts with only required symbols to decrease size
    - I'm not entirely sure which Unicode ranges to pick.
    - I _think_ my current fonts don't have Emojis (they render different on different devices)
  - Try using "faux bold/italic" where we don't add bold/italic font files and let the browser "fake it"
    - Depends on whether or not this looks good.
    - I use italics/bold sparingly in text.
    - The current code font also uses it sparingly
- Font matching https://meowni.ca/font-style-matcher/ would work but requires JS
  - you pick some CSS options that make two fonts look similar
  - when the fallback renders, it takes up close to the space that the webfont would take
  - when its then swapped out, there is no large re-layout
  - this requires JS to _remove_ the font settings as soon as the font is loaded though.

## Tradeoffs

- When adding `preload`, the font is always downloaded, even if the user has it installed locally
- Moving all CSS to the head isn't really an option I _think_
- Its not clear to me if inlining _just_ the `@font-face` declarations actually does anything. Apparently it still waits for the CSS file to be downloaded...
- Try running Ligthhouse in Chrome on local dev server to see differences faster.
- Overlaying fonts only works with JavaScript, don't really want that.
- Variable fonts seem too large in size. I think with preloading just the regular one, we should be good for the layout shifts.
- custom subset of font makes a lot of sense. But can I _verify_ that I haven't forgotten to add anything in there?
- The `@font-face` is NOT in the beginning of the generated CSS file. Can we move that? Or does inlining this part make more sense?

---

A few days ago I ran the [Web Performance Insights]() tool on my Blog and got a lower score than I expected.
Especially on the "Performance" metric, where I was only at 80%.
I couldn't let that stand, so I investigated it.

The biggest contributer to the low score was a "Late Layout Shift".
So whats that and how do I get rid of it?

## Late Layout Shift

A layout shift happens when the browser layouts the page content one way, and then later - when more information is available - has to re-layout the page again.

A simple example of this would be an image that doesn't have a static size set.
When the image isn't loaded yet, the browser might layout it by assigning it 1x1 pixels.
Then, some time later when the image is loaded, it turns out its actually 800x600 pixels large.
The browser must then layout the page _again_, this time with the correct image.

So far so good, **but** if the page was already rendered to the user, the re-layouting will make content jump visually.
This is irritaring when you're already reading the page.
So the later this re-layout happens, the worse the user experience and our score will become.

## FOUT

In my case, the main perpitrator of this late layout shift was the custom Webfont I use.
The _iA Writer Quattro_ is slightly wider than the fallback font that the browser picks.
This, combined with me using `font-display: swap` causes this effect.
[Simon Hearne's Post](https://simonhearne.com/2021/layout-shifts-webfonts/#prevent-layout-shifts-with-font-display) has some more details on the different options here.

So while the webfont hasn't been loaded yet, it layouts the text with the fallaback font.
As soon as the font loads, text is re-layout again.
This re-layout is significant because the text is much wider this time.
It can cause whole paragraphs to shift.
This phenomenon is called a "Flash of unstyled Text" or FOUT.

### Aproximate the Font

This idea is more cool than practical as it turns out.
The idea is that we can use some text specific CSS properties to make the fallback font look _more_ like the Webfont we want.
The goal is to reduce the amount of space that is shifted on the re-layout later.

The excellent [Font style matcher](https://meowni.ca/font-style-matcher/) tool helps do exactly that.
It overlaps the same text in two fonts of your choice and helps you visually make them as close as possible.

While I like this idea quite a bit, it has one drawback that I can't overcome: it requires JavaScript.
Because the CSS properties are set on the text containers, they should be removed again once the final webfont loads.
This is only possible by using JavaScript and the Fontloading API.
And I want to keep this blog free of any client-side scripting.

### Optimize the Font files

The webfont files I'm using are not large, but they're not small either.
And the page needs to load four files for each font: Regular, Italic, Bold, BoldItalic.
Of course it is an option to only load Regular and let the browser create the other styles.
But there are [good reasons against that](https://alistapart.com/article/say-no-to-faux-bold/).

Both _iA Writer Quattro_ and _JetBrains Mono_ clock in at about 45kb per file.
That means we're loading 360kb of data before a page with _just text_ can be layouted finally.
Of course this has less of an impact on repeated views when fonts might be cached.
But for a blog like this, one-off traffic from readers linked via HackerNews is more important.

So how do we make these files smaller?
One option is to [create just a subset](https://walterebert.com/blog/subsetting-web-fonts/) of symbols that are needed to render everything.
As an example, _JetBrains Mono_ contains the whole Greek and Cyrillic alphabet.
I don't speak either of those languages, so odds that I'll ever need all these characters are pretty low.

## Subsetting fonts

To do the actual work, I'll use [fonttools](https://github.com/fonttools/fonttools).
It has a [`subset`](https://fonttools.readthedocs.io/en/latest/subset/index.html) command that does exactly what we want.
The basic command looks like this:

```sh
fonttools subset _fonts/iAWriterQuattroS-Regular.ttf \
  --flavor=woff2 \
  --output-file="static/fonts/iAWriterQuattroS-Regular.woff2" \
  --unicodes-file="_fonts/iAWriterQuattroS-unicodes.txt" \
  --layout-features='zero'
```

I use a unicodes file instead of specifying them with the `--unicodes` argument because the file allows for comments.
To pick the actual unicode points I need, I used:

- [A unicode table](https://jrgraphix.net/r/Unicode/) to find the codepoints
- [Wakami Fondue](https://wakamaifondue.com/) to inspect the subset font

My final unicodes file for the text font (not used for code) looks like this:

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

The last part is the `--layout-features` flag, which lets me keep only the font features I want.
Some fonts have features that can be enabled on demand, such as `frac` which renders real fractions.

The only one I picked was the `zero` feature which makes the zero have a slash through it.
Note that this must be enabled via CSS to actually show up:

```css
font-feature-settings: "zero" on;
```

The procedure for the _JetBrains Mono_ font is similar, although fewer characters are needed.
The whole configuration is available in the [repository of this blog](https://github.com/LukasKnuth/lknuth.dev/blob/6ac1f161419b838c958492e322accab0673a417b/justfile#L1-L7).
During building of my static site I create `woff2` fonts from the `ttf` files in the `_fonts` folder.
The generated subset fonts are then deployed along with the rest of the website.

This whole spiel reduced the filesize of the fonts quite significantly.
_iA Writer Quattro_ files are now 12Kb, the _JetBrains Mono_ files are 29kb.
That means we're down from 360Kb originally to now **164Kb** for everything.

### Unicode CSS hint
- leaving out the `unicodes` css property because that only controls which font is _downloaded_ and we need the fonts anyways.

Instead of just outright removing an alphabet, there could be one font-file per alphabet.
Meaning _splitting_ a font into multiple files.
This is helpful for international websites with content in different languages.

CSS has the `unicode-range` descriptor, which goes into the `@font-family` declaration.
This informs the browser of which unicode ranges are in the specific font file.
The browser can then decide, based on the actual page content, which font files to load.

I left this one out for two reasons:
First, the `unicode-range` must be updated when new symbols are added.
I have this information already in my `[font]-unicodes.txt` file.
Remembering to do it in two places feels brittle.

Second, this only influences which font is _downloaded_.
If the browser encounters a symbol that is not present in the font, it will fall back automatically.

### Forgetting something?

Now, what happens if a symbol I have removed from the font is actually needed?
The browser will fall back to any of the fallback fonts, which in my case is `system-ui`.
That can look _odd_, especially if a single sentence has letters from multiple fonts.

To verify that I haven't removed anything super important, I use [subfont](https://github.com/Munter/subfont):

```sh
subfont public/index.html --dry-run \
  --recursive \
  --canonicalroot https://lknuth.dev
```

I only use it with `--dry-run` because its subsetting and integration of fonts is too opinionated for my taste.
The command above will first print any unicodes in the HTML output of the blog that are **not** part of the font.
This is font aware, so it knows which block of text is rendered using which font.
I use the output manually to verify that the font has everything necessary.

## Loading earlier

Now the font is much lighter, but the Chrome performance debugger shows that we're still re-layouting late.
This is due to the late loading of the font.
Webfonts are **not** loaded when the `@font-family` is reached, but only when the first element on the page actually _uses_ the font.
This means that fonts won't be loaded until much of the CSS is already parsed.

[Google suggests](https://web.dev/learn/performance/optimize-web-fonts#inline_font-face_declarations) to inline the `@font-face` declarations.
They also note that in this case, all critical CSS must be inlined.
Otherwise, the browser will wait for the CSS file again.

I quite like my simple setup at the moment, so I instead went with a `preload` directive:

```html
<link rel="preload" as="font" type="font/woff2" href="/fonts/iAWriterQuattroS-Regular.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/fonts/JetBrainsMono-Regular.woff2" crossorigin>
```

> [!note]
> The `crossorigin` property is **required**, even when loading the font from the same origin.
> Fonts are CORS objects, so they need to specify this.

This goes _at the top_ of the `<head>` of the page.
It instructs the browser to download the specified fonts _now_, promising they'll be needed soon.

Note that I only preload the Regular font variant.
This is on purpose.
The preload will block any further assets from being loaded, so it should be as small as possible.
If the Regular variant of the font is available, the layout will use faux bold/italic at first.
These are close enough, so that when the rest of the font variants are loaded, the shift isn't noticable.

### Consistency

Previously, I had a lot of `local()` functions in my `@font-family` definition.
The idea was to load the font from the users machine, if present.
For _JetBrains Mono_, I figured the chances where good with my audience.

The problem with this is that on _my_ machine, both fonts are installed locally.
This is the reason why I never saw these issues when developing, not even when simulating slow internet.

The second problem is that should I have use a new symbol that isn't in my font subset, I won't be able to tell.
The locally installed font has _everything_ in it, missing symbols won't be missing _on my machine_.

So I decided to remove any `local()` font loading.
This sacrifices a little speed for a few users for consistency across all of them.

## Results

I was already following most of the [best practices](https://web.dev/articles/font-best-practices), so this was just the last 10% for me.
With the new subset fonts, my "Performance" score is at 100%.
Even when loading the page over mobile internet, there are no more visible re-layouts.

