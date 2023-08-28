{
  nixpkgs,
  username,
  dotnet,
  ...
}: {
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

  services.swayidle = {enable = true;};
  services.cbatticon = {
    lowLevelPercent = 20;
    iconType = "standard";
    enable = true;
  };

  programs.vscode = {
    enable = true;
    enableExtensionUpdateCheck = true;
    enableUpdateCheck = true;
    package = nixpkgs.vscode;
    extensions = import ./vscode-extensions.nix {pkgs = nixpkgs;};
    userSettings = {
      workbench.colorTheme = "Default";
      "files.Exclude" = {
        "**/.git" = true;
        "**/.DS_Store" = true;
        "**/Thumbs.db" = true;
        "**/*.olean" = true;
        "**/result" = true;
      };
      "git.path" = "${nixpkgs.git}/bin/git";
      "update.mode" = "none";
      "docker.dockerPath" = "${nixpkgs.docker}/bin/docker";
      "explorer.confirmDelete" = false;
    };
  };
}
