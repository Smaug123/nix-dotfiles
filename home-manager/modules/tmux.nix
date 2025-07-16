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
      
      # Vi mode
      set-window-option -g mode-keys vi
      
      # Use v to begin selection in copy mode
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      
      # Use Shift+V to select line
      bind-key -T copy-mode-vi V send-keys -X select-line
      
      # Use y to yank to clipboard
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
    '';
  };
}
