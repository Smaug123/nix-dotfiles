{
  nixpkgs,
  username,
  dotnet,
  ...
}: {
  imports = [./rider];

  rider = {
    enable = true;
    username = username;
    dotnet = dotnet;
  };

  home.packages = [
    # "Damaged and can't be opened"
    #nixpkgs.bcompare
    #nixpkgs.gdb
    #nixpkgs.handbrake
  ];

  programs.vscode = {
    userSettings = {
      "lean.leanpkgPath" = "/Users/${username}/.elan/toolchains/stable/bin/leanpkg";
      "lean.executablePath" = "/Users/${username}/.elan/toolchains/stable/bin/lean";
      "lean.memoryLimit" = 16384;
      "latex-workshop.view.pdf.viewer" = "tab";
      "lean4.toolchainPath" = "/Users/${username}/.elan/toolchains/leanprover--lean4---nightly-2022-12-16";
    };
  };

  programs.zsh = {
    shellAliases = {
      cmake = "cmake -DCMAKE_MAKE_PROGRAM=${nixpkgs.gnumake}/bin/make -DCMAKE_AR=${nixpkgs.darwin.cctools}/bin/ar -DCMAKE_RANLIB=${nixpkgs.darwin.cctools}/bin/ranlib -DGMP_INCLUDE_DIR=${nixpkgs.gmp.dev}/include/ -DGMP_LIBRARIES=${nixpkgs.gmp}/lib/libgmp.10.dylib";
      ar = "${nixpkgs.darwin.cctools}/bin/ar";
    };
  };

  home.file.".ssh/config".source = ./ssh.config;
}
