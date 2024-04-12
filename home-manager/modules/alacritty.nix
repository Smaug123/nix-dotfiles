{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "FiraCode Nerd Font Mono";
        };
      };
    };
  };

  home.packages = [
    pkgs.alacritty
    (pkgs.nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
  ];
}
