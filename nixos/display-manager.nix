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
      background = ./dotfiles/Pictures/Wallpapers/dark-mountain.jpg;
      avatar = ./dotfiles/Pictures/face.jpg;
      autoColor = true;
      # The nerd-fonts package provides this name, never "JetBrains Mono".
      fontFamily = "JetBrainsMono Nerd Font";
    })
  ];
}
