{pkgs}: let
  my-python-packages = python-packages:
    with python-packages; [
      pip
      mathlibtools
    ];
in let
  packageOverrides = self: super: {
    # Test failures on darwin ("windows-1252"); just skip pytest
    # (required for elan)
    beautifulsoup4 = super.beautifulsoup4.overridePythonAttrs (old: {pytestCheckPhase = "true";});
  };
in
  (pkgs.python3.override {inherit packageOverrides;}).withPackages my-python-packages
