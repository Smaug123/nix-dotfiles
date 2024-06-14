{pkgs}:
pkgs.buildEnv {
  name = "isync-oauth2";
  paths = [pkgs.isync];
  pathsToLink = ["/bin"];
  nativeBuildInputs = [pkgs.makeWrapper];
  postBuild = ''
    wrapProgram "$out/bin/mbsync" \
      --prefix SASL_PATH : "${pkgs.cyrus_sasl}/lib/sasl2:${pkgs.cyrus-sasl-xoauth2}/lib/sasl2"
  '';
}
