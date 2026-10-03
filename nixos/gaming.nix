{ config, pkgs, ... }:
{
  # Only privileges belong to the host; home/gaming.nix owns the application.
  # Keep the compiled helper paths in the upstream policy unchanged. NixOS
  # Home Manager uses the same pkgs, so its daemon calls these exact helpers.
  environment.systemPackages = [
    (pkgs.linkFarm "gamemode-polkit-policy" [
      {
        name = "share/polkit-1/actions";
        path = "${pkgs.gamemode}/share/polkit-1/actions";
      }
    ])
  ];
  security.polkit.enable = true;
  security.wrappers.gamemoded = {
    owner = "root";
    group = "root";
    source = "${pkgs.gamemode}/bin/gamemoded";
    capabilities = "cap_sys_nice+ep";
  };
  users.groups.gamemode = { };

  # Steam itself is user-owned. Retain the host integration normally provided
  # by the NixOS Steam module; no Steam-specific firewall ports are opened.
  hardware.steam-hardware.enable = true;
  services.pulseaudio.support32Bit = config.services.pulseaudio.enable;
  services.pipewire.alsa.support32Bit = config.services.pipewire.alsa.enable;
}
