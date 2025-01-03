set shell := ["zsh", "-uc"]

dev:
  hugo --minify server --disableFastRender --logLevel info

build:
  hugo --minify

new_article filename:
  hugo new writings/{{filename}}.md
