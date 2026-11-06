{
  config,
  lib,
  profile,
  ...
}:
{
  options.workstation.containers.enable = lib.mkEnableOption "socket-activated Docker";

  config = lib.mkIf config.workstation.containers.enable {
    users.users.${profile.username}.extraGroups = [ "docker" ];
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;
      daemon.settings.builder.gc = {
        enabled = true;
        defaultKeepStorage = "15GB";
      };
    };
  };
}
