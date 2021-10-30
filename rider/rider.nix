{ pkgs ? import <nixpkgs> {}, username }:

let src = ./GlobalSettingsStorage.DotSettings; in

let riderconfig =
    pkgs.stdenv.mkDerivation {
        name = "rider-config";
        version = "2021.2";

        src = src;
        phases = [ "unpackPhase" ];
        unpackPhase = ''
        mkdir -p $out
        cp ${src} $out/GlobalSettingsStorage.DotSettings
        sed -i 's_NIX-DOTNET-SDK_${pkgs.dotnet-sdk}_' "$out/GlobalSettingsStorage.DotSettings"
        '';

        installPhase = ''
        '';
    };
in

pkgs.runCommandLocal "rider-config" {} ''
function go {
  outfile="$1/resharper-host/GlobalSettingsStorage.DotSettings"
    echo "$outfile"
  if [ -e "$outfile" ]; then
    existing=$(readlink "$outfile")
    if [ $? -eq 1 ] ; then
      echo "Backing up existing settings file $outfile"
      mv "$outfile" "$outfile.bak"
      ln -s "${riderconfig}/GlobalSettingsStorage.DotSettings" "$outfile"
    else
      if [[ "$existing" == /nix/store/* ]]; then
        ln -fs "${riderconfig}/GlobalSettingsStorage.DotSettings" "$outfile"
      else
        echo "Refusing to overwrite existing symlink to $existing"
        exit 1
      fi
    fi
  else
    ln -s "${riderconfig}/GlobalSettingsStorage.DotSettings" "$outfile"
  fi
}
export -f go

whoami

dest="/Users/${username}/Library/Application Support/JetBrains"
echo "$dest"
find "$dest" -type d -maxdepth 1 -name 'Rider*' -exec sh -c 'go "$0"' {} \;

mkdir -p "$out" && touch "$out/done.txt"
''


#pkgs.writeTextFile {
#    name = "rider-config";
#    text = ./GlobalSettingsStorage.DotSettings;
#    destination = "/Users/${username}/Library/ApplicationSupport/JetBrains/Rider2021.2/resharper-host/GlobalSettingsStorage.DotSettings";
#}
