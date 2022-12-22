{ pkgs }:

with pkgs.vscode-extensions; [
    bbenoist.nix
    haskell.haskell
    yzhang.markdown-all-in-one
    james-yu.latex-workshop
    vscodevim.vim
    # Not supported on Darwin, apparently
    #    ms-dotnettools.csharp
    
] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
{
    name = "remote-containers";
    publisher = "ms-vscode-remote";
    version = "0.266.0";
    sha256 = "sha256-XTt3qRuNXw6IAFj9QrblX3SnWeX771Dw/nY7eq3v8gA=";
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
    name = "vscode-pull-request-github";
    publisher = "GitHub";
    version = "0.55.2022120109";
    sha256 = "sha256-Ic7MubsL0xBqPRA8KupUNZ964B8dfnLk4OT7OORzzww=";
}
{
    name = "remote-ssh";
    publisher = "ms-vscode-remote";
    version = "0.93.2022112815";
    sha256 = "sha256-Uevadj2FTtP4zSRdlOt960sNWwW5z+K1d7dIZoyCkQs=";
}
{
    name = "vscode-docker";
    publisher = "ms-azuretools";
    version = "1.23.1";
    sha256 = "UPUfTOc5xJhI5ACm2oyWqtZ4zNxZjy16D6Mf30eHFEI=";
}
{
    name = "code-gnu-global";
    publisher = "austin";
    version = "0.2.2";
    sha256 = "1fz89m6ja25aif6wszg9h2fh5vajk6bj3lp1mh0l2b04nw2mzhd5";
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
    version = "0.16.56";
    sha256 = "sha256-BlANViRnZnZqEqOaLqyB+Shi6NjumSwVD/R19+cIgCI=";
}
{
    name = "lean4";
    publisher = "leanprover";
    version = "0.0.99";
    sha256 = "sha256-JbQ37AlCqMFBbe3PFIF7jMy0jkeHO4g67hgRQ7BywkQ=";
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
    version = "1.0.3602041";
    sha256 = "sha256-w1zhs5LoTieUe4PVfpCDCREPXYIXRiniRRBjgZtHr2Y=";
}
{
    name = "python";
    publisher = "ms-python";
    version = "2022.19.13351014";
    sha256 = "sha256-GvE4tWTnLMjDFvV3qGGZB6uDm/+FSbocD9ecDRZxwpQ=";
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
    name = "trailing-spaces";
    publisher = "shardulm94";
    version = "0.4.1";
    sha256 = "0h30zmg5rq7cv7kjdr5yzqkkc1bs20d72yz9rjqag32gwf46s8b8";
}
{
    name = "debug";
    publisher = "webfreak";
    version = "0.26.0";
    sha256 = "sha256-ZFrgsycm7/OYTN2sD3RGJG+yu0hTvADkHK1Gopm0XWc=";
}
]
