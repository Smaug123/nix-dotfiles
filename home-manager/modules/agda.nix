{pkgs, ...}: {
  imports = [./emacs.nix];

  home.packages = [
    pkgs.agda
  ];
}
