# Wireshark with unprivileged network capture for members of the wireshark group.
{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
{
  options.workstation.wireshark.enable = lib.mkEnableOption "Wireshark with network capture permissions";

  config = lib.mkIf config.workstation.wireshark.enable {
    programs.wireshark = {
      enable = true;
      # Qt GUI; the module's default is the CLI-only build.
      package = pkgs.wireshark;
      # setcap wrapper for dumpcap (cap_net_raw,cap_net_admin), group-restricted.
      dumpcap.enable = true;
      # Leave USB capture off: usbmon would expose every USB device to the group.
      usbmon.enable = false;
    };
    users.users.${profile.username}.extraGroups = [ "wireshark" ];
  };
}
