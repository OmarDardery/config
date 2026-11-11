# Native kernel scheduling and power profiles.
{ inputs, ... }:
{
  # Follow the CachyOS kernel release branch when the flake lock is refreshed.
  boot.kernelPackages =
    inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-latest;

  services.power-profiles-daemon.enable = true;
  # Compressed RAM first; generated hardware config retains disk-swap fallback.
  zramSwap.enable = true;
}
