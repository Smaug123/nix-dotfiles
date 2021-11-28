#!/bin/bash

dest="/usr/local/opt/gmp/lib/libgmp.10.dylib"
sudo mkdir -p "$(dirname "$dest")"
existing=$(readlink "$dest")
if [ $? -eq 1 ]; then
  sudo ln -s "NIX-GMP/lib/libgmp.10.dylib" "$dest"
else
  if [[ "$existing" == /nix/store/* ]]; then
    sudo ln -fs "NIX-GMP/lib/libgmp.10.dylib" "$dest"
  else
    echo "Existing symlink is $existing, refusing to overwrite"
    exit 1
  fi
fi
