{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
{
  options.workstation.containers.enable = lib.mkEnableOption "Docker container runtime";

  config = lib.mkIf config.workstation.containers.enable {
    users.users.${profile.username}.extraGroups = [ "docker" ];

    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      daemon.settings.builder.gc = {
        enabled = true;
        defaultKeepStorage = "15GB";
      };
    };
  };
}
