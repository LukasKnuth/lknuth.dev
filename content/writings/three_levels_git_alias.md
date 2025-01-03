---
title: "Three Levels of Git Aliases"
date: 2024-11-29T17:08:30+01:00
---

[Chapter 2.7 of the Git Book](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) is called "Git Aliases". Tucked away in it is probably the most powerful built-in feature to customize git to your own liking.

Aliases allow you to define a shorthand for a git sub-command - including its options - that you commonly type in your workflow.
We'll illustrate three increasingly powerful levels of customization enabled by aliases using a simple example:

<!--more-->

I want to open all modified files in my worktree with my editor.
To do this, we'll return a newline separated list of modified file paths from git and pipe it into [xargs](https://www.man7.org/linux/man-pages/man1/xargs.1.html) to open all of them with [Helix](https://helix-editor.com/): `git sx | xargs hx`

To create the alias, you can use `git config --global alias`.
Alternatively, edit the `[alias]` section of the `.gitconfig` file in your home directory with any text editor.

## Level 1

A simple alias that saves us from typing a full git sub-command, including its options:

```bash
sx = "status --porcelain"
```

We can now type `git sx`, which is equivalent to typing `git status --porcelain`.
It's the simplest type of alias, but it already saves us from typing and remembering a bit of stuff.
Note that we can still add any additional options we like.
For example, `git sx --staged` is equivalent to `git status --porcelain --staged`.

The `--porcelain` option gets rid of the coloring and is generally meant to make the output of the command more usable for scripting.
If we pipe the output into helix now, it will open more than just the modified files.
This is because each line starts with four characters indicating the mode of the file - whether it was added, modified, removed, etc.

## Level 2

If we place an exclamation mark (or "bang" in bash-speak) at the beginning of the alias line, the given command is executed in a shell.
We can use this to launch any executable (including `git` itself) and further process the output.

```bash
sx = "!git status --porcelain | cut -c4-"
```

The Unix [cut](https://man7.org/linux/man-pages/man1/cut.1.html) utility takes a newline separated input and removes characters from each line.
We instruct it to remove the first `4` characters and to read the input from `stdin`.
We then pipe the `git status` output into it, removing the four characters indicating the file mode.

It's important to note that whatever directory _within_ the git repository we run the bang-alias from, the shell command will always have the repositories root folder set as it's working directory!

If we run `git sx | xargs hx` now, it opens all files that are currently modified in our working tree.
Nice, but I also want to filter the output by directory, the way that `git status src/` would return only modified files _inside_ the `src/` folder.

## Level 3

If we add the folder to filter by at the end of our command like `git sx src/`, we'll get an error from `cut: src: no such file or directory`.
This is because what we're running is `git status --porcelain | cut -c4- src/`.
What we actually want is to pass the folder option to the `git status` part, before `cut` is even run.

Luckily, a bang-alias is basically a shell script.
So we can write shell functions:

```bash
sx = "!f() { git status --porcelain $1 | cut -c4-; }; f"
```

This declares a shell function `f` and then executes it immediately.
Any options added when invoking the alias (like the folder to filter by) are captured by the function and are available using the dollar notation.
The first option is available under `$1`, the second under `$2` and so on.
To get all of them at once, we can use `$@`.

Using this, we can put the folder option to filter by folder where it belongs.
The final result works as expected:

```bash
git sx src/ | xargs hx
```

This will open any modified file from the `src/` folder in Helix.

## More aliases

Over the past months I have accumulated many git aliases to shorten what I have to type.
I have also aliased `git` to just `g` to make it even shorter.

I find what works great for choosing aliases is shortening the original command name to a single character and adding additional characters for more specific variations:

- `git di` is `git diff`
- `git dis` is `git diff --staged`
- `git s` is `git status --short`
- `git ss` is `git status` (the longer one)

If you're intrigued, you can find my full config along with others in my [dotfiles](https://github.com/LukasKnuth/dotfiles) repository.
