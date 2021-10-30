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
      python
      #pkgs.keepassxc
    ];

  # This line is required; otherwise, on shell startup, you won't have Nix stuff in the PATH.
  programs.zsh.enable = true;

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # TODO: get Spacemacs actually working
  #nixpkgs.overlays = [
  #  (import (builtins.fetchTarball {
  #    url = https://github.com/nix-community/emacs-overlay/archive/8ed671dab09f08e8079e24f9fc7800b7ce260fa2.tar.gz;
  #  }))
  #];


  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
