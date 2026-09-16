{ pkgs, inputs, ... }:
{
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    # Keep Steam's broad port ranges closed until one of these features is
    # actually needed on this machine.
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;
  };
}
