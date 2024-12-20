{
  pkgs,
  config,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  imports = [
    ../hardware/capybara.nix
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;

  boot.kernelParams = [
    "video=DP-1:2560x1440@144"
    "video=HDMI-A-1:1920x1080@144"
  ];

  boot.extraModulePackages = [config.boot.kernelPackages.rtl8821au];

  networking = {
    hostName = "capybara";
    networkmanager.enable = true;
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

  services.syncthing = {
    enable = true;
    user = "patrick";
    dataDir = "/home/patrick/syncthing";
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.vim
    pkgs.wget
    pkgs.tmux
    pkgs.home-manager
    pkgs.firefox
  ];

  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway --unsupported-gpu
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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
}
