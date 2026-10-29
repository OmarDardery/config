# Specialist bundles are opt-in; enable them in configuration.nix.
{ config, lib, pkgs, profile, ... }:
let
  cfg = config.workstation;
in
{
  imports = [
    ./gaming.nix
    ./applications/gaming.nix
    ./applications/engineering.nix
    ./printing.nix
  ];
  options.workstation = {
    gaming.enable = lib.mkEnableOption "Steam, Millennium, GameMode and ProtonPlus";
    engineering.enable = lib.mkEnableOption "FreeCAD, Logisim, PlatformIO, webOS tools and OrcaSlicer";
    containers.enable = lib.mkEnableOption "socket-activated Docker and WinBoat";
    printing.enable = lib.mkEnableOption "network/USB printers and scanners";
  };
  config = lib.mkIf cfg.containers.enable {
    environment.systemPackages = [ pkgs.winboat ];
    # Scope the EOL Electron exception to the application that requires it.
    nixpkgs.config.permittedInsecurePackages = [ "electron-40.10.5" ];
    users.users.${profile.username}.extraGroups = [ "docker" ];
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;
      daemon.settings.builder.gc = {
        enabled = true;
        defaultKeepStorage = "15GB";
      };
    };
  };
}
