{nixpkgs, ...}: {
  home.packages = [nixpkgs.firefox-wayland nixpkgs.jetbrains.rider];
  nixpkgs.config.firefox.speechSynthesisSupport = true;

  wayland.windowManager.sway = {
    enable = true;
    config = {
      focus = {followMouse = false;};
      modifier = "Mod4";
      terminal = "alacritty";
      window = {border = 5;};
      bars = [
        { command = "${nixpkgs.waybar}/bin/waybar"; }
      ];
    };
    extraConfig = ''
      output Unknown-1 scale 2
    '';
  };

  programs.waybar = {
      enable = true;
      settings = {
          mainBar = {
              position = "bottom";
          };
      };
  };

  services.gpg-agent = {
    enable = nixpkgs.stdenv.isLinux;
    pinentryPackage = nixpkgs.pinentry-curses;
  };

  services.swayidle = {enable = true;};
}
