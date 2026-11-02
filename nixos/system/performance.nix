# Native kernel scheduling and power profiles.
{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.power-profiles-daemon.enable = true;
  # Compressed RAM first; generated hardware config retains disk-swap fallback.
  zramSwap.enable = true;
}
