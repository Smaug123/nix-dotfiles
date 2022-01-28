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
  };

  outputs = { self, darwin, nixpkgs, ...}@inputs: {
    darwinConfigurations = {
        nixpkgs = import nixpkgs {
            overlays = ./overlays inputs;
        };
        patrick = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [ ./darwin-configuration.nix ];
        };
    };
  };
}
