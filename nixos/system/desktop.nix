# Native login sessions and portals; application packages live in system/applications/.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.umbriel.nixosModules.default
  ];
  programs.umbriel.enable = true;
  environment.sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
  # The upstream Umbriel module supplies its portal and the GTK file chooser.
  xdg.portal = {
    enable = true;
    config.umbriel.default = [
      "umbriel"
      "gtk"
    ];
    config.umbriel."org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };

  # One desktop session; retain native integration without a second shell.
  programs.xwayland.enable = true;
  services.udisks2.enable = true;
  services.gnome.at-spi2-core.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;

  # Packet capture is restricted to the Wireshark group.
  users.groups.wireshark = { };
  security.wrappers.dumpcap = {
    source = "${pkgs.wireshark-cli}/bin/dumpcap";
    capabilities = "cap_net_raw,cap_net_admin+eip";
    owner = "root";
    group = "wireshark";
    permissions = "u+rx,g+x";
  };

  # greetd's native PAM integration unlocks the user keyring.
  services.gnome.gnome-keyring.enable = true;

  services.flatpak.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

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

  # One audio stack for the greeter and desktop, including PulseAudio clients.
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.udev.packages = [ pkgs.libmtp.out ];

}
