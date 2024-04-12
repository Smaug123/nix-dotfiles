{pkgs, ...}: {
  home.packages = [
    pkgs.direnv
  ];
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
