#!/bin/sh

install_nix () {
  echo "Installing Nix..."
  curl -L https://nixos.org/nix/install | sh
  echo "Nix installed."
}

install_darwin_build () {
  echo "Installing nix-darwin..."
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer || exit 1
  ./result/bin/darwin-installer || exit 1
  rm -r ./result
  echo "nix-darwin installed."
}

ln -s . ~/.nixpkgs || exit 1

nix-build --version || install_nix || exit 1
darwin-rebuild changelog || install_darwin_build || exit 1

nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager || exit 1
nix-channel --update || exit 1

darwin-rebuild || exit 1
