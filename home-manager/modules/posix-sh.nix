{pkgs, ...}: {
  home.packages = [
    pkgs.shellcheck
    pkgs.nodePackages_latest.bash-language-server
  ];
}
