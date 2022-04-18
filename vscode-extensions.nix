{pkgs}:
with pkgs.vscode-extensions;
  [
    bbenoist.nix
    haskell.haskell
    yzhang.markdown-all-in-one
    james-yu.latex-workshop
    vscodevim.vim
    # Not supported on Darwin, apparently
    #    ms-dotnettools.csharp
  ]
  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "remote-containers";
      publisher = "ms-vscode-remote";
      version = "0.232.6";
      sha256 = "4Li0sYfHOsJMn5FJtvDTGKoGPcRmoosD9tZ7q9H9DfQ=";
    }
    {
      name = "remote-ssh";
      publisher = "ms-vscode-remote";
      version = "0.79.2022040715";
      sha256 = "hTRfoUHKrIOSV8eZ/62ewaII5291huXjOZ++dRUmKoI=";
    }
    {
      name = "vscode-docker";
      publisher = "ms-azuretools";
      version = "1.21.0";
      sha256 = "UPUfTOc5xJhI5ACm2oyWqtZ4zNxZjy16D6Mf30eHFEI=";
    }
    {
      name = "code-gnu-global";
      publisher = "austin";
      version = "0.2.2";
      sha256 = "1fz89m6ja25aif6wszg9h2fh5vajk6bj3lp1mh0l2b04nw2mzhd5";
    }
    {
      name = "rust-analyzer";
      publisher = "matklad";
      version = "0.3.1017";
      sha256 = "t5CCUdFCiSYrMsBHG5eOfg3sXMacFWiR0hmVa7S1i8Y=";
    }
    {
      name = "vscode-lldb";
      publisher = "vadimcn";
      version = "1.7.0";
      sha256 = "CGVVs//jIZM8uX7Wc9gM4aQGwECi88eIpfPqU2hKbeA=";
    }
    {
      name = "toml";
      publisher = "be5invis";
      version = "0.6.0";
      sha256 = "yk7buEyQIw6aiUizAm+sgalWxUibIuP9crhyBaOjC2E=";
    }
    {
      name = "Ionide-Paket";
      publisher = "Ionide";
      version = "2.0.0";
      sha256 = "1455zx5p0d30b1agdi1zw22hj0d3zqqglw98ga8lj1l1d757gv6v";
    }
    {
      name = "lean";
      publisher = "jroesch";
      version = "0.16.46";
      sha256 = "hjflz5JHVr1YWq6QI9DpdNPY1uL7lAuQTMAdwCtLEfY=";
    }
    {
      name = "language-haskell";
      publisher = "justusadam";
      version = "3.6.0";
      sha256 = "0ab7m5jzxakjxaiwmg0jcck53vnn183589bbxh3iiylkpicrv67y";
    }
    {
      name = "vscode-clang";
      publisher = "mitaki28";
      version = "0.2.4";
      sha256 = "0sys2h4jvnannlk2q02lprc2ss9nkgh0f0kwa188i7viaprpnx23";
    }
    {
      name = "dotnet-interactive-vscode";
      publisher = "ms-dotnettools";
      version = "1.0.3211011";
      sha256 = "a3u9NKsqHZKhZkKqJqo+LgJFTL2yhehBepTOFOXE+jY=";
    }
    {
      name = "python";
      publisher = "ms-python";
      version = "2022.5.11051003";
      sha256 = "hXTVZ7gbu234zyAg0ZrZPUo6oULB98apxe79U2yQHD4=";
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
      name = "debug";
      publisher = "webfreak";
      version = "0.26.0";
      sha256 = "1l01sv6kwh8dlv3kygkkd0z9m37hahflzd5bx1wwij5p61jg7np9";
    }
  ]
