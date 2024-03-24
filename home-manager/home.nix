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
    autosuggestion.enable = true;
    enableCompletion = true;
    history = {
      expireDuplicatesFirst = true;
    };
    sessionVariables = {
      EDITOR = "vim";
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      RUSTFLAGS = "-L ${nixpkgs.libiconv}/lib -L ${nixpkgs.libcxx}/lib";
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
    initExtra = builtins.readFile ./.zshrc;
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
    pynvimpp = nixpkgs.python3.pkgs.buildPythonPackage {
      pname = "pynvim-pp";
      version = "unstable-2024-03-24";
      pyproject = true;

      src = nixpkgs.fetchFromGitHub {
        owner = "ms-jpq";
        repo = "pynvim_pp";
        rev = "34e3a027c595981886d7efd1c91071f3eaa4715d";
        hash = "sha256-2+jDRJXlg9q4MN9vOhmeq4cWVJ0wp5r5xAh3G8lqgOg=";
      };

      nativeBuildInputs = [nixpkgs.python3.pkgs.setuptools];

      propagatedBuildInputs = [nixpkgs.python3.pkgs.pynvim];
    };
  in let
    pythonEnv = nixpkgs.python3.withPackages (ps: [
      ps.pynvim
      pynvimpp
      ps.pyyaml
      ps.std2
    ]);
    debugPyEnv = nixpkgs.python3.withPackages (ps: [ps.debugpy]);
  in {
    enable = true;
    plugins = [
      {
        plugin = nixpkgs.vimPlugins.which-key-nvim;
        type = "lua";
        config = builtins.readFile ./nvim/which-key.lua;
      }
      {
        plugin = nixpkgs.vimPlugins.tokyonight-nvim;
        config = builtins.readFile ./nvim/tokyonight.lua;
        type = "lua";
      }
      {
        plugin = nixpkgs.vimPlugins.nvim-treesitter.withAllGrammars;
        config = builtins.readFile ./nvim/treesitter.lua;
        type = "lua";
      }

      {
        plugin = nixpkgs.vimPlugins.nvim-lspconfig;
        config = builtins.readFile ./nvim/lspconfig.lua;
        type = "lua";
      }
      nixpkgs.vimPlugins.telescope-nvim
      nixpkgs.vimPlugins.tagbar
      nixpkgs.vimPlugins.fzf-vim
      {
        plugin = let
          name = "coq.artifacts";
          rev = "9c5067a471322c6bb866545e88e5b28c82511865";
        in
          nixpkgs.vimUtils.buildVimPlugin {
            name = name;
            src = nixpkgs.fetchFromGitHub {
              owner = "ms-jpq";
              repo = name;
              rev = rev;
              hash = "sha256-BHm7U3pINtYamY7m26I4lQee7ccJ6AcHmYx7j1MRFDA=";
            };
          };
        config = builtins.readFile ./nvim/venv-selector.lua;
        type = "lua";
      }
      {
        plugin = let
          name = "venv-selector.nvim";
          rev = "2ad34f36d498ff5193ea10f79c87688bd5284172";
        in
          nixpkgs.vimUtils.buildVimPlugin {
            name = name;
            src = nixpkgs.fetchFromGitHub {
              owner = "linux-cultist";
              repo = name;
              rev = rev;
              hash = "sha256-aOga7kJ1y3T2vDyYFl/XHOwk35ZqeUcfPUk+Pr1mIeo=";
            };
          };
        config = builtins.readFile ./nvim/venv-selector.lua;
        type = "lua";
      }
      {
        plugin = nixpkgs.vimPlugins.Ionide-vim;
        type = "lua";
        config = builtins.readFile ./nvim/ionide-vim.lua;
      }
      {
        plugin = nixpkgs.vimPlugins.chadtree;
        config = builtins.readFile ./nvim/chadtree.vim;
      }
      {
        plugin = nixpkgs.vimPlugins.coq_nvim;
        config = ''let g:coq_settings = { 'auto_start': 'shut-up', 'xdg': v:true }'';
      }
      {
        plugin = nixpkgs.vimPlugins.rustaceanvim;
      }
      {
        plugin = nixpkgs.vimPlugins.LanguageClient-neovim;
      }
      {
        plugin = nixpkgs.vimPlugins.nvim-dap;
        config = builtins.readFile ./nvim/nvim-dap.lua;
        type = "lua";
      }
      {
        plugin = nixpkgs.vimPlugins.nvim-dap-python;
        config = builtins.replaceStrings ["%PYTHONENV%"] ["${debugPyEnv}"] (builtins.readFile ./nvim/nvim-dap-python.lua);
        type = "lua";
      }
    ];
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = true;

    extraLuaConfig = builtins.replaceStrings ["%PYTHONENV%"] ["${pythonEnv}"] (builtins.readFile ./nvim/init.lua);
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
    nixpkgs.netcoredbg
    nixpkgs.nil
    nixpkgs.fsautocomplete
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
    nixpkgs.grpc-tools
    nixpkgs.element-desktop
    nixpkgs.ihp-new
    nixpkgs.direnv
    nixpkgs.lnav
    nixpkgs.age
    nixpkgs.nodejs
    nixpkgs.nodePackages.pyright
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
    nixpkgs.fd
    nixpkgs.sumneko-lua-language-server
    (nixpkgs.nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
  ];

  home.file.".mailcap".source = ./mailcap;
  home.file.".ideavimrc".source = ./ideavimrc;
  home.file.".config/yt-dlp/config".source = ./youtube-dl.conf;
  home.file.".config/ripgrep/config".source = ./ripgrep.conf;

  programs.emacs = {
    enable = true;
    package = nixpkgs.emacs;
    extraPackages = epkgs: [epkgs.evil];
    extraConfig = ''
      (load-file (let ((coding-system-for-read 'utf-8))
                 (shell-command-to-string "agda-mode locate")))
      (require 'evil)
      (evil-mode 1)
      (evil-set-undo-system 'undo-redo)
      ;; Allow hash to be entered
      (global-set-key (kbd "M-3") '(lambda () (interactive) (insert "#")))
    '';
  };

  home.file.".cargo/config.toml".source = ./cargo-config.toml;
}
