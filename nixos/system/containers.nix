{
  config,
  lib,
  profile,
  ...
}:
lib.mkIf config.workstation.containers.enable {
  users.users.${profile.username}.extraGroups = [ "docker" ];
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    daemon.settings.builder.gc = {
      enabled = true;
      defaultKeepStorage = "15GB";
    };
  };
}
