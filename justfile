subset-text-style style:
  fonttools subset _fonts/iAWriterQuattroS-{{style}}.ttf --flavor=woff2 --output-file="static/fonts/iAWriterQuattroS-{{style}}.woff2" --unicodes-file="_fonts/iAWriterQuattroS-unicodes.txt" --layout-features='zero'
subset-text: (subset-text-style "Regular") (subset-text-style "Italic") (subset-text-style "Bold") (subset-text-style "BoldItalic")

subset-code-style style:
  fonttools subset _fonts/JetBrainsMono-{{style}}.ttf --flavor=woff2 --output-file="static/fonts/JetBrainsMono-{{style}}.woff2" --unicodes-file="_fonts/JetBrainsMono-unicodes.txt" --layout-features='calt','zero'
subset-code: (subset-code-style "Regular") (subset-code-style "Italic") (subset-code-style "Bold") (subset-code-style "BoldItalic")

subset: subset-code subset-text

dev:
  hugo --minify server --disableFastRender --logLevel info

build: subset
  hugo --minify

check: build
  node_modules/.bin/subfont public/index.html --dry-run --recursive --canonicalroot https://lknuth.dev

new_article filename:
  hugo new writings/{{filename}}.md
