{ pkgs }:
pkgs.mkShell {
  name = "go-development";
  packages = with pkgs; [
    git
    gnumake
    pkg-config
    go
    gopls
    delve
    golangci-lint
  ];
}
