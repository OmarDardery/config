# Entry point. Identity is in profile.nix; machine details stay in hardware*.nix.
{ lib, profile, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./system
  ]
  ++ lib.optional (profile.hardwareProfile == "asus-tuf-a14") ./hardware.nix;

  # Optional bundles default off; set workstation.<bundle>.enable = true here.
  # See README.md for gaming, engineering, containers and printing.
  # Steam is part of this laptop's normal setup.
  workstation.gaming.enable = true;

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
