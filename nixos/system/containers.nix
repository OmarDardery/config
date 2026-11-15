{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
{
  options.workstation.containers.enable = lib.mkEnableOption "Docker and WinBoat";

  config = lib.mkIf config.workstation.containers.enable {
    # WinBoat's USB passthrough requires Docker rather than Podman.
    environment.systemPackages = [ pkgs.winboat ];
    users.users.${profile.username}.extraGroups = [ "docker" ];

    virtualisation.docker = {
      enable = true;
      # WinBoat expects a running daemon during its setup and USB passthrough.
      enableOnBoot = true;
      daemon.settings.builder.gc = {
        enabled = true;
        defaultKeepStorage = "15GB";
      };
    };
  };
}
