# Entry point. Identity is in profile.nix; machine details stay in hardware*.nix.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./system
  ];

  # Optional bundles default off; set workstation.<bundle>.enable = true here.
  # See README.md for gaming, engineering, containers and printing.

  # Preserve the original installation's stateful defaults.
  system.stateVersion = "26.05";
}
