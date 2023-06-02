# Usage

In articles/templates, use the `svg` shortcode:

```markdown
{{< svg src="subfolder/figure.svg" >}}
```

This will **embed** the SVG markup into the page at compile time, so the actual SVG files are _not_ served from the webserver.

# Cleaning up Excalidraw SVG

1. Remove both `width` and `height` attributes of the `svg` tag
	* The exported images are basically always to big and should be dynamically resized based on available space
	* If image sizes must be fine tuned, use the `width` and `height` attributes of the shortcode when embedding.
2. Remove the entire `defs` tag-block
	* The custom fonts are loaded as part of `themes/cactus/partial/_fonts.scss` and are globally available.