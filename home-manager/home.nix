{
  nixpkgs,
  username,
  dotnet,
  ...
}: {
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

  fonts.fontconfig.enable = true;

  programs.tmux = {
    shell = "${nixpkgs.zsh}/bin/zsh";
    escapeTime = 50;
    mouse = false;
    prefix = "C-b";
    enable = true;
    terminal = "screen-256color";
    extraConfig = ''
      set-option -sa terminal-features ',xterm-256color:RGB'
    '';
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
      RUSTFLAGS = "-L ${nixpkgs.libiconv}/lib -L ${nixpkgs.libcxxabi}/lib -L ${nixpkgs.libcxx}/lib";
      RUST_BACKTRACE = "full";
    };
    shellAliases = {
      vim = "nvim";
      view = "vim -R";
      grep = "${nixpkgs.ripgrep}/bin/rg";
    };
    sessionVariables = {
      RIPGREP_CONFIG_PATH = "/Users/${username}/.config/ripgrep/config";
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
    delta = {enable = true;};
    extraConfig = {
      core = {
        autocrlf = "input";
      };
      rerere = {
        enabled = true;
      };
      push = {
        default = "current";
        autoSetupRemote = true;
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
      merge = {
        conflictStyle = "diff3";
      };
      diff = {
        colorMoved = "default";
      };
      "protocol.file" = {
        allow = "always";
      };
    };
  };

  programs.vscode = {
    enable = true;
    enableExtensionUpdateCheck = true;
    enableUpdateCheck = true;
    package = nixpkgs.vscode;
    extensions = import ./vscode-extensions.nix {pkgs = nixpkgs;};
    userSettings = {
      workbench.colorTheme = "Default";
      "files.Exclude" = {
        "**/.git" = true;
        "**/.DS_Store" = true;
        "**/Thumbs.db" = true;
        "**/*.olean" = true;
        "**/result" = true;
      };
      "git.path" = "${nixpkgs.git}/bin/git";
      "update.mode" = "none";
      "explorer.confirmDelete" = false;
    };
  };

  programs.neovim = let
    pythonEnv = nixpkgs.python3.withPackages (ps: [
      ps.pynvim
      ps.pynvim-pp
      ps.pyyaml
      ps.std2
    ]);
  in {
    enable = true;
    plugins = [
      nixpkgs.vimPlugins.molokai
      nixpkgs.vimPlugins.tagbar
      nixpkgs.vimPlugins.fzf-vim
      {
        plugin = nixpkgs.vimPlugins.Ionide-vim;
        config = ''
          let g:fsharp#fsautocomplete_command = ['dotnet', 'fsautocomplete', '--background-service-enabled']
          let g:fsharp#show_signature_on_cursor_move = 1
          if has('nvim') && exists('*nvim_open_win')
            augroup FSharpGroup
              autocmd!
              autocmd FileType fsharp nnoremap <leader>t :call fsharp#showTooltip()<CR>
            augroup END
          endif
        '';
      }
      {
        plugin = nixpkgs.vimPlugins.chadtree;
        config = "let g:chadtree_settings = {'xdg': v:true}";
      }
      {
        plugin = nixpkgs.vimPlugins.coq_nvim;
        config = ''let g:coq_settings = { 'auto_start': v:true, 'xdg': v:true }'';
      }
      {
        plugin = nixpkgs.vimPlugins.rust-vim;
        config = "let g:rustfmt_autosave = 1";
      }
      {
        plugin = nixpkgs.vimPlugins.LanguageClient-neovim;
        config = "let g:LanguageClient_serverCommands = { 'nix': ['rnix-lsp'] }";
      }
      {
        plugin = nixpkgs.vimPlugins.syntastic;
        config = ''          let g:syntastic_rust_checkers = ['cargo']
          let g:syntastic_always_populate_loc_list = 1
          let g:syntastic_auto_loc_list = 1
          let g:syntastic_check_on_open = 1
          let g:syntastic_check_on_wq = 0'';
      }

      nixpkgs.vimPlugins.tagbar
    ];
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = true;

    extraLuaConfig = ''vim.g.python3_host_prog="${pythonEnv}/bin/python"'';
    extraConfig = builtins.readFile ./init.vim;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "FiraCode Nerd Font Mono";
        };
      };
    };
  };

  home.packages = [
    nixpkgs.keepassxc
    nixpkgs.rust-analyzer
    nixpkgs.tmux
    nixpkgs.wget
    nixpkgs.yt-dlp
    nixpkgs.cmake
    nixpkgs.gnumake
    nixpkgs.gcc
    nixpkgs.lldb
    nixpkgs.hledger
    nixpkgs.hledger-web
    dotnet
    nixpkgs.jitsi-meet
    nixpkgs.ripgrep
    nixpkgs.elan
    nixpkgs.coreutils-prefixed
    nixpkgs.shellcheck
    nixpkgs.html-tidy
    nixpkgs.hugo
    nixpkgs.agda
    nixpkgs.pijul
    nixpkgs.universal-ctags
    nixpkgs.asciinema
    nixpkgs.git-lfs
    nixpkgs.imagemagick
    nixpkgs.nixpkgs-fmt
    nixpkgs.rnix-lsp
    nixpkgs.grpc-tools
    nixpkgs.element-desktop
    nixpkgs.ihp-new
    nixpkgs.direnv
    nixpkgs.lnav
    nixpkgs.age
    nixpkgs.nodejs
    nixpkgs.sqlitebrowser
    nixpkgs.typst
    nixpkgs.poetry
    nixpkgs.woodpecker-agent
    nixpkgs.alacritty
    nixpkgs.lynx
    nixpkgs.alejandra
    nixpkgs.ffmpeg
    nixpkgs.bat
    nixpkgs.pandoc
    (nixpkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  home.file.".mailcap".source = ./mailcap;
  home.file.".ideavimrc".source = ./ideavimrc;
  home.file.".config/yt-dlp/config".source = ./youtube-dl.conf;
  home.file.".config/ripgrep/config".source = ./ripgrep.conf;

  programs.emacs = {
    enable = true;
    package = nixpkgs.emacs;
    extraPackages = epkgs: [];
    extraConfig = ''
      (load-file (let ((coding-system-for-read 'utf-8))
                 (shell-command-to-string "agda-mode locate")))
    '';
  };

  home.file.".cargo/config.toml".source = ./cargo-config.toml;
}
