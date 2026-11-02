{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
lib.mkIf config.workstation.engineering.enable {
  environment.systemPackages = with pkgs; [
    freecad
    platformio-core
    orca-slicer
    inputs.webos-dev-manager.packages.${pkgs.stdenv.hostPlatform.system}.webos-dev-manager
  ];
  services.udev.packages = [ pkgs.platformio-core.udev ];
}
