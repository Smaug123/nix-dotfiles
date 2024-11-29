{pkgs, ...}: {
  imports = [
    ../hardware/earthworm.nix
  ];

  hardware.asahi.peripheralFirmwareDirectory = ./../firmware;
  hardware.asahi = {
    useExperimentalGPUDriver = true;
    experimentalGPUInstallMode = "overlay";
    setupAsahiSound = true;
    withRust = true;
  };
  hardware.graphics.enable = true;

  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      {
        keys = [225];
        events = ["key"];
        command = "${pkgs.light}/bin/light -A 10";
      }
      {
        keys = [224];
        events = ["key"];
        command = "${pkgs.light}/bin/light -U 10";
      }
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=0
  '';

  networking = {
    hostName = "earthworm";
    networkmanager.enable = true;
    wireless.iwd = {
      enable = true;
      settings.General.EnableNetworkConfiguration = true;
    };
  };

  time.timeZone = "Europe/London";

  programs.sway.enable = true;
  programs.zsh.enable = true;

  # TODO: work out secrets management for password, then set mutableUsers to false
  users.mutableUsers = true;
  users.users.patrick = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkManager"];
  };

  environment.systemPackages = [
    pkgs.vim
    pkgs.wget
    pkgs.mesa-asahi-edge
  ];

  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && export WLR_RENDER_NO_EXPLICIT_SYNC=1 && sway
  '';

  services.openssh.enable = true;

  system.stateVersion = "23.11";
  nix.settings.experimental-features = ["nix-command" "flakes" "ca-derivations"];

  nix.gc.automatic = true;
  nix.extraOptions = ''
    auto-optimise-store = true
    max-jobs = auto
    keep-outputs = true
    keep-derivations = true
  '';
}
