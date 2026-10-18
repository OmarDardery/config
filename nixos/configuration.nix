# Entry point. Identity is in profile.nix; machine details stay in hardware*.nix.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./system
  ];

  # Preserve the original installation's stateful defaults.
  system.stateVersion = "26.05";
}
