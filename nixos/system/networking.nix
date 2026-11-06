{ profile, ... }:
{
  networking.hostName = profile.hostName;
  networking.networkmanager.enable = true;
  networking.nftables.enable = true;
  # Reaching the desktop does not require an online network.
  systemd.services.NetworkManager-wait-online.enable = false;
}
