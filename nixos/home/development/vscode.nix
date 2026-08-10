{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      platformio.platformio-vscode-ide
      golang.go
      rust-lang.rust-analyzer
    ];
  };
}
