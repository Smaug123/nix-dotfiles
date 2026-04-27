{
  lib,
  pkgs,
  ...
}: let
  # FIXME(nixpkgs#513019): direnv's checkPhase can hang on aarch64-darwin
  # while fish/zsh substitutes are served with broken code signatures.
  # Remove this once nixpkgs#513081 or an equivalent upstream fix lands.
  direnv = assert pkgs.lib.assertMsg (pkgs.direnv.version == "2.37.1" && (pkgs.direnv.doCheck or true))
  "direnv workaround may no longer be needed: direnv=${pkgs.direnv.version}, doCheck=${pkgs.lib.boolToString (pkgs.direnv.doCheck or true)}. Try removing it.";
    pkgs.direnv.overrideAttrs (_: {
      doCheck = false;
    });
in {
  home.packages = [
    direnv
  ];
  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    package = direnv;
    nix-direnv.enable = true;
    # stdlib = builtins.readFile ../direnv/envrc;
  };

  programs.zsh.initContent = lib.mkAfter ''
    _direnv_hook() {
      trap -- "" SIGINT

      local direnv_export_file="''${TMPDIR:-/tmp}/direnv-export-''${UID:-501}-$$.zsh"
      ${pkgs.coreutils}/bin/timeout --kill-after=1s 10s ${direnv}/bin/direnv export zsh >| "$direnv_export_file"
      local direnv_export_status=$?

      if [[ "$direnv_export_status" -eq 0 ]]; then
        source "$direnv_export_file"
      elif [[ "$direnv_export_status" -eq 124 || "$direnv_export_status" -eq 137 ]]; then
        print -ru2 "direnv: export timed out"
      fi

      rm -f "$direnv_export_file"
      trap - SIGINT
    }

    typeset -ag precmd_functions
    if (( ! ''${precmd_functions[(I)_direnv_hook]} )); then
      precmd_functions=(_direnv_hook $precmd_functions)
    fi

    typeset -ag chpwd_functions
    if (( ! ''${chpwd_functions[(I)_direnv_hook]} )); then
      chpwd_functions=(_direnv_hook $chpwd_functions)
    fi
  '';
}
