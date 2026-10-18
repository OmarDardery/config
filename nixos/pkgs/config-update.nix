{ pkgs, isNixOS }:
pkgs.writeShellApplication {
  name = "config-update";
  runtimeInputs =
    (with pkgs; [
      coreutils
      nh
      nix
      nvd
      util-linux
    ])
    ++ pkgs.lib.optional isNixOS pkgs.flatpak;
  text = builtins.readFile ./config-update.sh;
}
