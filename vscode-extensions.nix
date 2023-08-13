{pkgs}:
with pkgs.vscode-extensions;
  [
    bbenoist.nix
    haskell.haskell
    yzhang.markdown-all-in-one
    james-yu.latex-workshop
    vscodevim.vim
    ms-dotnettools.csharp
    ms-vscode-remote.remote-ssh
    justusadam.language-haskell
    rust-lang.rust-analyzer
    github.vscode-pull-request-github
    shardulm94.trailing-spaces
    nvarner.typst-lsp
  ]
  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "remote-containers";
      publisher = "ms-vscode-remote";
      version = "0.285.0";
      sha256 = "sha256-UHp6Ewx0bUvPjgaO0A5k77SGj8ovPFLl/WvxyLcZ4y0=";
    }
    {
      name = "nix-env-selector";
      publisher = "arrterian";
      version = "1.0.9";
      sha256 = "sha256-TkxqWZ8X+PAonzeXQ+sI9WI+XlqUHll7YyM7N9uErk0=";
    }
    {
      name = "vscode-hsx";
      publisher = "s0kil";
      version = "0.4.0";
      sha256 = "sha256-/WRy+cQBqzb6QB5+AizlyIcjqNpZ86o2at885hOcroM=";
    }
    {
      name = "vscode-docker";
      publisher = "ms-azuretools";
      version = "1.24.0";
      sha256 = "sha256-zZ34KQrRPqVbfGdpYACuLMiMj4ZIWSnJIPac1yXD87k=";
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
      version = "0.16.58";
      sha256 = "sha256-e5+C6dAcpet4xOiifmTJ1vm2pNrcPhx/mjl70il5NG0=";
    }
    {
      name = "lean4";
      publisher = "leanprover";
      version = "0.0.101";
      sha256 = "sha256-tHxP6X6qp3qVkkCn5TjhHrYHHvGGWJ4kYE7la6bPT6w=";
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
      version = "1.0.4165021";
      sha256 = "sha256-P5EHc5t4UyKEfxIGNTg+SyQPFlrbwaNIaprPY63iJ/k=";
    }
    {
      name = "mono-debug";
      publisher = "ms-vscode";
      version = "0.16.3";
      sha256 = "sha256-6IU8aP4FQVbEMZAgssGiyqM+PAbwipxou5Wk3Q2mjZg=";
    }
    {
      name = "Theme-MarkdownKit";
      publisher = "ms-vscode";
      version = "0.1.4";
      sha256 = "1im78k2gaj6cri2jcvy727qdy25667v0f7vv3p3hv13apzxgzl0l";
    }
    {
      name = "debug";
      publisher = "webfreak";
      version = "0.26.1";
      sha256 = "sha256-lLLa8SN+Sf9Tbi7HeWYWa2KhPQFJyQWrf9l3EUljwYo=";
    }
  ]
  ++ [
    (let
      vsix = builtins.fetchurl {
        name = "vadimcn-vscode-lldb.zip";
        url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.0/codelldb-aarch64-darwin.vsix";
        sha256 = "sha256:1kxrxxlzasa9jl73lqh3n36fzpdgh2hbxpzp8fk6xyzcc5vm9zfb";
      };
    in
      pkgs.vscode-utils.buildVscodeExtension
      {
        vsix = vsix;
        src = vsix;
        vscodeExtPublisher = "vadimcn";
        vscodeExtName = "vscode-lldb";
        vscodeExtUniqueId = "vadimcn-vscode-lldb";
        publisher = "vadimcn";
        version = "1.9.0";
        name = "vadimcn-vscode-lldb-1.9.0";
      })
  ]
