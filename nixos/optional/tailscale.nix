# Import this module from configuration.nix to enable Tailscale.
{ config, ... }:
{
  services.tailscale.enable = true;

  networking.firewall = {
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];
}
