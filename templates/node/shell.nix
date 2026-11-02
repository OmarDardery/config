{ pkgs }:
pkgs.mkShellNoCC {
  name = "node-development";
  packages = with pkgs; [
    git
    gnumake
    pkg-config
    nodejs
    pnpm
    typescript-language-server
  ];
}
