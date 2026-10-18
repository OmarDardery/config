# Native login sessions and portals; user applications live in home/.
{
  config,
  lib,
  pkgs,
  inputs,
  profile,
  ...
}:
let
  home = config.home-manager.users.${profile.username};
in
{
  imports = [
    inputs.umbriel.nixosModules.default
  ];
  programs.umbriel.enable = true;
  # Native GNOME supplies the shared portal frontend. Its system-level lookup
  # directory must include the Umbriel backend for the registered login session.
  xdg.portal = {
    enable = true;
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
      CursorTheme = home.home.pointerCursor.name;
      CursorSize = home.home.pointerCursor.size;
    };

  };

  services.displayManager.defaultSession = "umbriel";
  # SDDM runs before the user profile exists, so its cursor must be system-wide.
  xdg.icons.fallbackCursorThemes = [ home.home.pointerCursor.name ];

  environment.systemPackages = [
    home.home.pointerCursor.package
    (inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.pixie-sddm.override {
      background = ../assets/wallpapers/dark-mountain.jpg;
      avatar = ../assets/avatar.jpg;
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
    # Home Manager owns the user-facing tools.
    gnome-color-manager
    gnome-control-center
    gnome-tour
    gnome-user-docs
    gnome-backgrounds
    glycin-thumbnailer
    gst-thumbnailers
  ];
  services.speechd.enable = false;

  # The recorder app is home-owned; only the privileged KMS helper is global.
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

  security.polkit.enable = true;
  # SDDM inherits the keyring PAM integration through login.
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

  # Home Manager owns KDE Connect. Its ports are opened only on Tailscale
  # above; the NixOS module would open them globally.
  programs.kdeconnect = {
    enable = false;
    package = null;
  };
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.fwupd.enable = true;

  # Umbriel handles short presses; do not race its lock-screen power controls.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
  };

  # The greeter needs its font before a user profile is available.
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  fonts.fontDir.enable = true; # preserve native/Flatpak discovery of host greeter fonts

  # One audio stack for both login sessions, including legacy PulseAudio clients.
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
