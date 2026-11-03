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
    orca-slicer
  ];
  services.udev.packages = [ pkgs.platformio-core.udev ];
}
