# Entry point. Identity is in profile.nix; machine details stay in hardware*.nix.
{ lib, profile, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./system
  ]
  ++ lib.optional (profile.hardwareProfile == "asus-tuf-a14") ./hardware.nix;

  # Complete desktop setup. Set individual bundles to false here to opt out.
  workstation = {
    gaming.enable = lib.mkDefault true;
    engineering.enable = lib.mkDefault true;
    containers.enable = lib.mkDefault true;
    printing.enable = lib.mkDefault true;
    diagnostics.enable = lib.mkDefault true;
    tailscale.enable = lib.mkDefault true;
    # The backup repository lives on the personal storage disk.
    backups.enable = lib.mkDefault (profile.storageUUID != null);
  };

  # Preserve the original installation's stateful defaults.
  system.stateVersion = profile.stateVersion;
  boot.loader = profile.bootLoader;
  fileSystems = lib.optionalAttrs (profile.storageUUID != null) {
    "/mnt/storage" = {
      device = "/dev/disk/by-uuid/${profile.storageUUID}";
      fsType = "xfs";
      options = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
      ];
    };
  };
}
