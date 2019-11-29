# md-toc

This library provides a generic way to generate ToC for markdown files.

Frustrated by other libraries that either do unnecessary work like converting
the markdown into html, or generate one specific type of ToC, this projects
tries to do ToC generation right.

## Basic principles

Instead of offering one monolithic generator, this library uses two steps:

1. The analyzer: Here you'll have to choose whether to use CommonMark, Github
  flavored Markdown or other supported versions. (currently only CommonMark)
2. The style: This script uses the output of the first script to generate
  the actual ToC.
  If you don't like any of the given styles, you can simply and quickly write
  this part yourself.

## How to use this library

> TODO

## Tests

### Commonmark

The script `make-commonmark-tests.sh` can automatically generate a test file
for a given version by simply calling

```sh
sh make-commonmark-tests.sh <VERSION>
```

It will then generate a file called `commonmark-<VERSION>.json` in the test
directory.

> TODO: Execute Tests
