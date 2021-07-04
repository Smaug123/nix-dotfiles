{ config, pkgs, lib, ... }:

let
    extensions = (with pkgs.vscode-extensions; [
        ms-vscode-remote.remote-ssh
      ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
  {
    name = "code-gnu-global";
    publisher = "austin";
    version = "0.2.2";
    sha256 = "1fz89m6ja25aif6wszg9h2fh5vajk6bj3lp1mh0l2b04nw2mzhd5";
  }
  {
    name = "Nix";
    publisher = "bbenoist";
    version = "1.0.1";
    sha256 = "0zd0n9f5z1f0ckzfjr38xw2zzmcxg1gjrava7yahg5cvdcw6l35b";
  }
  {
    name = "toml";
    publisher = "be5invis";
    version = "0.5.1";
    sha256 = "1r1y6krqw5rrdhia9xbs3bx9gibd1ky4bm709231m9zvbqqwwq2j";
  }
  {
    name = "haskell";
    publisher = "haskell";
    version = "1.4.0";
    sha256 = "1jk702fd0b0aqfryixpiy6sc8njzd1brd0lbkdhcifp0qlbdwki0";
  }
  {
    name = "Ionide-fsharp";
    publisher = "Ionide";
    version = "5.5.5";
    sha256 = "0nyi07xs7izynp2llhkqgz4i5j8gkpxy0gs934n9sm6rhs44vc66";
  }
  {
    name = "Ionide-Paket";
    publisher = "Ionide";
    version = "2.0.0";
    sha256 = "1455zx5p0d30b1agdi1zw22hj0d3zqqglw98ga8lj1l1d757gv6v";
  }
  {
    name = "latex-workshop";
    publisher = "James-Yu";
    version = "8.19.2";
    sha256 = "17jmwvj36pf207bv8nyi70vi5snskfnk7rbfcan79zl92g29id5z";
  }
  {
    name = "lean";
    publisher = "jroesch";
    version = "0.16.36";
    sha256 = "1ijzh82ka7k9pmzqax4ikmqv20yjmw7zi9vz2lizgsz6gdaylrj9";
  }
  {
    name = "language-haskell";
    publisher = "justusadam";
    version = "3.4.0";
    sha256 = "0ab7m5jzxakjxaiwmg0jcck53vnn183589bbxh3iiylkpicrv67y";
  }
  {
    name = "rust-analyzer";
    publisher = "matklad";
    version = "0.2.637";
    sha256 = "1bi9xklbls0jpccfg9bh3vk5s7v8f3a6f331b4hw0mpiv72ls5fr";
  }
  {
    name = "vscode-clang";
    publisher = "mitaki28";
    version = "0.2.4";
    sha256 = "0sys2h4jvnannlk2q02lprc2ss9nkgh0f0kwa188i7viaprpnx23";
  }
  {
    name = "vscode-docker";
    publisher = "ms-azuretools";
    version = "1.13.0";
    sha256 = "09iq528m3f8xa67daxyxddmg6xkzbbs2jps4hdni68j7jn0724y7";
  }
  {
    name = "csharp";
    publisher = "ms-dotnettools";
    version = "1.23.12";
    sha256 = "1j76399f5xhyn3qjp9gjdin7rdzn6bhig0xkswznf2yainz2x84z";
  }
  {
    name = "dotnet-interactive-vscode";
    publisher = "ms-dotnettools";
    version = "1.0.2309031";
    sha256 = "0vqlspq3696yyfsv17rpcbsaqs7nm7yvggv700sl1bia817cak10";
  }
  {
    name = "python";
    publisher = "ms-python";
    version = "2021.5.926500501";
    sha256 = "0hpb1z10ykg1sz0840qnas5ddbys9inqnjf749lvakj9spk1syk3";
  }
  {
    name = "vscode-pylance";
    publisher = "ms-python";
    version = "2021.6.1";
    sha256 = "1lv22z41rzbgy0b49c6avcy26747kw5533azbag4q12ylj67vn21";
  }
  {
    name = "jupyter";
    publisher = "ms-toolsai";
    version = "2021.7.942275039";
    sha256 = "1k60ak2scqq46gmwx3lmj82fchmvyjznra6y6p1djg2hqfkabxvx";
  }
  {
    name = "remote-containers";
    publisher = "ms-vscode-remote";
    version = "0.183.0";
    sha256 = "12v7037rn46svv6ff2g824hdkk7l95g4gbzrp5zdddwxs0a62jlg";
  }
  {
    name = "cpptools";
    publisher = "ms-vscode";
    version = "1.4.1";
    sha256 = "1728skp74b0685phjphcrrx5v7v715ms1j30xc363kvd2l9dvna8";
  }
  {
    name = "mono-debug";
    publisher = "ms-vscode";
    version = "0.16.2";
    sha256 = "10hixqkw5r3cg52xkbky395lv72sb9d9wrngdvmrwx62hkbk5465";
  }
  {
    name = "Theme-MarkdownKit";
    publisher = "ms-vscode";
    version = "0.1.4";
    sha256 = "1im78k2gaj6cri2jcvy727qdy25667v0f7vv3p3hv13apzxgzl0l";
  }
  {
    name = "trailing-spaces";
    publisher = "shardulm94";
    version = "0.3.1";
    sha256 = "0h30zmg5rq7cv7kjdr5yzqkkc1bs20d72yz9rjqag32gwf46s8b8";
  }
  {
    name = "vscode-lldb";
    publisher = "vadimcn";
    version = "1.6.4";
    sha256 = "0d2kra6rd0310qxkzn8paygirgmxd2v8yq0rbjmfnngcqccqv0pk";
  }
  {
    name = "vim";
    publisher = "vscodevim";
    version = "1.21.2";
    sha256 = "18bifdsm4k6rmzg5jx9kin0vlm1h9jikmka0rcyyw7zk1lxwbs9z";
  }
  {
    name = "debug";
    publisher = "webfreak";
    version = "0.25.1";
    sha256 = "1l01sv6kwh8dlv3kygkkd0z9m37hahflzd5bx1wwij5p61jg7np9";
  }
  {
    name = "markdown-all-in-one";
    publisher = "yzhang";
    version = "3.4.0";
    sha256 = "0ihfrsg2sc8d441a2lkc453zbw1jcpadmmkbkaf42x9b9cipd5qb";
  }
];
    vscode-with-extensions = pkgs.vscode-with-extensions.override {
        vscodeExtensions = extensions;
      };

in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget

  environment.systemPackages =
    [ pkgs.neovim
      pkgs.alacritty
      pkgs.tmux
      pkgs.wget
      pkgs.youtube-dl
      pkgs.git
      pkgs.fzf
      pkgs.shellcheck
      pkgs.cmake
      pkgs.gcc
      pkgs.gdb
      pkgs.hledger
      pkgs.hledger-web
      pkgs.dotnet-sdk_5
      pkgs.docker
      pkgs.ycmd
      pkgs.keepassxc
      pkgs.oh-my-zsh
      pkgs.jitsi-meet
      pkgs.elan
      pkgs.protonmail-bridge
      pkgs.handbrake
      vscode-with-extensions
    ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
    "vscode-with-extensions"
    "vscode-extension-ms-vscode-remote-remote-ssh"
  ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
