{pkgs, ...}: {
  imports = [
    ../hardware/earthworm.nix
  ];

  # hardware.asahi.peripheralFirmwareDirectory = "/etc/nixos/firmware";
  hardware.asahi =
  {
      extractPeripheralFirmware = false;
      useExperimentalGPUDriver = true;
      experimentalGPUInstallMode = "driver";
      setupAsahiSound = true;
      withRust = true;
  };
  hardware.graphics.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=0
  '';

  networking = {
    hostName = "earthworm";
    networkmanager.enable = true;
    wireless.iwd = { enable = true; settings.General.EnableNetworkConfiguration = true; };
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
    [[ "$(tty)" == /dev/tty1 ]] && sway
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
