{
  nixpkgs,
  username,
  ...
}: let
  dotnet = nixpkgs.dotnet-sdk_6;
in {
  imports = [./rider];

  rider = {
    enable = true;
    username = username;
    dotnet = dotnet;
  };

  home.packages = [
    # Broken on Apple Silicon
    #nixpkgs.keepassxc
    nixpkgs.rust-analyzer
    nixpkgs.tmux
    nixpkgs.wget
    nixpkgs.youtube-dl
    nixpkgs.yt-dlp
    nixpkgs.cmake
    nixpkgs.gnumake
    nixpkgs.gcc
    nixpkgs.gdb
    nixpkgs.hledger
    nixpkgs.hledger-web
    dotnet
    nixpkgs.docker
    nixpkgs.jitsi-meet
    #nixpkgs.handbrake
    nixpkgs.ripgrep
    nixpkgs.elan
    nixpkgs.coreutils-prefixed
    nixpkgs.shellcheck
    nixpkgs.html-tidy
    nixpkgs.hugo
    #nixpkgs.agda
    nixpkgs.pijul
    nixpkgs.universal-ctags
    nixpkgs.asciinema
    nixpkgs.git-lfs
    nixpkgs.imagemagick
    nixpkgs.nixpkgs-fmt
    nixpkgs.rnix-lsp
  ];

  programs.vscode = {
    enable = true;
    package = nixpkgs.vscodium;
    extensions = import ./vscode-extensions.nix {pkgs = nixpkgs;};
    userSettings = {
      workbench.colorTheme = "Default High Contrast";
      "files.Exclude" = {
        "**/.git" = true;
        "**/.DS_Store" = true;
        "**/Thumbs.db" = true;
        "**/*.olean" = true;
        "**/result" = true;
      };
      "git.path" = "${nixpkgs.git}/bin/git";
      "update.mode" = "none";
      "docker.dockerPath" = "${nixpkgs.docker}/bin/docker";
      "lean.leanpkgPath" = "/Users/${username}/.elan/toolchains/stable/bin/leanpkg";
      "lean.executablePath" = "/Users/${username}/.elan/toolchains/stable/bin/lean";
      #"lean.executablePath" = "/Users/${username}/.elan/toolchains/lean4/bin/lean";
      "explorer.confirmDelete" = false;
      "lean.memoryLimit" = 16384;
      "latex-workshop.view.pdf.viewer" = "tab";
    };
  };

  programs.zsh = {
    shellAliases = {
      cmake = "cmake -DCMAKE_MAKE_PROGRAM=${nixpkgs.gnumake}/bin/make -DCMAKE_AR=${nixpkgs.darwin.cctools}/bin/ar -DCMAKE_RANLIB=${nixpkgs.darwin.cctools}/bin/ranlib -DGMP_INCLUDE_DIR=${nixpkgs.gmp.dev}/include/ -DGMP_LIBRARIES=${nixpkgs.gmp}/lib/libgmp.10.dylib";
      ar = "${nixpkgs.darwin.cctools}/bin/ar";
    };
  };

  home.file.".ssh/config".source = ./ssh.config;

  home.file.".ideavimrc".source = ./ideavimrc;

  home.file.".config/youtube-dl/config".source = ./youtube-dl.conf;
  home.file.".config/yt-dlp/config".source = ./youtube-dl.conf;
  programs.emacs = {
    enable = true;
    package = nixpkgs.emacsNativeComp;
    extraPackages = epkgs: [];
    extraConfig = ''
      (load-file (let ((coding-system-for-read 'utf-8))
                 (shell-command-to-string "agda-mode locate")))
    '';
  };
}