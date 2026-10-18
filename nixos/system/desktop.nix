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
  # The upstream Umbriel module supplies its portal and the GTK file chooser.
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

  # One desktop session; retain native integration without a second shell.
  programs.xwayland.enable = true;
  services.udisks2.enable = true;
  services.gnome.at-spi2-core.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;

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

  # Home Manager owns KDE Connect; networking.nix limits its ports to Tailscale.
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
