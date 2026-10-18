# Native performance policy; application launchers use the shared power profile.
{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.power-profiles-daemon.enable = true;
  services.scx = {
    enable = true;
    package = pkgs.scx.rustscheds;
    scheduler = "scx_lavd";
    # Follow PPD (including performance-run/game-run), with upstream EPP fallback.
    extraArgs = [ "--autopower" ];
  };

  # Compressed RAM first; generated hardware config retains disk-swap fallback.
  zramSwap.enable = true;
}
