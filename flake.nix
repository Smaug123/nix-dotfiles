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
    emacs.url = "github:nix-community/emacs-overlay/master";
  };

  outputs = { self, darwin, nixpkgs, home-manager, emacs }: {
    darwinConfigurations = {
        patrick = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [ ./darwin-configuration.nix ]; # { pkgs = nixpkgs; home-manager = home-manager; emacs = emacs; }) ];
        };
    };
  };
}
