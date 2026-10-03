{
  pkgs,
  lib,
  config,
  isLaptop,
  ...
}:
{
  services.kdeconnect.enable = true;
  systemd.user.services.kdeconnect = {
    Unit.BindsTo = [ "graphical-session.target" ];
    Service = {
      Type = "dbus";
      BusName = "org.kde.kdeconnect";
    };
  };
  # GNOME otherwise starts a second daemon through the package's XDG autostart.
  xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE Connect
    Hidden=true
  '';
  # D-Bus activation must use the same session-bound service, not fork a daemon.
  xdg.dataFile."dbus-1/services/org.kde.kdeconnect.service".text = ''
    [D-BUS Service]
    Name=org.kde.kdeconnect
    Exec=${pkgs.coreutils}/bin/false
    SystemdService=kdeconnect.service
  '';

  # The play/pause/skip buttons on Bluetooth headphones speak AVRCP, which
  # nothing on the desktop listens to by default — so pressing them on the Sony
  # set did nothing. mpris-proxy is BlueZ's own bridge from AVRCP to MPRIS,
  # which is the bus playerctl and the noctalia bar already use.
  services.mpris-proxy.enable = true;
  systemd.user.services.mpris-proxy = {
    Unit = {
      BindsTo = lib.mkForce [ "graphical-session.target" ];
      After = lib.mkForce [ "graphical-session.target" ];
      ConditionPathExists = "/sys/class/bluetooth";
    };
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
    Service.Restart = "on-failure";
    Service.RestartSec = "5s";
  };

  # Raw config trees, deployed as read-only symlinks into ~/.config.
  # Retain directory-level ownership so existing HM directory links migrate safely.
  xdg.configFile."kitty".source = pkgs.runCommand "kitty-config" { } ''
    cp -r ${../dotfiles/kitty} "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/kitty.conf" \
      --replace-fail '~/.local/state/noctalia/theme/kitty.conf' \
      ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/theme/kitty.conf"}
  '';

  # Required for pointerCursor.gtk to deploy the cursor settings.
  gtk.enable = true;
  gtk.gtk3.extraCss = ''@import url("noctalia.css");'';
  gtk.gtk4.extraCss = ''@import url("noctalia.css");'';
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # Single source of truth for the cursor. This sets XCURSOR_THEME/XCURSOR_SIZE
  # for the session, writes the GTK settings, and populates ~/.icons, replacing
  # three separate declarations that had drifted apart.
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
  };

  # Fonts in home.packages are invisible to fontconfig on NixOS unless this is
  # on: the per-user directory under /etc/profiles is not a path fontconfig
  # searches by default. Without it, kitty's JetBrainsMono falls back to DejaVu.
  fonts.fontconfig.enable = true;

  home.packages =
    with pkgs;
    [
      nerd-fonts.jetbrains-mono

      # Arabic coverage independently of the English locale and US keyboard.
      noto-fonts
      adw-gtk3
      glib # gsettings for Noctalia's dark/light and GTK-theme synchronization
      dconf

      # capture / selection
      slurp
      grim
      hyprpicker

      # processing
      # The default includes every OCR model (about 1 GiB). These are the two
      # languages used on this machine; Tesseract requires English to be present.
      (tesseract.override {
        enableLanguages = [
          "eng"
          "ara"
        ];
      })
      imagemagick
      zbar # zbarimg for QR/barcode
      bc

      # ── Displays ───────────────────────────────────────────────────────
      # What GNOME's Settings → Displays panel does, split across three tools
      # for the Umbriel session.
      #
      # nwg-displays drives wlr-output-management for interactive changes;
      # persistent modes and positions are declared in home/umbriel.nix.
      nwg-displays
      wlr-randr # the same thing for scripts and one-off queries
      # Mirroring, which Umbriel has no native support for. Still the right tool for
      # a projector that will not take an extended desktop — but with the
      # SAL_USE_VCLPLUGIN fix in ./apps.nix, presenting no longer needs it.
      wl-mirror

      # network / opening
      curl
      jq
      sshfs # Phone Connect's remote-filesystem integration
      pulseaudio # pactl, used by recording/audio helpers; no daemon is enabled
      procps # pkill, used by template reloads and recording helpers
      xdg-utils
      wl-clipboard

      # recording
      wl-screenrec # region recording + mic audio
      wf-recorder # fallback
      ffmpeg # also provides ffprobe

      # annotation + extras
      swappy
      satty
      translate-shell # `trans`, for OCR translation
    ]
    ++ lib.optionals isLaptop [
      (pkgs.writeShellApplication {
        name = "mirror-laptop";
        runtimeInputs = [
          config.programs.umbriel.package
          pkgs.jq
          pkgs.wl-mirror
        ];
        text = ''
          outputs=$(umbriel outputs --json)
          panel=$(jq -er '
            [.[] | select(.make == "BOE" and .model == "NE140QDM-NX7" and .enabled) | .name]
            | if length == 1 then .[0] else error("Expected one active laptop panel") end
          ' <<< "$outputs")
          if ! jq -e 'any(.[]; .name == "HDMI-A-1" and .enabled)' <<< "$outputs" >/dev/null; then
            printf '%s\n' 'HDMI-A-1 is not active; connect and enable the projector first.' >&2
            exit 1
          fi
          exec wl-mirror --fullscreen-output HDMI-A-1 "$panel"
        '';
      })
    ];
}
