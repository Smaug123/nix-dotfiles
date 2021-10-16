{
  packageOverrides = pkgs: {
    gmp = pkgs.gmp.override { postInstall = ''
      echo hello
      ln -s /usr/local/opt/gmp/lib/libgmp.10.dylib $out/lib/libgmp.10.dylib
      '';
    };
  };
}
