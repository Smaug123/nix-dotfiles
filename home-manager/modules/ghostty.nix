{pkgs, ...}: {
  programs.ghostty = {
    enable = pkgs.stdenv.isLinux;
    enableZshIntegration = true;
    settings = {
      keybind = [
        "shift+enter=text:\\n"
      ];
    };
  };

  home.packages =
    if pkgs.stdenv.isLinux
    then [
      pkgs.ghostty
    ]
    else [];
}
