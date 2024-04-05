{
  description = "Patrick's Darwin Nix setup";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      # url = "github:Smaug123/nix-darwin/extract";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
    };
    whisper = {
      url = "github:Smaug123/whisper.cpp/nix";
    };
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    neovim-nightly,
    darwin,
    emacs,
    nixpkgs,
    home-manager,
    apple-silicon,
    whisper,
    ...
  }: let
    config = {
      # contentAddressedByDefault = true;
      allowUnfree = true;
    };
    systems = ["aarch64-darwin" "aarch64-linux" "x86_64-linux"];
  in let
    overlays = [emacs.overlay neovim-nightly.overlay];
    recursiveMerge = attrList: let
      f = attrPath:
        builtins.zipAttrsWith (n: values:
          if builtins.tail values == []
          then builtins.head values
          else if builtins.all builtins.isList values
          then nixpkgs.lib.unique (builtins.concatLists values)
          else if builtins.all builtins.isAttrs values
          then f (attrPath ++ [n]) values
          else builtins.last values);
    in
      f [] attrList;
  in {
    nixosConfigurations = {
      capybara = let
        system = "x86_64-linux";
      in let
        pkgs = import nixpkgs {inherit system config overlays;};
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = let
            args = {
              nixpkgs = pkgs;
              username = "patrick";
              dotnet = pkgs.dotnet-sdk_8;
              mbsync = import ./mbsync.nix {inherit pkgs;};
            };
          in [
            ./home-manager/capybara-config.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.patrick = recursiveMerge [(import ./home-manager/linux.nix args) (import ./home-manager/home.nix args)];
            }
          ];
        };
      earthworm = let
        system = "aarch64-linux";
      in let
        pkgs = import nixpkgs {inherit system config overlays;};
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = let
            args = {
              nixpkgs = pkgs;
              username = "patrick";
              dotnet = pkgs.dotnet-sdk_8;
              mbsync = import ./mbsync.nix {inherit pkgs;};
            };
          in [
            ./home-manager/earthworm-config.nix
            apple-silicon.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.patrick = recursiveMerge [(import ./home-manager/linux.nix args) (import ./home-manager/home.nix args)];
            }
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
            username = "patrick";
            dotnet = pkgs.dotnet-sdk_8;
            whisper = whisper.packages.${system};
            mbsync = import ./mbsync.nix {inherit pkgs;};
          };
        in [
          ./darwin-configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.patrick = recursiveMerge [(import ./home-manager/darwin.nix args) (import ./home-manager/home.nix args)];
          }
        ];
      };
    };
    checks = let
      fmt-check = system: let
        pkgs = import nixpkgs {inherit config system;};
      in
        pkgs.stdenvNoCC.mkDerivation {
          name = "fmt-check";
          src = ./.;
          nativeBuildInputs = [pkgs.alejandra pkgs.shellcheck pkgs.shfmt pkgs.stylua];
          checkPhase = ''
            find . -type f -name '*.sh' | xargs shfmt -d -s -i 2 -ci
            alejandra -c .
            find . -type f -name '*.sh' -exec shellcheck -x {} \;
            find . -type f -name '*.lua' -exec stylua --check {} \;
          '';
          installPhase = "mkdir $out";
          dontBuild = true;
          doCheck = true;
        };
    in
      builtins.listToAttrs (builtins.map (system: {
          name = system;
          value = {fmt-check = fmt-check system;};
        })
        systems);
    devShells = let
      devShell = system: (
        let
          pkgs = import nixpkgs {inherit config system;};
        in {
          default = pkgs.mkShell {
            buildInputs = [pkgs.alejandra pkgs.shellcheck pkgs.stylua];
          };
        }
      );
    in
      builtins.listToAttrs (builtins.map (system: {
          name = system;
          value = devShell system;
        })
        systems);
  };
}
