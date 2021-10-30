{ pkgs ? import <nixpkgs> {} }:

# If this fails, `chmod -R a+rw /usr/local/opt/gmp/lib`
pkgs.runCommandLocal "gmp-symlink" {} ''
dest="/usr/local/opt/gmp/lib/libgmp.10.dylib"
existing=$(readlink "$dest")
if [ $? -eq 1 ]; then
  ln -s ${pkgs.gmp}/lib/libgmp.10.dylib "$dest" && mkdir -p $out && touch $out/done.txt
else
  if [[ "$existing" == /nix/store/* ]]; then
    ln -fs ${pkgs.gmp}/lib/libgmp.10.dylib "$dest" && mkdir -p $out && touch $out/done.txt
  else
    echo "Existing symlink is $existing, refusing to overwrite"
    exit 1
  fi
fi
''
