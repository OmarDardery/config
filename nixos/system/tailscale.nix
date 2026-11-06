{
  config,
  lib,
  profile,
  ...
}:
let
  kdeConnectPorts = [
    {
      from = 1714;
      to = 1764;
    }
  ];
in
{
  options.workstation.tailscale.enable = lib.mkEnableOption "Tailscale and KDE Connect access over its interface";

  config = lib.mkIf config.workstation.tailscale.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [ "--operator=${profile.username}" ];
    };
    systemd.services.tailscaled = {
      serviceConfig.Environment = [ "TS_DEBUG_FIREWALL_MODE=nftables" ];
    };

    # KDE Connect is reachable over Tailscale without exposing its ports on LAN.
    networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
      allowedTCPPortRanges = kdeConnectPorts;
      allowedUDPPortRanges = kdeConnectPorts;
    };
  };
}
