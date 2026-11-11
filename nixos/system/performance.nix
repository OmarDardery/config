# CachyOS kernel via its own pinned flake overlay and binary cache.
{ inputs, pkgs, ... }:
{
  # The pinned overlay matches upstream's kernel build environment.
  # Do not make the CachyOS flake input follow this system's nixpkgs.
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  services.power-profiles-daemon.enable = true;
  zramSwap.enable = true;
}
