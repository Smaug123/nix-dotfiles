{
  description = "Patrick's Darwin Nix setup";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/9d6b46bbb26ac0b435e41a7f6e9e60bf1b43cbc2";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      # Can't take a version that includes https://github.com/nix-community/home-manager/pull/3233
      url = "github:nix-community/home-manager/f17819f4f198a3973be76797aa8a9370e35c7ca6";
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
    config = {
      #contentAddressedByDefault = true;
    };
  in let
    overlays = [emacs.overlay] ++ import ./overlays.nix;
  in {
    homeConfigurations = let
      system = "x86_64-linux";
    in let
      pkgs = import nixpkgs {inherit system config overlays;};
    in let args = { nixpkgs = pkgs; username = "patrick"; }; in {
      patrick = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          (import ./home.nix args)
          # home-manager.nixosModules.home-manager {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   home-manager.users.patrick = pkgs.lib.mkMerge [(import ./server-home.nix args) (import ./home.nix args)];
          # }
        ];
      };
    };
    darwinConfigurations = let
      system = "aarch64-darwin";
    in let
      pkgs = import nixpkgs {inherit system config overlays;};
    in {
      nixpkgs = pkgs;
      patrick = darwin.lib.darwinSystem {
        system = system;
        modules = let
          args = {
            nixpkgs = pkgs;
            username = "Patrick";
          };
        in [
          ./darwin-configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.Patrick = pkgs.lib.mkMerge [(import ./daily-home.nix args) (import ./home.nix args)];
          }
        ];
      };
    };
  };
}
