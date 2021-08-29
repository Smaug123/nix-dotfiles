{ config, pkgs, ... }:

{

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "Patrick";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  home.packages =
    [
      pkgs.tmux
      pkgs.wget
      pkgs.youtube-dl
      pkgs.cmake
      pkgs.gcc
      pkgs.gdb
      pkgs.hledger
      pkgs.hledger-web
      pkgs.dotnet-sdk_5
      pkgs.docker
      pkgs.jitsi-meet
      pkgs.elan
      pkgs.protonmail-bridge
      pkgs.handbrake
      pkgs.ripgrep
    ];

  programs.emacs = {
    enable = true;
    package = pkgs.emacsGcc;
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
      plugins = [ "git" "osx" "dircycle" "timer" ];
      theme = "robbyrussell";
    };
    sessionVariables = {
      EDITOR = "vim";
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
    };
    shellAliases = {
      vim = "nvim";
      view = "vim -R";
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

  home.file.".config/youtube-dl/config".source = ./youtube-dl.conf;

  home.file.".emacs.d" = {
    # don't make the directory read only so that impure melpa can still happen
    # for now
    recursive = true;
    source = pkgs.fetchFromGitHub {
      owner = "syl20bnr";
      repo = "spacemacs";
      rev = "59852a6ab52911ac76bb22aa8642ccef48238349";
      sha256 = "0m634adqnwqvi8d7qkq7nh8ivfz6cx90idvwd2wiylg4w1hly252";
    };
  };
}
