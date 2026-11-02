{ config, pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontDir.enable = true;
  };

  # Follow the NixOS non-Nix application integration: expose real files at the
  # standard path, rather than store symlinks that some sandboxes cannot follow.
  # https://wiki.nixos.org/wiki/Fixes_for_non-Nix_applications
  fileSystems."/usr/share/fonts" = {
    # A generation-specific source also makes rebuilds replace the mount;
    # bindfs resolves its source at startup and otherwise retains old fonts.
    device = "${config.system.path}/share/X11/fonts";
    fsType = "fuse.bindfs";
    options = [
      "ro"
      "resolve-symlinks"
      "x-gvfs-hide"
    ];
  };

}
