{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.workstation.engineering.enable {
  environment.systemPackages = with pkgs; [
    freecad
    platformio-core
  ];
  services.flatpak.packages = [ "com.orcaslicer.OrcaSlicer" ];
  services.udev.packages = [ pkgs.platformio-core.udev ];
}
