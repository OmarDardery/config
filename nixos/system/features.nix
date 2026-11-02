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
    diagnostics.enable = lib.mkEnableOption "host hardware, storage and network diagnostics";
    gaming.enable = lib.mkEnableOption "Steam, Millennium, GameMode and ProtonPlus";
    engineering.enable = lib.mkEnableOption "FreeCAD, PlatformIO, webOS tools and OrcaSlicer";
    containers.enable = lib.mkEnableOption "socket-activated Docker";
    printing.enable = lib.mkEnableOption "network/USB printers and scanners";
  };
}
