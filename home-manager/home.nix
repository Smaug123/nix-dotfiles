{
  nixpkgs,
  username,
  mbsync,
  dotnet,
  secretsPath,
  ...
}: let
  deobfuscate = str: let
    lib = nixpkgs.lib;
    base64Table =
      builtins.listToAttrs
      (lib.imap0 (i: c: lib.nameValuePair c i)
        (lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"));

    # Generated using python3:
    # print(''.join([ chr(n) for n in range(1, 256) ]), file=open('ascii', 'w'))
    ascii = builtins.readFile ./ascii;

    # List of base-64 numbers
    numbers64 = map (c: base64Table.${c}) (lib.lists.reverseList (lib.stringToCharacters str));

    # List of base-256 numbers
    numbers256 = lib.concatLists (lib.genList (
      i: let
        v =
          lib.foldl'
          (acc: el: acc * 64 + el)
          0
          (lib.sublist (i * 4) 4 numbers64);
      in [
        (lib.mod (v / 256 / 256) 256)
        (lib.mod (v / 256) 256)
        (lib.mod v 256)
      ]
    ) (lib.length numbers64 / 4));
  in
    # Converts base-256 numbers to ascii
    lib.concatMapStrings (
      n:
      # Can't represent the null byte in Nix..
      let
        result = lib.substring (n - 1) 1 ascii;
      in
        if result == " "
        then ""
        else result
    )
    numbers256;
in {
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
      RIPGREP_CONFIG_PATH = ./ripgrep.conf;
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
        plugin = nixpkgs.vimPlugins.nvim-lightbulb;
        type = "lua";
        config = builtins.readFile ./nvim/nvim-lightbulb.lua;
      }
      {
        plugin = nixpkgs.vimPlugins.lean-nvim;
        type = "lua";
        config = builtins.readFile ./nvim/lean.lua;
      }
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
        plugin = nixpkgs.vimPlugins.roslyn-nvim;
        config = builtins.readFile ./nvim/roslyn-nvim.lua;
        type = "lua";
      }
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
        config = builtins.readFile ./nvim/chadtree.lua;
        type = "lua";
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
    withRuby = true;

    extraLuaConfig = builtins.readFile ./nvim/build-utils.lua + "\n" + builtins.readFile ./nvim/dotnet.lua + "\n" + builtins.replaceStrings ["%PYTHONENV%"] ["${pythonEnv}"] (builtins.readFile ./nvim/init.lua) + "\n" + builtins.readFile ./nvim/python.lua;

    package = nixpkgs.neovim-nightly;
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
    nixpkgs.notmuch
    nixpkgs.nodePackages_latest.dockerfile-language-server-nodejs
    nixpkgs.nodePackages_latest.bash-language-server
    nixpkgs.nodePackages_latest.vscode-json-languageserver
    nixpkgs.nodePackages_latest.vscode-langservers-extracted
    nixpkgs.hadolint
    nixpkgs.ltex-ls
    nixpkgs.yaml-language-server
    nixpkgs.csharp-ls
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

  accounts.email.accounts."Gmail" = let
    address = (deobfuscate "AFTN0cWdh12c") + "gmail.com";
  in {
    notmuch.enable = true;
    neomutt = {
      enable = true;
    };
    address = address;
    flavor = "gmail.com";
    mbsync = {
      enable = true;
      create = "maildir";
      extraConfig.account = {
        AuthMechs = "XOAUTH2";
      };
    };
    userName = address;
    # This is accompanied by a developer application at Google:
    # https://console.cloud.google.com/apis/credentials
    # Create an OAuth 2.0 Client ID with type `Desktop`.
    # The Google application needs the https://mail.google.com scope; mine has
    # an authorized domain `google.com` but I don't know if that's required.
    # Enter the client ID and client secret into a two-line text file
    # named gmail-client-app.txt immediately next to the intended destination
    # secret file (the arg to mutt-oauth2.py in the invocation):
    # so here it would be /path/to/gmail-client-app.txt .
    # Run `./mail/mutt-oauth2.py /path/to/secret --authorize --verbose` once manually,
    # and that will populate /path/to/secret.
    # I've left it unencrypted here; the original uses GPG to store it encrypted at rest.
    passwordCommand = ''${nixpkgs.python3}/bin/python ${./mail/mutt-oauth2.py} ${secretsPath}/gmail.txt'';
    realName = "Patrick Stevens";
  };

  accounts.email.accounts."BTInternet" = let
    address = (deobfuscate "z5WZ2VGdz5yajlmc0FGc") + "@btinternet.com";
  in {
    notmuch.enable = true;
    neomutt = {
      enable = true;
    };
    address = address;
    imap = {
      host = "mail.btinternet.com";
      port = 993;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };
    mbsync = {
      enable = true;
      create = "maildir";
    };
    realName = "Patrick Stevens";
    passwordCommand = "cat ${secretsPath}/btinternet.txt";
    smtp = {
      host = "mail.btinternet.com";
      port = 465;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };
    userName = address;
    primary = true;
  };

  accounts.email.accounts."Proton" = let
    address = deobfuscate "gAya15ybj5ycuVmdlR3crNWayRXYwB0ajlmc0FGc";
  in {
    notmuch.enable = true;
    neomutt = {
      enable = true;
    };
    address = address;
    # I use the ProtonMail bridge, which sits at localhost.
    imap = {
      host = "127.0.0.1";
      port = 1143; # 8125; if using hydroxide
      tls = {
        enable = false;
        useStartTls = true;
      };
    };
    mbsync = {
      enable = true;
      create = "maildir";
      extraConfig.account = {
        # Because ProtonMail Bridge is localhost, we don't
        # care that we can only auth to it in plain text.
        AuthMechs = "LOGIN";
      };
    };
    realName = "Patrick Stevens";
    passwordCommand =
      # I store the ProtonMail Bridge password here.
      # Extracting it from a keychain would be better.
      "cat ${secretsPath}/proton.txt";
    smtp = {
      host = "127.0.0.1";
      port = 1025; # 8126; if using hydroxide
      tls = {enable = false;};
    };
    userName = address;
  };

  programs.mbsync = {
    enable = true;
    extraConfig = ''
      CopyArrivalDate yes
    '';
    package = mbsync;
  };
  programs.neomutt = {
    enable = true;
    extraConfig = ''
      set use_threads=threads sort=last-date sort_aux=date
    '';
    sidebar.enable = true;
    vimKeys = true;
  };

  programs.notmuch.enable = true;

  home.file.".mailcap".source = ./mail/mailcap;
  home.file.".ideavimrc".source = ./ideavimrc;
  home.file.".config/yt-dlp/config".source = ./youtube-dl.conf;
  # Not actually used, but if I ever need to debug it'll be easier
  # if I can see what the current state of the world is by looking in .config
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
      (global set-key (kbd "M-3") '(lambda () (interactive) (insert "#")))
    '';
  };

  home.file.".cargo/config.toml".source = ./cargo-config.toml;
}
