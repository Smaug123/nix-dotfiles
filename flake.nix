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
    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
    };
    whisper = {
      url = "github:Smaug123/whisper.cpp/nix";
    };
  };

  outputs = inputs @ {
    self,
    darwin,
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
        pkgs = import nixpkgs {inherit system config;};
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            username = "patrick";
            dotnet = pkgs.dotnet-sdk_8;
          };
          modules = let
            args = {
              nixpkgs = pkgs;
              username = "patrick";
              dotnet = pkgs.dotnet-sdk_8;
              mbsync = import ./mbsync.nix {inherit pkgs;};
              secretsPath = "/home/patrick/.secrets/";
              machinename = "capybara";
            };
          in [
            ./home-manager/capybara-config.nix
            ./nixos-modules/user-groups-exist.nix
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
        pkgs = import nixpkgs {inherit system config;};
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = let
            args = {
              nixpkgs = pkgs;
              username = "patrick";
              dotnet = pkgs.dotnet-sdk_8;
              mbsync = import ./mbsync.nix {inherit pkgs;};
              secretsPath = "/home/patrick/.secrets/";
              machinename = "earthworm";
            };
          in [
            ./home-manager/earthworm-config.nix
            ./nixos-modules/user-groups-exist.nix
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
      pkgs = import nixpkgs {
        inherit system config;
        overlays = [
          (_f: p: {
            # On aarch64-darwin the `ffmpeg-headless` binary has a broken ad-hoc
            # code signature, so the kernel SIGKILLs it on exec. yt-dlp wraps it
            # and probes ffmpeg by running it; the kill makes yt-dlp report
            # "ffmpeg is not installed" and refuse to merge formats. Wrap the
            # full (validly signed) ffmpeg instead.
            yt-dlp = p.yt-dlp.override {ffmpeg-headless = p.ffmpeg;};
          })
        ];
      };
    in {
      patrick = darwin.lib.darwinSystem {
        system = system;
        modules = let
          args = {
            nixpkgs = pkgs;
            username = "patrick";
            dotnet = pkgs.dotnet-sdk_8;
            whisper = whisper.packages.${system};
            mbsync = import ./mbsync.nix {inherit pkgs;};
            secretsPath = "/Users/patrick/.secrets/";
            machinename = "darwin";
          };
        in [
          ./darwin-configuration.nix
          {
            system.configurationRevision = self.rev or self.dirtyRev or null;
          }
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
      # Exhaustive test of ./nixos-modules/user-groups-exist.nix: one user for every
      # combination of (declared) primary group and extra groups drawn from a small universe,
      # all evaluated in a single NixOS configuration. The oracle says an extraGroups entry
      # should fail exactly when its group isn't declared. (Undeclared primary groups are
      # already rejected by NixOS itself.) The work happens at evaluation time, so this
      # is checked for every system by `nix flake check --all-systems`.
      user-groups-exist = system: let
        pkgs = import nixpkgs {inherit config system;};
        lib = nixpkgs.lib;
        # "wheel" and "users" are declared by NixOS itself; "declared" by the test config.
        declared = ["wheel" "users" "declared"];
        universe = ["wheel" "declared" "missing1" "missing2"];
        subsets = lib.foldr (x: acc: acc ++ map (s: [x] ++ s) acc) [[]] universe;
        primaries = ["users" "declared"];
        cases =
          lib.imap0 (i: c: c // {user = "u${toString i}";})
          (lib.concatMap (group: map (extraGroups: {inherit group extraGroups;}) subsets) primaries);
        eval = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nixos-modules/user-groups-exist.nix
            {
              boot.loader.grub.enable = false;
              fileSystems."/" = {
                device = "/dev/null";
                fsType = "ext4";
              };
              system.stateVersion = "25.11";
              users.groups.declared = {};
              users.users = lib.listToAttrs (map (c: {
                  name = c.user;
                  value = {
                    isNormalUser = true;
                    inherit (c) group extraGroups;
                  };
                })
                cases);
            }
          ];
        };
        failed = map (a: a.message) (lib.filter (a: !a.assertion) eval.config.assertions);
        expected = lib.concatMap (c:
          map (group: {
            inherit (c) user;
            inherit group;
          }) (lib.filter (g: !lib.elem g declared) c.extraGroups))
        cases;
        mentions = e: m: lib.hasInfix "users.users.${e.user}.extraGroups " m && lib.hasInfix "‘${e.group}’" m;
        unmatched = lib.filter (e: lib.length (lib.filter (mentions e) failed) != 1) expected;
      in
        assert lib.assertMsg (lib.length cases == 32) "expected 32 cases, got ${toString (lib.length cases)}";
        assert lib.assertMsg (unmatched == [])
        "user-groups-exist: these expected failures did not each match exactly one failed assertion: ${builtins.toJSON unmatched}\nFailed assertions were: ${builtins.toJSON failed}";
        assert lib.assertMsg (lib.length failed == lib.length expected)
        "user-groups-exist: expected ${toString (lib.length expected)} failed assertions, got ${toString (lib.length failed)}: ${builtins.toJSON failed}";
          pkgs.runCommand "user-groups-exist" {} "mkdir $out";
    in
      builtins.listToAttrs (builtins.map (system: {
          name = system;
          value = {
            fmt-check = fmt-check system;
            user-groups-exist = user-groups-exist system;
          };
        })
        systems);
    devShells = let
      devShell = system: (
        let
          pkgs = import nixpkgs {inherit config system;};
        in {
          default = pkgs.mkShell {
            buildInputs = [pkgs.alejandra pkgs.shellcheck pkgs.stylua pkgs.codex pkgs.claude-code];
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
