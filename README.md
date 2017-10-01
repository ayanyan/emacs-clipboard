# Functions for clipboard in Emacs on Mac

This software provides some functions reading and writing clipboard in Emacs on Mac.

## Quick Start

1. Copy the code into your `init.el`.

2. Restart Emacs.

## Usage

* `\C-c\C-y` pastes the contents of not the Emacs kill-ring but the OS clipboard.

* `\C-c\C-w` cuts the region text into the OS clipboard like `\C-w` even when Emacs runs in Terminal.

* `\C-c\M-\C-w` copies the region text into the clipboard and converts it for Japanese Excel-方眼紙.  (方眼紙 means a graph paper in Japanese.)

## Requirement

* `pbpaste` and `pbcopy` should be found in your load-path.

## Copyright Notice

Follow GPL v3 or later.
