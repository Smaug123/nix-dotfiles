{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      keybind = [
        "shift+enter=text:\\n"
      ];
    };
  };

  home.packages = [
    pkgs.ghostty
  ];
}
