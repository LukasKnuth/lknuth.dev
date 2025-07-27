---
layout: movie
date: {{ .Date }}
title: "{{ replace .Name "_" " " | title }}"
params:
  year: 0000
  length: min
  genres: []
  imdb: url
---

About the movie
