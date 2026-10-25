# Evaluation-only fixture, copied into a temporary checkout by tests/ci.sh.
# This is not the laptop's disk layout and must never be deployed.
{ profile, ... }:
{
  nixpkgs.hostPlatform = profile.system;
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/CI-EVALUATION-ONLY";
    fsType = "vfat";
  };
}
