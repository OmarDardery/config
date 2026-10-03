# Only display-manager, PAM, and native portal registration live outside HM.
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
}
