{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "FiraCode Nerd Font Mono";
        };
      };
      terminal = {shell = "${pkgs.zsh}/bin/zsh";};
    };
  };

  home.packages = [
    pkgs.alacritty
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.droid-sans-mono
  ];
}
