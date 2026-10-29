# Entry point. Identity is in profile.nix; machine details stay in hardware*.nix.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./system
  ];

  # Optional bundles; enable only what this machine needs.
  workstation = {
    gaming.enable = false;
    engineering.enable = false;
    containers.enable = false;
    printing.enable = false;
  };

  # Preserve the original installation's stateful defaults.
  system.stateVersion = "26.05";
}
