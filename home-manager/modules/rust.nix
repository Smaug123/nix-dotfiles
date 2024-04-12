{pkgs, ...}: {
  programs.zsh.sessionVariables = {
    RUSTFLAGS = "-L ${pkgs.libiconv}/lib -L ${pkgs.libcxx}/lib";
    RUST_BACKTRACE = "full";
  };
  home.file.".cargo/config.toml".source = ./rust/cargo-config.toml;
  home.packages = [
    pkgs.rust-analyzer
  ];
}
