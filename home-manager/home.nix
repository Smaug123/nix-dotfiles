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

  programs.tmux = {
    shell = "\${nixpkgs.zsh}/bin/zsh";
    escapeTime = 50;
    mouse = false;
    prefix = "C-b";
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

  programs.neovim.enable = true;
  programs.neovim.plugins = with nixpkgs.vimPlugins; [
    molokai
    tagbar
    fzf-vim
    Ionide-vim
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

    # YouCompleteMe
    tagbar
  ];
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;
  programs.neovim.withPython3 = true;

  programs.neovim.extraConfig = builtins.readFile ./init.vim;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
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

  programs.firefox = {
    enable = true;
    profiles = {
      patrick = {
        isDefault = true;
        name = "patrick";
        search = {default = "Google";};
        settings = {
          # see https://github.com/TLATER/dotfiles/blob/b39af91fbd13d338559a05d69f56c5a97f8c905d/home-config/config/graphical-applications/firefox.nix
          # see https://www.ghacks.net/2015/08/18/a-comprehensive-list-of-firefox-privacy-and-security-settings/
          "browser.search.isUS" = false;
          "browser.search.region" = "GB";
          "gfx.webrender.all" = true; # enable GPU acceleration
          "media.ffmpeg.vaapi.enabled" = true;
          "widget.dmabuf.force-enabled" = true;
          "privacy.webrtc.legacyGlobalIndicator" = false;
          "app.shield.optoutstudies.enabled" = false;
          "app.update.enabled" = false;
          "app.update.auto" = false;
          "app.update.silent" = false;
          "app.update.service.enabled" = false;
          "app.update.staging.enabled" = false;
          "browser.discovery.enabled" = false;
          "browser.laterrun.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.rights.3.shown" = true;
          "browser.search.update" = false;
          "extensions.update.enabled" = false;
          "extensions.update.autoUpdateDefault" = false;
          "extensions.getAddons.cache.enabled" = false;
          "dom.ipc.plugins.reportCrashURL" = false;
          "extensions.webservice.discoverURL" = "http://127.0.0.1";
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.unifiedIsOptIn" = true;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "";
          "toolkit.telemetry.archive.enabled" = false;
          "lightweightThemes.update.enabled" = false;
          "startup.homepage_welcome_url" = "";
          "startup.homepage_welcome_url.additional" = "";
          "startup.homepage_override_url" = "";
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.healthreport.documentServerURI" = "";
          "datareporting.healthreport.service.enabled" = false;
          "datareporting.healthreport.about.reportUrl" = "data:text/plain,";
          "toolkit.telemetry.cachedClientID" = "";
          "browser.selfsupport.url" = "";
          "browser.selfsupport.enabled" = false;
          "experiments.enabled" = false;
          "experiments.supported" = false;
          "experiments.activeExperiment" = false;
          "experiments.manifest.uri" = "";
          "network.allow-experiments" = false;
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.newtab.preload" = false;
          "browser.newtabpage.directory.ping" = "data:text/plain,";
          "browser.newtabpage.directory.source" = "data:text/plain,";
          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.enhanced" = false;
          "browser.newtabpage.introShown" = true;
          "browser.aboutHomeSnippets.updateUrl" = "https://127.0.0.1";
          "extensions.pocket.enabled" = false;
          "extensions.pocket.api" = "";
          "extensions.pocket.site" = "";
          "extensions.pocket.oAuthConsumerKey" = "";
          "social.whitelist" = "";
          "social.toast-notifications.enabled" = false;
          "social.shareDirectory" = "";
          "social.remote-install.enabled" = false;
          "social.directories" = "";
          "social.share.activationPanelEnabled" = false;
          "social.enabled" = false;
          "dom.flyweb.enabled" = false;
          "services.sync.enabled" = false;
        };
      };
    };
  };

  home.file.".cargo/config.toml".source = ./cargo-config.toml;
}
