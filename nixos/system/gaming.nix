{
  config,
  pkgs,
  profile,
  ...
}:
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
      {
        name = "share/polkit-1/rules.d";
        path = "${pkgs.gamemode}/share/polkit-1/rules.d";
      }
    ])
  ];
  security.wrappers.gamemoded = {
    owner = "root";
    group = "root";
    source = "${pkgs.gamemode}/bin/gamemoded";
    capabilities = "cap_sys_nice+ep";
  };
  # Give game clients priority over background indexing/builds without
  # realtime scheduling, core pinning, or GPU-clock overrides.
  environment.etc."gamemode.ini".source = (pkgs.formats.ini { }).generate "gamemode.ini" {
    general = {
      renice = 10;
      # amd-pstate-epp uses EPP to boost; powersave permits PPD's EPP changes.
      # game-run holds the performance profile instead of racing PPD with
      # governor changes that could outlive the game.
      desiredgov = "powersave";
      igpu_desiredgov = "powersave";
      softrealtime = "off";
    };
    cpu = {
      pin_cores = "no";
      park_cores = "no";
    };
  };
  users.groups.gamemode = { };
  users.users.${profile.username}.extraGroups = [ "gamemode" ];

  # Steam itself is user-owned. Retain the host integration normally provided
  # by the NixOS Steam module; no Steam-specific firewall ports are opened.
  hardware.steam-hardware.enable = true;
  services.pulseaudio.support32Bit = config.services.pulseaudio.enable;
  services.pipewire.alsa.support32Bit = config.services.pipewire.alsa.enable;
}
