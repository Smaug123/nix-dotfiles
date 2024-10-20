{pkgs, ...}: {
  imports = [./zsh.nix];
  home.packages = [
    pkgs.tmux
  ];

  programs.tmux = {
    shell = "${pkgs.zsh}/bin/zsh";
    escapeTime = 50;
    mouse = false;
    prefix = "C-b";
    enable = true;
    terminal = "screen-256color";
    extraConfig = ''
      set-option -sa terminal-features ',xterm-256color:RGB'
      set -g default-command "exec ${pkgs.zsh}/bin/zsh"
    '';
  };
}
