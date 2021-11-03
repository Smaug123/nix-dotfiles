{ pkgs, config, lib, ... }:

let src = ./GlobalSettingsStorage.DotSettings; in
let link = ./link.sh; in

let riderconfig =
    pkgs.stdenv.mkDerivation {
        name = "rider-config";
        version = "2021.2";

        src = src;
        phases = [ "unpackPhase" ];
        unpackPhase = ''
        mkdir -p $out
        cp ${src} $out/GlobalSettingsStorage.DotSettings
        cp ${link} $out/link.sh
        chmod u+x $out/link.sh
        sed -i 's_NIX-DOTNET-SDK_${pkgs.dotnet-sdk}_' "$out/GlobalSettingsStorage.DotSettings"
        '';

        installPhase = ''
        '';
    };
in

{
  options = {
    rider.enable = lib.mkOption { default = false; };
    rider.username = lib.mkOption { type = lib.types.str; example = "Patrick"; };
  };

  config = lib.mkIf config.rider.enable {
    home.activation.jetbrains-rider-settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''

dest="/Users/${config.rider.username}/Library/Application Support/JetBrains"
find "$dest" -type d -maxdepth 1 -name 'Rider*' -exec sh -c '${riderconfig}/link.sh "$0"' {} \;
    '';
  };

}

#mkdir -p "$out" && touch "$out/done.txt"
