# Native login sessions and portals; application packages live in system/applications/.
{
  config,
  lib,
  pkgs,
  inputs,
  profile,
  ...
}:
{
  imports = [
    inputs.umbriel.nixosModules.default
  ];
  programs.umbriel.enable = true;
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

  # Limit the privileged KMS helper to the recording group.
  # KMS capture needs CAP_SYS_ADMIN; do not expose the helper to every user.
  users.groups.recording = { };
  security.wrappers.gsr-kms-server = {
    owner = "root";
    group = "recording";
    permissions = "u+rx,g+rx,o-rwx";
    capabilities = "cap_sys_admin+ep";
    source = lib.getExe' (pkgs.gpu-screen-recorder.override {
      inherit (config.security) wrapperDir;
    }) "gsr-kms-server";
  };
  # Only the privileged capture helper and access group are host-owned.
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

  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.flatpak.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # User units live in applications/services.nix; restrict ports to Tailscale.
  programs.kdeconnect = {
    enable = false;
    package = null;
  };
  services.upower.enable = true;
  services.fwupd.enable = true;

  # Umbriel handles short presses; do not race its lock-screen power controls.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
  };

  # One audio stack for the greeter and desktop, including PulseAudio clients.
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Driverless network/USB printers and eSCL/WSD scanners. No printer sharing.
  services.printing.enable = true;
  services.system-config-printer.enable = true;
  services.ipp-usb.enable = true;
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };
  users.users.${profile.username}.extraGroups = [
    "scanner"
    "lp"
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.udev.packages = [ pkgs.libmtp.out ];

}
