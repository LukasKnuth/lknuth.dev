---
title: "EPUBs the hard way"
date: 2024-03-27T21:30:11+01:00
draft: true
---

I like Low Tech Magazine.
Not only is their website solar powered and only availalbe when the weather is good, they provide an interresting viewpoint on technology as a whole.

Recently, they created a thematic collection of articles called ["How to Build a Low-tech Internet?"](https://solar.lowtechmagazine.com/2023/08/thematic-books-series/).
It's sold as a hard-copy book, but not as an EPUB.
Since I'm almost exclusively reading my books digitally these days - and the articles are all available on their website, I thought I'd just create an EPUB myself.

The irony of this is not lost on me.

## Getting the goods

On the Low Tech Magazine website, they have a simple Archive page with all articles that they have published.
I simply found all the ones in the book and downloaded them to my local machine.

I used `wget` for this task, the commandline itself I stole from [Tyler Smith](https://tinkerlog.dev/journal/downloading-a-webpage-and-all-of-its-assets-with-wget):

```bash
wget --page-requisites --convert-links --span-hosts --no-directories https://www.example.com
```

This does a number of things:

* It downloads the page you point it to into the current directory
* Alongside the page, it downloads all styles/images/scripts (`--page-requirements`)
* All assets are downloaded into a single, flat directory (`--no-directories`)
* Even if the assets are from different hosts (`--span-hosts`)
* Then all links to assets are rewritten to the local path (`--convert-links`)

This gives me a single directory with the main page as `index.html`, all images, styles and scripts.
Opening the local index file via the `file://` protocol (just by double clicking it) opens it in the browser.
It looks and works as if it was the online version.

This worked fine for this website, which is mostly static content.
If you want to download from a website which renders using JavaScript, you'll need to use an actual Browser.
[Chrome can get you stated](https://til.simonwillison.net/chrome/headless):

```bash
/path/to/chrome  --headless --dump-dom https://www.example.com
```

This will print the rendered websites HTML to stdout.
Downloading the assets that this page links to is left as an excercise for the reader.

## Creating an EPUB

With the content downloaded, I just hat to put it into an EPUB.
What little knowledge I had about ebooks was that they're basically a Zip file with some HTML content inside.
Surely this can't be too hard.

I looked at some ready-made tools available on the internet.
Either their output wasn't nice enough, or they where to clunky, or they did too much.
It might have just been my own curiosity though.

I started off by looking at how another great online source for ebooks does it: [StandardEbooks](https://standardebooks.org/)
They take publicly available works, digitized for the public and carefully touch them up to professional standards.
They have a great catalogue and a most importantly, a very detailed guide on Ebook creation, typesetting and some nice tooling.

I started by looking through their _extensive_ [manual of style](https://standardebooks.org/manual/) - and immediately decided this was too detailed.
Their [Step by step guide](https://standardebooks.org/contribute/producing-an-ebook-step-by-step) turned out to be a more appropriate resource.
Throughout the guide, they use [their own tooling](https://github.com/standardebooks/tools) to perform verious tasks. Which got me thinking.

Going through the guide, it struck me that there was a bunch of manual work involved.
While I was initially happy to do it _once_ for the one book I really wanted to make, I felt an itch.

![XKCD 1319](https://imgs.xkcd.com/comics/automation.png)

> I'd rather spend four hours automating a task that takes one hour to do manually.

## Automation

So, I want to automatically bundle a bunch of static HTML into an EPUB container.
I would need to:

1. EPUBs use XHTML, so I would have to convert the downloaded HTML to valid XHTML
2. I only want the actual article portion of the page, so I'd have to extract that
3. Cleanup the XHTML to remove unecessary elements and properties (like styling) left over from the website
4. Bundle and link all the Images used in the articles
5. Generate some standard EPUB files like the manifest, table of contents, etz

Lets get started

### Wrangling HTML

You [wouldn't parse HTML with Regex](https://stackoverflow.com/a/1732454/717341), so what else is there?
Because I had just installed the Standard Ebooks tools, which are written in Python, I read into [BeautifulSoup](https://beautiful-soup-4.readthedocs.io/en/latest/).
This can parse an entire DOM from an HTML source and offers navigation and manipulation functions.

My first attempt at a script to clean up and convert my HTML to XHTML looked like this:

```python
import sys
from bs4 import BeautifulSoup

def cleanup(tag):
  for noise in tag.find_all(["div", "section", "header"]):
    noise.unwrap()

  for figure in tag.find_all("figure"):
    caption = figure.find("figcaption")
    cap_text = caption.find("span")
    cap_text.name = "figcaption"
    caption.replace_with(cap_text)


with open(sys.argv[1]) as source:
    soup = BeautifulSoup(source, "html.parser")
    article = soup.find("section", id="content")
    cleanup(article)
    with open("out.xhtml", "w") as dest:
      dest.write(str(article))
```

I looked into the HTML files of the articles I had downloaded and found that the content was in a single `<section>` tag.
Next I looked for any elements that where needed on the website only and unwrapped them, removing the element and it's properties but retaining it's inner tags.
I wanted to get both the image and the caption that the article placed in the first `<span>` element after it, so I wrapped both into `<figure>` and `<figcaption>`.
Lastly, when converting the DOM to a string, it's valid XHTML by default, so just write that out.

This approach has problems.
For starters, the code is too specific to the HTML structure of the articles from this single website.
It assumes too much about it's input data to be useful elsewhere.

The second issue is that now, with elements like `<header>` unwrapped, the title and author where now just part of the article body.
This would make it hard to present them clerly.
It would also make it hard to generate a table of contents from the file without making the code _even more_ specific to the structure.

### Learn to stop worrying

By chance when looking into how other tools automated this part, I came accross [mozilla/readability](https://github.com/mozilla/readability).
This is the standalone library powering Firefoxes "Reader View", which simplifies page content and presents it very much like an Ebook reader would.

TODO Some images here???

Eurika!
We can harness this power for ourselfs.
It's pretty simple too:

```javascript
const { JSDOM } = require("jsdom")
const { Readability } = require("@mozilla/readability")
const fs = require("fs")

function simplify(html) {
  const doc = new JSDOM(html)
  const reader = new Readability(doc.window.document)
  return reader.parse()
}

const file = fs.readFileSync(process.argv[2], "utf8")
const simple = simplify(file)
fs.writeFileSync("out.xhtml", simple.content, "utf8")
```

Since readability is a JavaScript library, I switched over from Python.
Even though I preferr BeautifulSoup to JSDom, I didn't have to use it much anymore now.
The above code parses the entire HTML file, finds the relevant article text and simplifies it greatly.

It also parses a bunch of metadata from the article, such as title, author publishing time, etc.
This got me thinking: I should do _something_ with this information.

### Perspective shift

What I needed was a simpler intermediate format.
One that wouldn't allow for complicated markup and focused on purely textual content.
One that would allow me to store the metadata that readability extracted along with the article, to be used in the next step.
One that could easily be converted to XHTML again.

Wait, I know such a format.
I use it to write this Blog.
I'm looking for Markdown!
