set shell := ["zsh", "-uc"]

dev:
  hugo --minify server --disableFastRender --logLevel info

build:
  hugo --minify

subset-font-text type:
  fonttools subset _fonts/iAWriterQuattroS-{{type}}.ttf --flavor=woff2 --output-file="static/fonts/iAWriterQuattroS-{{type}}.woff2" --unicodes-file="_fonts/iAWriterQuattroS-unicodes.txt" --layout-features='zero'
font-text: (subset-font-text "Regular") (subset-font-text "Italic") (subset-font-text "Bold") (subset-font-text "BoldItalic")

subset-font-code type:
  fonttools subset _fonts/JetBrainsMono-{{type}}.ttf --flavor=woff2 --output-file="static/fonts/JetBrainsMono-{{type}}.woff2" --unicodes-file="_fonts/JetBrainsMono-unicodes.txt" --layout-features='calt','zero'
font-code: (subset-font-code "Regular") (subset-font-code "Italic") (subset-font-code "Bold") (subset-font-code "BoldItalic")

check: build
  node_modules/.bin/subfont public/index.html --dry-run --recursive --canonicalroot https://lknuth.dev

new_article filename:
  hugo new writings/{{filename}}.md
