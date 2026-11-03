# Native kernel scheduling and power profiles.
{ pkgs, isLaptop, ... }:
{
  # Keep the tested laptop driver/kernel policy; other hosts use the stable kernel.
  boot.kernelPackages = if isLaptop then pkgs.linuxPackages_latest else pkgs.linuxPackages;

  services.power-profiles-daemon.enable = true;
  # Compressed RAM first; generated hardware config retains disk-swap fallback.
  zramSwap.enable = true;
}
