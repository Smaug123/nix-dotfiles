{lib, ...}: {
  home.activation.removeZcompdump = lib.hm.dag.entryBefore ["writeBoundary"] ''
    rm -f ~/.zcompdump*
  '';

  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit -C";
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
    initContent = builtins.readFile ./zsh/zshrc;
  };

  programs.fzf.enableZshIntegration = true;
}
