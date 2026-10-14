# Native login sessions and portals; user applications live in home/.
{
  config,
  lib,
  pkgs,
  inputs,
  profile,
  modulesPath,
  ...
}:
{
  imports = [
    (import "${modulesPath}/programs/wayland/wayland-session.nix" {
      inherit lib pkgs;
      enableXWayland = false;
      enableWlrPortal = false;
    })
  ];
  services.displayManager.sessionPackages = [
    config.home-manager.users.${profile.username}.programs.umbriel.package
  ];
  # Native GNOME supplies the shared portal frontend. Its system-level lookup
  # directory must include the Umbriel backend for the registered login session.
  xdg.portal = {
    enable = true;
    extraPortals = [
      inputs.umbriel.inputs.xdg-desktop-portal-umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    config.umbriel.default = [
      "umbriel"
      "gtk"
    ];
    config.umbriel."org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };

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

  services.displayManager.defaultSession = "umbriel";
  # SDDM runs before the user profile exists, so its cursor must be system-wide.
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

  # GNOME is a Wayland fallback session; SDDM remains the login manager.
  # User applications live in home/apps.nix; session/PAM services stay native.
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;

  # Omit unused speech services and home-owned applications.
  environment.gnome.excludePackages = with pkgs; [
    orca
    # User-facing core-shell tools are also installed/registered by HM.
    gnome-color-manager
    gnome-control-center
    gnome-tour
    gnome-user-docs
    gnome-backgrounds
    glycin-thumbnailer
    gst-thumbnailers
  ];
  services.speechd.enable = false;

}
