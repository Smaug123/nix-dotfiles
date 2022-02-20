{
  nixpkgs,
  ...
}:
let
  username = "Patrick";
in let
  dotnet = nixpkgs.dotnet-sdk_6;
in {
  imports = [./rider];

  rider = {
    enable = true;
    username = username;
    dotnet = dotnet;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = username;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  home.packages =
    [
      nixpkgs.rust-analyzer
      nixpkgs.tmux
      nixpkgs.wget
      nixpkgs.youtube-dl
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
    package = nixpkgs.vscode;
    extensions = import ./vscode-extensions.nix { pkgs = nixpkgs; };
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
      #"lean.leanpkgPath" = "/Users/${username}/.elan/toolchains/stable/bin/leanpkg";
      "lean.executablePath" = "/Users/${username}/.elan/toolchains/lean4/bin/lean";
      "lean.memoryLimit" = 8092;
    };
  };

  programs.tmux = {
    shell = "\${nixpkgs.zsh}/bin/zsh";
  };

  programs.zsh = {
    enable = true;
    autocd = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    history = {
      expireDuplicatesFirst = true;
    };
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "macos" "dircycle" "timer"];
      theme = "robbyrussell";
    };
    sessionVariables = {
      EDITOR = "vim";
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      RUSTFLAGS = "-L ${nixpkgs.libiconv}/lib";
      RUST_BACKTRACE = "full";
    };
    shellAliases = {
      vim = "nvim";
      view = "vim -R";
      nix-upgrade = "sudo -i sh -c 'nix-channel --update && nix-env -iA nixpkgs.nix && launchctl remove org.nixos.nix-daemon && launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist'";
      cmake = "cmake -DCMAKE_MAKE_PROGRAM=${nixpkgs.gnumake}/bin/make -DCMAKE_AR=${nixpkgs.darwin.cctools}/bin/ar -DCMAKE_RANLIB=${nixpkgs.darwin.cctools}/bin/ranlib -DGMP_INCLUDE_DIR=${nixpkgs.gmp.dev}/include/ -DGMP_LIBRARIES=${nixpkgs.gmp}/lib/libgmp.10.dylib";
      ar = "${nixpkgs.darwin.cctools}/bin/ar";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    package = nixpkgs.gitAndTools.gitFull;
    enable = true;
    userName = "Smaug123";
    userEmail = "patrick+github@patrickstevens.co.uk";
    aliases = {
      co = "checkout";
      st = "status";
    };
    extraConfig = {
      rerere = {
        enabled = true;
      };
      push = {
        default = "current";
      };
      pull = {
        rebase = false;
      };
      init = {
        defaultBranch = "main";
      };
      advice = {
        addIgnoredFile = false;
      };
      "filter \"lfs\"" = {
        clean = "${nixpkgs.git-lfs} clean -- %f";
        smudge = "${nixpkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
        process = "${nixpkgs.git-lfs}/bin/git-lfs filter-process";
        required = true;
      };
      pull = {
        twohead = "ort";
      };
    };
  };

  programs.neovim.enable = true;
  programs.neovim.plugins = with nixpkgs.vimPlugins; [
    molokai
    tagbar
    {
      plugin = rust-vim;
      config = "let g:rustfmt_autosave = 1";
    }
    {
      plugin = LanguageClient-neovim;
      config = "let g:LanguageClient_serverCommands = { 'nix': ['rnix-lsp'] }";
    }
    {
      plugin = syntastic;
      config = ''        let g:syntastic_rust_checkers = ['cargo']
        let g:syntastic_always_populate_loc_list = 1
        let g:syntastic_auto_loc_list = 1
        let g:syntastic_check_on_open = 1
        let g:syntastic_check_on_wq = 0'';
    }

    YouCompleteMe
    tagbar
  ];
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;
  programs.neovim.withPython3 = true;

  programs.neovim.extraConfig = builtins.readFile ./init.vim;

  home.file.".ssh/config".source = ./ssh.config;

  home.file.".ideavimrc".source = ./ideavimrc;

  home.file.".config/youtube-dl/config".source = ./youtube-dl.conf;
  programs.emacs = {
    enable = true;
    package = nixpkgs.emacsGcc;
    extraPackages = (epkgs: []);
    extraConfig = ''
      (load-file (let ((coding-system-for-read 'utf-8))
                 (shell-command-to-string "agda-mode locate")))
    '';
  };
}
