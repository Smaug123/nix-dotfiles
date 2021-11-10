{ config, lib, pkgs, ... }:

let python = import ./python.nix { inherit pkgs; }; in

let gmp =
  if pkgs.stdenv.isDarwin then
      import ./gmp.nix { inherit pkgs; }
  else pkgs.gmp
  ; in

{

  nix.useDaemon = true;

  imports = [ <home-manager/nix-darwin> ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.Patrick = import ./home.nix;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget

  environment.systemPackages =
    [
      pkgs.alacritty
      pkgs.rustc
      pkgs.cargo
      pkgs.clang
      gmp
      #pkgs.keepassxc
      python
    ];

  # This line is required; otherwise, on shell startup, you won't have Nix stuff in the PATH.
  programs.zsh.enable = true;

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/25dd5297f613fd13971e4847e82d1097077eeb53.tar.gz;
    }))
  ];


  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
  nix.gc.automatic = true;
  nix.useSandbox = true;

  nix.extraOptions = ''
    auto-optimise-store = true
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
