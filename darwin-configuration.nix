{ pkgs, inputs, ... }:

let
  inherit (inputs) home-manager;
in

let python = import ./python.nix { inherit pkgs; }; in

{

  nix.useDaemon = true;
  #imports = [ home-manager ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.Patrick = import ./home.nix { pkgs = pkgs; };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget

  environment.systemPackages =
    [
      pkgs.alacritty
      pkgs.rustup
      pkgs.libiconv
      pkgs.clang
      #pkgs.keepassxc
      python
    ];

  # This line is required; otherwise, on shell startup, you won't have Nix stuff in the PATH.
  programs.zsh.enable = true;

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";

  nixpkgs.overlays = import ./overlays.nix;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "vscode"
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nixFlakes;
  nix.gc.automatic = true;

  # Sandbox causes failure: https://github.com/NixOS/nix/issues/4119
  nix.useSandbox = false;

  nix.extraOptions = ''
    auto-optimise-store = true
    experimental-features = nix-command flakes
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
