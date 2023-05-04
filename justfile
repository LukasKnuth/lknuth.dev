set shell := ["zsh", "-uc"]

dev:
  hugo server

build:
  hugo --minify

new_article filename:
  hugo new writings/{{filename}}.md
