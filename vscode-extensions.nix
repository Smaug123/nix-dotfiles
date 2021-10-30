{ pkgs }:

with pkgs.vscode-extensions; [
    bbenoist.nix
    haskell.haskell
    yzhang.markdown-all-in-one
    james-yu.latex-workshop
    ms-azuretools.vscode-docker
    vscodevim.vim
# Doesn't work with vscodium, and unfree
#       ms-vscode-remote.remote-ssh
# Not supported on Darwin, apparently
#       ms-dotnettools.csharp
] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
{
    name = "code-gnu-global";
    publisher = "austin";
    version = "0.2.2";
    sha256 = "1fz89m6ja25aif6wszg9h2fh5vajk6bj3lp1mh0l2b04nw2mzhd5";
}
{
    name = "rust-analyzer";
    publisher = "matklad";
    version = "0.2.792";
    sha256 = "1m4g6nf5yhfjrjja0x8pfp79v04lxp5lfm6z91y0iilmqbb9kx1q";
}
{
    name = "vscode-lldb";
    publisher = "vadimcn";
    version = "1.6.8";
    sha256 = "1c81hs2lbcxshw3fnpajc9hzkpykc76a6hgs7wl5xji57782bckl";
}
{
    name = "toml";
    publisher = "be5invis";
    version = "0.5.1";
    sha256 = "1r1y6krqw5rrdhia9xbs3bx9gibd1ky4bm709231m9zvbqqwwq2j";
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
    version = "0.16.39";
    sha256 = "0v1w0rmx2z7q6lfrl430fl6aq6n70y14s2fqsp734igdkdhdnvmk";
}
{
    name = "language-haskell";
    publisher = "justusadam";
    version = "3.4.0";
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
    name = "remote-containers";
    publisher = "ms-vscode-remote";
    version = "0.183.0";
    sha256 = "12v7037rn46svv6ff2g824hdkk7l95g4gbzrp5zdddwxs0a62jlg";
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
    version = "0.25.1";
    sha256 = "1l01sv6kwh8dlv3kygkkd0z9m37hahflzd5bx1wwij5p61jg7np9";
}
]
