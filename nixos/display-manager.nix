{ pkgs, inputs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    wayland.compositor = "kwin";

    theme = "pixie";

    settings.Theme = {
      CursorTheme = "Bibata-Modern-Classic";
      CursorSize = 24;
    };
    
  };
  environment.systemPackages = [
    (inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.pixie-sddm.override {
      background = ./modules/Pictures/Wallpapers/dark-mountain.jpg;
      avatar = ./modules/Pictures/face.jpg;
      autoColor = true;
      fontFamily = "JetBrains Mono";
    })
  ];
}
