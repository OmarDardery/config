{ pkgs }:
pkgs.mkShellNoCC {
  name = "nix-development";
  packages = with pkgs; [
    git
    gnumake
    pkg-config
    nixd
    nixfmt
  ];
}
