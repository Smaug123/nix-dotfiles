[
  (self: super: {
    # https://github.com/NixOS/nixpkgs/issues/153304
    alacritty = super.alacritty.overrideAttrs (
      o: rec {
        doCheck = false;
      }
    );
  })

  (import (builtins.fetchTarball {
    url = https://github.com/nix-community/emacs-overlay/archive/9516033899da467b8fcee6536a61ea66ebd0c4fa.tar.gz;
  }))
]
