{
  pkgs,
  config,
  lib,
  ...
}: let
  src = ./GlobalSettingsStorage.DotSettings;
in let
  link = ./link.sh;
in let
  riderconfig = pkgs.stdenv.mkDerivation {
    name = "rider-config";
    version = "2023.1";
    __contentAddressed = true;

    src = src;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p "$out"
      cp ${src} "$out/GlobalSettingsStorage.DotSettings"
      cp ${link} "$out/link.sh"
      chmod u+x "$out/link.sh"
      sed -i 's_NIX-DOTNET-SDK_${config.rider.dotnet}_' "$out/GlobalSettingsStorage.DotSettings"
      sed -i "s!NIX-RIDER-CONFIG!$out!" "$out/link.sh"
    '';

    installPhase = ''
    '';
  };
in {
  options = {
    rider.enable = lib.mkOption {default = false;};
    rider.username = lib.mkOption {
      type = lib.types.str;
      example = "Patrick";
    };
    rider.dotnet = lib.mkOption {default = pkgs.dotnet-sdk;};
  };

  config = lib.mkIf config.rider.enable {
    home.activation.jetbrains-rider-settings = lib.hm.dag.entryAfter ["writeBoundary"] ''

      dest="/Users/${config.rider.username}/Library/Application Support/JetBrains"
      if [ -e "$dest" ]; then
        find "$dest" -maxdepth 1 -type d -name 'Rider*' -exec sh -c '${riderconfig}/link.sh "$0"' {} \;
      fi
    '';
  };
}
