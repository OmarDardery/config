{ pkgs }:
pkgs.writeShellApplication {
  name = "nixos-update";
  runtimeInputs = with pkgs; [
    coreutils
    nix
    nixos-rebuild
    sudo
    util-linux
  ];
  text = builtins.readFile ./nixos-update.sh;
}
