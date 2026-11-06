# Native kernel scheduling and power profiles.
{ lib, pkgs, ... }:
{
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

  services.power-profiles-daemon.enable = true;
  # Compressed RAM first; generated hardware config retains disk-swap fallback.
  zramSwap.enable = true;
}
