#!/bin/bash

if [ -z "$1" ]; then
  echo Please provide the version of the commonmark spec
  echo See https://spec.commonmark.org/
  exit
else
  SPEC_VERSION=$1
fi


curl "https://spec.commonmark.org/$SPEC_VERSION/spec.json" |
  jq '[.[] | select(.section == "ATX headings" or .section == "Setext headings") | {markdown, section, valid: .html | test("<h[1-6]")}]' > tests/commonmark-$SPEC_VERSION.json
