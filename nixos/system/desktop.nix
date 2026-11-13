# Native login sessions and portals; application packages live in system/applications/.
{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.umbriel.nixosModules.default
  ];
  programs.umbriel.enable = true;
  # Umbriel supplies its own portal; Plasma provides KDE portals.
  xdg.portal = {
    config.umbriel."org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };

  # Plasma and Umbriel are Wayland sessions; do not run X11 applications.
  services.xserver.enable = false;
  services.desktopManager.plasma6.enable = true;
  programs.xwayland.enable = pkgs.lib.mkForce false;
  services.udisks2.enable = true;
  services.gnome.at-spi2-core.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;

  # Ly's NixOS PAM integration unlocks the user keyring.
  services.gnome.gnome-keyring.enable = true;


  services.upower.enable = true;
  services.fwupd.enable = true;

  # Umbriel handles short presses; do not race its lock-screen power controls.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # One desktop audio stack, including PulseAudio clients.
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.udev.packages = [ pkgs.libmtp.out ];

}
