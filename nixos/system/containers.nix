{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
lib.mkIf config.workstation.containers.enable {
  environment.systemPackages = [ pkgs.winboat ];
  # Scope the EOL Electron exception to the application that requires it.
  nixpkgs.config.permittedInsecurePackages = [ "electron-40.10.5" ];
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
