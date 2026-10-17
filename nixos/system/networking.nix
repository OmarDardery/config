{ config, profile, ... }:
let
  kdeConnectPorts = [
    {
      from = 1714;
      to = 1764;
    }
  ];
in
{
  networking.hostName = profile.hostName;
  networking.networkmanager.enable = true;
  networking.nftables.enable = true;
  programs.mtr.enable = true;
  # This laptop does not require network availability to reach the desktop.
  systemd.services.NetworkManager-wait-online.enable = false;

  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [ "--operator=${profile.username}" ];
  };
  systemd.services.tailscaled.serviceConfig.Environment = [ "TS_DEBUG_FIREWALL_MODE=nftables" ];

  # KDE Connect is reachable over Tailscale without exposing its ports on LAN.
  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPortRanges = kdeConnectPorts;
    allowedUDPPortRanges = kdeConnectPorts;
  };
}
