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

  # Which session SDDM preselects. Without this it is empty and SDDM falls back
  # to whichever session was used last, which stopped being obvious the moment
  # gnome.nix added a second one.
  services.displayManager.defaultSession = "niri";

  # The cursor theme named above has to exist in the SYSTEM icon path. SDDM runs
  # as its own user, so home.pointerCursor in home/desktop.nix — which puts
  # Bibata in ~/.icons — is invisible to it. Same reason fonts.packages in
  # configuration.nix has to carry the greeter's font. Name a theme that is not
  # there and the greeter draws no cursor at all.
  #
  # This is the same store path home.pointerCursor already uses, so it costs
  # nothing to download.
  #
  # fallbackCursorThemes writes /share/icons/default, the theme libXcursor looks
  # for when nothing else matches. It defaults to empty, so this system has had
  # no `default` cursor theme at all; the KDE experiment briefly hid that by
  # setting its own to breeze_cursors, and removing KDE took it away again.
  xdg.icons.fallbackCursorThemes = [ "Bibata-Modern-Classic" ];

  environment.systemPackages = [
    pkgs.bibata-cursors
    (inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.pixie-sddm.override {
      background = ./dotfiles/Pictures/Wallpapers/dark-mountain.jpg;
      avatar = ./dotfiles/Pictures/face.jpg;
      autoColor = true;
      # The nerd-fonts package provides this name, never "JetBrains Mono".
      fontFamily = "JetBrainsMono Nerd Font";
    })
  ];
}
