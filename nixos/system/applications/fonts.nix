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
  system.fsPackages = [ pkgs.bindfs ];
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

  # Cache paths from the old user profile can survive moving fonts to the
  # system. Refresh inside each sandbox as its user, once per font set/ref.
  systemd.user.services.flatpak-font-cache = {
    description = "Refresh Flatpak font caches after font changes";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session-pre.target" ];
    restartTriggers = [ config.system.path ];
    path = [ config.services.flatpak.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.python3}/bin/python3 ${../../pkgs/flatpak-font-cache.py} /run/current-system/sw/share/X11/fonts";
    };
  };
}
