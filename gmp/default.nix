{ pkgs, config, lib, ... }:


let link = ./link.sh; in
let gmp-symlink =
    pkgs.stdenv.mkDerivation {

        name = "gmp-symlink";
        src = ./link.sh;
        phases = [ "unpackPhase" ];
        unpackPhase = ''
        mkdir -p "$out"
        cp ${link} "$out/link.sh"
        chmod u+x "$out/link.sh"
        sed -i 's_NIX-GMP_${config.gmp-symlink.gmp}_' "$out/link.sh"
        '';

        installPhase = ''
        '';
    };
in

{
  options = {
    gmp-symlink.enable = lib.mkOption { default = false; };
    gmp-symlink.gmp = lib.mkOption { default = pkgs.gmp; };
  };

  config = lib.mkIf config.gmp-symlink.enable {
    home.activation.gmp-symlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
${gmp-symlink}/link.sh
    '';
  };

}

