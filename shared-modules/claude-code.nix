# A module for both NixOS and nix-darwin, not a home-manager one. Under
# `home-manager.useGlobalPkgs`, home-manager's `pkgs` is the system's package set
# and home-manager modules may not set `nixpkgs.*`, so permitting this unfree
# package has to happen at the system level.
{username}: {
  nixpkgs.config.allowUnfreePackages = ["claude-code"];

  home-manager.users.${username} = {pkgs, ...}: {
    home.packages = [
      pkgs.claude-code
    ];

    home.file.".claude/settings.json".source = ./claude-code/settings-raw.json;
  };
}
