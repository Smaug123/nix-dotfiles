{pkgs, ...}: {
  home.packages = [
    pkgs.ripgrep
  ];

  home.file.".config/ripgrep/config".source = ./ripgrep/ripgrep.conf;
}
