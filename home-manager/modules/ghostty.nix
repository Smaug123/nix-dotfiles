{pkgs, ...}: {
  programs.ghostty = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    enableZshIntegration = true;
    settings = {
      keybind = [
        "shift+enter=text:\\n"
      ];
    };
  };

  home.packages =
    if pkgs.stdenv.hostPlatform.isLinux
    then [
      pkgs.ghostty
    ]
    else [];
}
