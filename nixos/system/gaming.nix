{
  config,
  lib,
  pkgs,
  profile,
  isLaptop,
  ...
}:
lib.mkIf config.workstation.gaming.enable {
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraEnv = lib.optionalAttrs isLaptop {
        STEAM_FORCE_DESKTOPUI_SCALING = toString (import ../lib/display.nix).laptopScale;
      };
    };
  };
  programs.gamemode.enable = true;
  services.flatpak.packages = [ "com.vysp3r.ProtonPlus" ];
  users.users.${profile.username}.extraGroups = [ "gamemode" ];
}
