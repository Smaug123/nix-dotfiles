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
    };
    extraConfig = ''
      output Unknown-1 scale 2
    '';
  };

  services.gpg-agent = {
    enable = nixpkgs.stdenv.isLinux;
    pinentryPackage = nixpkgs.pinentry-qt;
  };

  services.swayidle = {enable = true;};
  services.cbatticon = {
    lowLevelPercent = 20;
    iconType = "standard";
    enable = true;
  };
}
