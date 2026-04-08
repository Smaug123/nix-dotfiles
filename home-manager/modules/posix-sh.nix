{pkgs, ...}: {
  home.packages = [
    pkgs.shellcheck
    pkgs.bash-language-server
  ];
}
