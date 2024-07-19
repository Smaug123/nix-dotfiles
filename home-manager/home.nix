{
  nixpkgs,
  username,
  mbsync,
  dotnet,
  secretsPath,
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

  imports = [
    # ./modules/agda.nix
    # ./modules/emacs.nix
    ./modules/direnv.nix
    ./modules/tmux.nix
    ./modules/zsh.nix
    ./modules/ripgrep.nix
    ./modules/alacritty.nix
    ./modules/rust.nix
    (import ./modules/mail.nix
      {
        inherit mbsync secretsPath;
        pkgs = nixpkgs;
      })
  ];

  programs.fzf = {
    enable = true;
  };

  programs.git = {
    package = nixpkgs.gitAndTools.gitFull;
    enable = true;
    userName = "Smaug123";
    userEmail = "3138005+Smaug123@users.noreply.github.com";
    aliases = {
      co = "checkout";
      st = "status";
    };
    difftastic.enable = true;
    extraConfig = {
      commit.gpgsign = true;
      gpg.program = "${nixpkgs.gnupg}/bin/gpg";
      user.signingkey = "7C97D679CF3BC4F9";
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

  services.syncthing = {
    enable = true;
  };

  programs.neovim = let
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
    extraPython3Packages = ps: [
      ps.pynvim
      ps.pynvim-pp
      ps.pyyaml
      ps.std2
    ];
    withRuby = true;

    extraLuaConfig = builtins.readFile ./nvim/build-utils.lua + "\n" + (builtins.replaceStrings ["_CURL_"] ["${nixpkgs.curl}/bin/curl"] (builtins.readFile ./nvim/dotnet.lua)) + "\n" + builtins.readFile ./nvim/init.lua + "\n" + builtins.readFile ./nvim/python.lua;
  };

  home.packages = [
    nixpkgs.difftastic
    nixpkgs.syncthing
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
    nixpkgs.elan
    nixpkgs.coreutils-prefixed
    nixpkgs.shellcheck
    nixpkgs.universal-ctags
    nixpkgs.asciinema
    nixpkgs.git-lfs
    nixpkgs.imagemagick
    nixpkgs.nixpkgs-fmt
    nixpkgs.lnav
    nixpkgs.age
    nixpkgs.nodejs
    nixpkgs.pyright
    nixpkgs.woodpecker-agent
    nixpkgs.lynx
    nixpkgs.alejandra
    nixpkgs.ffmpeg
    nixpkgs.bat
    nixpkgs.pandoc
    nixpkgs.fd
    nixpkgs.sumneko-lua-language-server
    nixpkgs.gnupg
    nixpkgs.gh
    nixpkgs.clang-tools
  ];

  home.file.".ideavimrc".source = ./ideavimrc;
  home.file.".config/yt-dlp/config".source = ./youtube-dl.conf;
}
