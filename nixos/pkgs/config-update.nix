{ pkgs }:
pkgs.writeShellApplication {
  name = "config-update";
  runtimeInputs = with pkgs; [
    coreutils
    flatpak
    nh
    nix
    nvd
    sudo
    util-linux
  ];
  text = builtins.readFile ./config-update.sh;
}
