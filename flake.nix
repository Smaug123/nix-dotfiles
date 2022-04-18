{
  description = "Patrick's Darwin Nix setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    darwin,
    emacs,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "aarch64-darwin";
  in let
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "vscode"
        ];
    };
  in let
    overlays = [emacs.overlay] ++ import ./overlays.nix;
  in let
    pkgs = import nixpkgs {inherit system config overlays;};
  in {
    darwinConfigurations = {
      nixpkgs = pkgs;
      patrick = darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin-configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.Patrick = import ./home.nix {nixpkgs = pkgs;};
          }
        ];
      };
    };
  };
}
