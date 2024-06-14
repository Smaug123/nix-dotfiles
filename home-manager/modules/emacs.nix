{pkgs, ...}: {
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [epkgs.evil];
    extraConfig = ''
      (load-file (let ((coding-system-for-read 'utf-8))
                 (shell-command-to-string "agda-mode locate")))
      (require 'evil)
      (evil-mode 1)
      (evil-set-undo-system 'undo-redo)
    '';
  };
}
