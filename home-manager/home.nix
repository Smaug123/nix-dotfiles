{
  nixpkgs,
  machinename,
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
    ./modules/ghostty.nix
    ./modules/direnv.nix
    ./modules/tmux.nix
    ./modules/zsh.nix
    ./modules/ripgrep.nix
    ./modules/rust.nix
    ./modules/posix-sh.nix
    (import ./modules/mail.nix
      {
        inherit mbsync secretsPath;
        pkgs = nixpkgs;
      })
  ];

  programs.fzf = {
    enable = true;
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };
  programs.git = {
    enable = true;
    settings = {
      alias = {
        co = "checkout";
        st = "status";
      };
      user = {
        email = "3138005+Smaug123@users.noreply.github.com";
        name = "Smaug123";
      };
      commit.gpgsign = true;
      gpg.program = "${nixpkgs.gnupg}/bin/gpg";
      user.signingkey =
        if machinename == "darwin"
        then "6D71064924BE1245"
        else if machinename == "earthworm"
        then "6E8B1BA1148AD7C9"
        else if machinename == "capybara"
        then "AE90453E879DBCFA"
        else throw "unrecognised machine name!";
      core = {
        autocrlf = "input";
      };
      rerere = {
        enabled = true;
      };
      push = {
        default = "current";
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        all = true;
      };
      help = {
        autocorrect = "prompt";
      };
      pull = {
        rebase = false;
        twohead = "ort";
      };
      init = {
        defaultBranch = "main";
      };
      branch = {
        sort = "-committerdate";
      };
      column = {
        ui = "auto";
      };
      tag = {
        sort = "version:refname";
      };
      advice = {
        addIgnoredFile = false;
      };
      "filter \"lfs\"" = {
        clean = "${nixpkgs.git-lfs}/bin/git-lfs clean -- %f";
        smudge = "${nixpkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
        process = "${nixpkgs.git-lfs}/bin/git-lfs filter-process";
        required = true;
      };
      merge = {
        conflictStyle = "diff3";
      };
      diff = {
        colorMoved = "default";
        algorithm = "histogram";
        renames = true;
      };
      "protocol.file" = {
        allow = "always";
      };
      url."git@github.com:" = {
        insteadOf = "https://github.com/";
      };
    };
  };

  programs.vscode = {
    enable = true;
    package = nixpkgs.vscode;
    profiles.default = {
      extensions = import ./vscode-extensions.nix {pkgs = nixpkgs;};
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = true;
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
  };

  services.syncthing = {
    enable = true;
  };

  programs.neovim = let
    debugPyEnv = nixpkgs.python3.withPackages (ps: [ps.debugpy]);
    codelldb = nixpkgs.vscode-extensions.vadimcn.vscode-lldb;
    codelldbPath = "${codelldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
    liblldbPath = "${codelldb}/share/vscode/extensions/vadimcn.vscode-lldb/lldb/lib/liblldb.${
      if nixpkgs.stdenv.isDarwin
      then "dylib"
      else "so"
    }";
  in {
    enable = true;
    plugins = [
      {
        plugin = nixpkgs.vimPlugins.nvim-web-devicons;
      }
      {
        plugin = nixpkgs.vimPlugins.mini-nvim;
      }
      {
        plugin = nixpkgs.vimPlugins.satellite-nvim;
      }
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
        plugin = nixpkgs.vimPlugins.rustaceanvim;
        config = builtins.replaceStrings ["%CODELLDB_PATH%" "%LIBLLDB_PATH%"] [codelldbPath liblldbPath] (builtins.readFile ./nvim/rustaceanvim.lua);
        type = "lua";
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
      ps.pip
      ps.pynvim
      ps.pynvim-pp
      ps.pyyaml
      ps.std2
    ];
    withRuby = true;

    initLua = builtins.readFile ./nvim/build-utils.lua + "\n" + (builtins.replaceStrings ["_CURL_"] ["${nixpkgs.curl}/bin/curl"] (builtins.readFile ./nvim/dotnet.lua)) + "\n" + builtins.readFile ./nvim/init.lua + "\n" + builtins.readFile ./nvim/python.lua;
  };

  home.packages =
    [
      nixpkgs.jq
      nixpkgs.difftastic
      nixpkgs.syncthing
      nixpkgs.dockerfile-language-server
      nixpkgs.nodePackages_latest.vscode-langservers-extracted
      nixpkgs.hadolint
      nixpkgs.yaml-language-server
      nixpkgs.netcoredbg
      nixpkgs.nil
      nixpkgs.fsautocomplete
      nixpkgs.wget
      nixpkgs.yt-dlp
      nixpkgs.lldb
      nixpkgs.hledger
      nixpkgs.hledger-web
      dotnet
      nixpkgs.elan
      nixpkgs.coreutils-prefixed
      nixpkgs.asciinema
      nixpkgs.git-lfs
      nixpkgs.imagemagick
      nixpkgs.nixpkgs-fmt
      nixpkgs.age
      nixpkgs.pyright
      nixpkgs.woodpecker-agent
      nixpkgs.lynx
      nixpkgs.ffmpeg
      nixpkgs.bat
      nixpkgs.pandoc
      nixpkgs.fd
      nixpkgs.lua-language-server
      nixpkgs.gnupg
      nixpkgs.gh
      nixpkgs.clang-tools
      nixpkgs.deno
      nixpkgs.yazi
      nixpkgs.font-awesome
      nixpkgs.gopls
      nixpkgs.go
      nixpkgs.libiconv
      nixpkgs.claude-code
      nixpkgs.uv
    ]
    ++ (
      if nixpkgs.stdenv.isLinux
      then [
        nixpkgs.protonmail-bridge
        nixpkgs.pinentry-curses
        nixpkgs.signal-desktop
        nixpkgs.keepassxc
      ]
      else []
    )
    ++ (
      if machinename == "capybara"
      then [
        nixpkgs.steam-run
        nixpkgs.discord-canary
        nixpkgs.anki-bin
      ]
      else []
    );

  home.file.".ideavimrc".source = ./ideavimrc;
  home.file.".config/yt-dlp/config".source = ./youtube-dl.conf;
}
