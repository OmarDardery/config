# Specialist bundles are opt-in; enable them in configuration.nix.
{ lib, ... }:
{
  imports = [
    ./gaming.nix
    ./engineering.nix
    ./containers.nix
    ./printing.nix
  ];
  options.workstation = {
    backups.enable = lib.mkEnableOption "daily Restic backups to /mnt/storage/backup";
    tailscale.enable = lib.mkEnableOption "Tailscale and KDE Connect access over its interface";
    diagnostics.enable = lib.mkEnableOption "host hardware, storage and network diagnostics";
    gaming.enable = lib.mkEnableOption "Steam and GameMode";
    engineering.enable = lib.mkEnableOption "FreeCAD, PlatformIO and OrcaSlicer";
    containers.enable = lib.mkEnableOption "socket-activated Docker";
    printing.enable = lib.mkEnableOption "network/USB printers and scanners";
  };
}
