{pkgs, ...}: let
  mbsync = import ./mbsync.nix {inherit pkgs;};
in {
  nix.useDaemon = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget

  environment.systemPackages = [
    pkgs.alacritty
    pkgs.rustup
    pkgs.libiconv
    pkgs.clang
    pkgs.python3
  ];

  users.users.patrick = {
    home = "/Users/patrick";
    name = "patrick";
  };

  # This line is required; otherwise, on shell startup, you won't have Nix stuff in the PATH.
  programs.zsh.enable = true;
  programs.gnupg.agent.enable = true;

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";

  launchd.agents = {
    mbsync-btinternet = {
      command = "${mbsync}/bin/mbsync BTInternet > /tmp/mbsync.btinternet.log 2>/tmp/mbsync.btinternet.2.log";
      serviceConfig = {
        KeepAlive = false;
        UserName = "patrick";
        StartInterval = 60;
        RunAtLoad = true;
      };
    };

    mbsync-proton = {
      command = "${mbsync}/bin/mbsync Proton > /tmp/mbsync.proton.1.log 2>/tmp/mbsync.proton.2.log";
      serviceConfig = {
        KeepAlive = false;
        UserName = "patrick";
        StartInterval = 60;
        RunAtLoad = true;
      };
    };

    mbsync-gmail = {
      command = "${mbsync}/bin/mbsync Gmail > /tmp/mbsync.gmail.1.log 2>/tmp/mbsync.gmail.2.log";
      serviceConfig = {
        KeepAlive = false;
        UserName = "patrick";
        StartInterval = 60;
        RunAtLoad = true;
      };
    };

    backup-calendar = {
      command = ''${pkgs.bash}/bin/bash -c "mkdir -p /Users/patrick/Backups && if [ ! -d /Users/patrick/Backups/radicale ] ; then ${pkgs.git}/bin/git clone root@patrickstevens.co.uk:/preserve/radicale/data/.git /Users/patrick/Backups/radicale >/tmp/radicale.out.log 2>/tmp/radicale.err.log; fi && ${pkgs.git}/bin/git --git-dir /Users/patrick/Backups/radicale/.git pull 2>>/tmp/radicale.err.log"'';
      serviceConfig = {
        KeepAlive = false;
        UserName = "patrick";
        StartInterval = 3600;
        RunAtLoad = true;
      };
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nixVersions.stable;
  nix.gc.automatic = true;

  # Sandbox causes failure: https://github.com/NixOS/nix/issues/4119
  nix.settings.sandbox = false;

  nix.extraOptions = ''
    auto-optimise-store = true
    experimental-features = nix-command flakes
    extra-experimental-features = ca-derivations
    max-jobs = auto  # Allow building multiple derivations in parallel
    keep-outputs = true  # Do not garbage-collect build time-only dependencies (e.g. clang)
    keep-derivations = true
    # Allow fetching build results from the Lean Cachix cache
    trusted-substituters = https://lean4.cachix.org/
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= lean4.cachix.org-1:mawtxSxcaiWE24xCXXgh3qnvlTkyU7evRRnGeAhD4Wk=
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
