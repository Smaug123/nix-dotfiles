{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
  };

  home.packages = [
    pkgs.ghostty
  ];
}
