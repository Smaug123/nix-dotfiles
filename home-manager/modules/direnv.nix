{pkgs, ...}: let
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
    enableZshIntegration = true;
    package = direnv;
    nix-direnv.enable = true;
    # stdlib = builtins.readFile ../direnv/envrc;
  };
}
