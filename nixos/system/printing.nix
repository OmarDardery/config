{ config, lib, pkgs, profile, ... }:
lib.mkIf config.workstation.printing.enable {
  environment.systemPackages = [ pkgs.simple-scan ];
  # Driverless network/USB printers and eSCL/WSD scanners. No printer sharing.
  services.printing.enable = true;
  services.system-config-printer.enable = true;
  services.ipp-usb.enable = true;
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };
  users.users.${profile.username}.extraGroups = [
    "scanner"
    "lp"
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
