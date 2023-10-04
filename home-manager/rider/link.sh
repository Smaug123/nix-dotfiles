#!/bin/sh

outfile="$1/resharper-host/GlobalSettingsStorage.DotSettings"
if [ -e "$outfile" ]; then
  existing=$(readlink "$outfile")
  if [ $? -eq 1 ]; then
    echo "Backing up existing settings file $outfile"
    mv "$outfile" "$outfile.bak"
    ln -s "NIX-RIDER-CONFIG/GlobalSettingsStorage.DotSettings" "$outfile"
  else
    case "$existing" in
      "/nix/store/"*)
        ln -fs "NIX-RIDER-CONFIG/GlobalSettingsStorage.DotSettings" "$outfile"
        ;;
      *)
        echo "Refusing to overwrite existing symlink to $existing" &&
          exit 1
        ;;
    esac
  fi
else
  ln -s "NIX-RIDER-CONFIG/GlobalSettingsStorage.DotSettings" "$outfile"
fi
