{
  lib,
  pkgs,
  ...
}: let
  zshrc =
    builtins.replaceStrings
    [
      "@nix-git@"
    ]
    [
      "${pkgs.git}/bin/git"
    ]
    (builtins.readFile ./zsh/zshrc);
in {
  home.activation.removeZcompdump = lib.hm.dag.entryBefore ["writeBoundary"] ''
    rm -f ~/.zcompdump*
  '';

  home.packages = [
    pkgs.coreutils
    pkgs.git
  ];

  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit -C -D";
    history = {
      expireDuplicatesFirst = true;
    };
    sessionVariables = {
      EDITOR = "vim";
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
    };
    shellAliases = {
      vim = "nvim";
      view = "vim -R";
    };
    initContent = zshrc;
  };

  programs.fzf.enableZshIntegration = true;
}
