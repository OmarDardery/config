{ pkgs }:
pkgs.mkShell {
  name = "rust-development";
  packages = with pkgs; [
    git
    gnumake
    pkg-config
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];
}
