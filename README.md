# Functions for clipboard in Emacs on Mac

This software provides some functions reading and writing the clipboard in Emacs.

## Quick Start

1. Put the file appropriately and write `(load "clipboard.el")` in your `init.el`.

2. Restart Emacs.

## Usage

Simply, you can use some functions in your favorite way.
For a shortcut, global bindings are available automatically, which may be overridden by a major or minor mode.

- `C-c C-y` / `M-C-y` pastes the contents of not the Emacs kill-ring but the OS clipboard.

- `C-c C-w` / `M-C-w` copies the region text into the OS clipboard like `C-w` even when Emacs runs in Terminal.

- `M-C-x c e l` copies the region text into the clipboard and converts it for Japanese Excel-方眼紙.
  (方眼紙 means a graph paper in Japanese.)

## Requirement

- `pbpaste` and `pbcopy` (or `xsel`) should be found in your `load-path`.

## Copyright Notice

Follow GPL v3 or later.
