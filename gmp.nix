{ pkgs ? import <nixpkgs> {} }:

# If this fails, `chmod -R a+rw /usr/local/opt/gmp/lib`
pkgs.stdenv.mkDerivation {
    name = "gmp-symlink";
    builder = "${pkgs.bash}/bin/bash";
    args = ["-c" "${pkgs.coreutils}/bin/mkdir -p $out && ${pkgs.coreutils}/bin/touch $out/gmp-symlink"];
    system = "x86_64-darwin";
    postInstall =
    ''
    ${pkgs.coreutils}/bin/echo "hi!"
    ${pkgs.coreutils}/bin/ln -s ${pkgs.gmp}/lib/libgmp.10.dylib /usr/local/opt/gmp/lib/libgmp.10.dylib
    '';
}
