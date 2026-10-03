{
  pkgs,
  inputs,
  config,
  ...
}:
let
  # Match the pinned GNOME core-apps module, including its auxiliary modules.
  gnomeApps = with pkgs; [
    baobab
    decibels
    epiphany
    gnome-text-editor
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-console
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-system-monitor
    gnome-tecla
    gnome-weather
    loupe
    nautilus
    papers
    gnome-connections
    showtime
    simple-scan
    snapshot
    yelp
    gnome-disk-utility
    seahorse
    sushi
    gnome-software
    # User-facing core-shell tools; the shell/session machinery stays native.
    gnome-color-manager
    gnome-control-center
    gnome-tour
    gnome-user-docs
    gnome-backgrounds
    glycin-thumbnailer
    gst-thumbnailers
  ];
in
{
  dbus.packages = gnomeApps ++ [ pkgs.gvfs ];
  systemd.user.packages = gnomeApps ++ [ pkgs.gvfs ];
  home.sessionSearchVariables.GIO_EXTRA_MODULES = [ "${pkgs.gvfs}/lib/gio/modules" ];
  # Native GNOME consumers also need the schemas, not just wrapped app binaries.
  home.sessionSearchVariables.XDG_DATA_DIRS = [
    "${config.home.profileDirectory}/share"
  ]
  ++ map (p: "${p}/share/gsettings-schemas/${p.name}") gnomeApps;
  home.sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${config.home.profileDirectory}/lib/nautilus/extensions-4";
  # Preserve the askpass choice previously supplied by programs.seahorse.
  home.sessionVariables.SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ "org.gnome.Nautilus.desktop" ];
  };
  programs.bash.enableVteIntegration = true;
  programs.zsh.enableVteIntegration = true;

  home.packages =
    with pkgs;
    [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.webos-dev-manager.packages.${pkgs.stdenv.hostPlatform.system}.webos-dev-manager
      kitty
      # The gtk3-default build, not libreoffice-qt — see SAL_USE_VCLPLUGIN below
      # for why the VCL backend decides whether Impress can present onto HDMI.
      libreoffice
      hunspell
      hunspellDicts.en_US # hunspell ships no dictionaries of its own
      rnote
      proton-vpn
      protonup-ng
      fastfetch
      unzip
      lshw
      zenity
      obsidian
      # Media and viewers. There was previously no video player, image viewer or
      # PDF viewer installed at all.
      mpv
      imv
      wireshark # capture privileges remain the native host's responsibility
      gvfs # user mounts/trash/remote files; native UDisks2 and MTP rules remain required
      gpu-screen-recorder # NixOS provides the restricted KMS helper wrapper

      # Session controls, for the noctalia bar and the media keys.
      pavucontrol
      brightnessctl
      playerctl
      opencode

      # ── Chat ───────────────────────────────────────────────────────────
      # Official: the derivation fetches from stable.dl2.discordapp.net, which is
      # Discord's own CDN, not a repackage.
      discord
      # WhatsApp has NO official Linux desktop client — the only official surfaces
      # are the phone apps, web.whatsapp.com, and the Windows/macOS builds. ZapZap
      # is a third-party Qt shell around the official WhatsApp Web, built from its
      # real upstream (github.com/rafatosta/zapzap, rtosta.com/zapzap). It buys
      # native notifications and a tray icon over a browser tab; it does not make
      # anything more official than the web app it wraps.
      #zapzap
      # Windows apps in a container. Needs Docker socket (virtualisation.docker).
      # KVM needs nothing: /dev/kvm and /dev/net/tun are already world-accessible here.
      #
      # The Windows guest wants 4 GB minimum and this machine has 14 GiB, so
      # expect to be swapping into zram with a browser and an IDE already open.
      winboat
      logisim-evolution
      (callPackage ../pkgs/antigravity-cli.nix { })
    ]
    ++ gnomeApps;
  home.sessionVariables = {
    # ── Why "click Present" lands on the projector ─────────────────────────
    # Under Wayland a client cannot position its own windows. The one exception
    # is xdg_toplevel.set_fullscreen, which takes an optional wl_output argument
    # meaning "fullscreen me on THAT monitor". GTK3 exposes it as
    # gtk_window_fullscreen_on_monitor(), and LibreOffice's gtk3 VCL backend
    # calls it when Impress starts a presentation. Qt has no equivalent path on
    # Wayland — showFullScreen only ever takes effect on the main screen,
    # because Qt never passes an output to the compositor. So under the Qt
    # backend the slides fullscreen on the laptop panel no matter what the
    # "Presentation display" dropdown says, which is why this previously needed
    # wl-mirror to work around.
    #
    # This was never a niri problem: Fedora presented correctly under the same
    # compositor because its LibreOffice defaults to gtk3. The build installed
    # here ships all four backends (gtk3, qt6, kf6, gen) and picks one at
    # runtime by autodetecting the desktop — and niri is not a desktop it
    # recognises. Naming the backend removes the guess.
    #
    # Session variable: needs a fresh LOGIN, not just a rebuild.
    SAL_USE_VCLPLUGIN = "gtk3";

  };
}
