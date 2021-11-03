#!/bin/sh

dest="/Users/Patrick/Library/Application Support/JetBrains"
find "$dest" -type d -maxdepth 1 -name 'Rider*' -exec sh -c 'link.sh "$0"' {} \;
