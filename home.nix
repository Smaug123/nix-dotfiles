{ config, pkgs, ... }:

let username = "Patrick"; in
let dotnet = pkgs.dotnet-sdk_6; in

{
  imports = [ ./rider ./gmp ];

  rider = { enable = true; username = username; dotnet = dotnet; };
  gmp-symlink = { enable = true; };

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
  home.stateVersion = "21.11";

  home.packages =
    [
      pkgs.rust-analyzer
      pkgs.tmux
      pkgs.wget
      pkgs.youtube-dl
      pkgs.cmake
      pkgs.gnumake
      pkgs.gcc
      pkgs.gdb
      pkgs.hledger
      pkgs.hledger-web
      dotnet
      pkgs.docker
      pkgs.jitsi-meet
      #pkgs.handbrake
      pkgs.ripgrep
      pkgs.elan
      pkgs.coreutils-prefixed
      pkgs.shellcheck
      pkgs.html-tidy
      pkgs.hugo
      #pkgs.agda
      pkgs.pijul
      pkgs.universal-ctags
    ];

  programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      extensions = import ./vscode-extensions.nix { inherit pkgs; };
      userSettings = {
        workbench.colorTheme = "Default High Contrast";
        "files.Exclude" = {
          "**/.git" = true;
          "**/.DS_Store" = true;
          "**/Thumbs.db" = true;
          "**/*.olean" = true;
        };
        "git.path" = "${pkgs.git}/bin/git";
        "update.mode" = "none";
        "docker.dockerPath" = "${pkgs.docker}/bin/docker";
        "lean.leanpkgPath" = "${pkgs.elan}/bin/leanpkg";
      };
  };

  programs.tmux = {
    shell = "\${pkgs.zsh}/bin/zsh";
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
      plugins = [ "git" "macos" "dircycle" "timer" ];
      theme = "robbyrussell";
    };
    sessionVariables = {
      EDITOR = "vim";
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      RUSTFLAGS = "-L ${pkgs.libiconv}/lib";
    };
    shellAliases = {
      vim = "nvim";
      view = "vim -R";
      nix-upgrade = "sudo -i sh -c 'nix-channel --update && nix-env -iA nixpkgs.nix && launchctl remove org.nixos.nix-daemon && launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist'";
      cmake = "cmake -DCMAKE_MAKE_PROGRAM=${pkgs.gnumake}/bin/make -DCMAKE_AR=${pkgs.darwin.cctools}/bin/ar -DCMAKE_RANLIB=${pkgs.darwin.cctools}/bin/ranlib";
      ar = "${pkgs.darwin.cctools}/bin/ar";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    package = pkgs.gitAndTools.gitFull;
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
    };
  };

  programs.neovim.enable = true;
  programs.neovim.plugins = with pkgs.vimPlugins; [
    molokai
    tagbar
    { plugin = rust-vim;
      config = "let g:rustfmt_autosave = 1"; }
    { plugin = syntastic;
      config = ''let g:syntastic_rust_checkers = ['cargo']
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0''; }

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
    package = pkgs.emacsGcc;
    extraPackages = (epkgs: []);
    extraConfig = ''
(load-file (let ((coding-system-for-read 'utf-8))
           (shell-command-to-string "agda-mode locate")))
    '';
  };
}
