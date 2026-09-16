{ pkgs, ... }:
{
  # The play/pause/skip buttons on Bluetooth headphones speak AVRCP, which
  # nothing on the desktop listens to by default — so pressing them on the Sony
  # set did nothing. mpris-proxy is BlueZ's own bridge from AVRCP to MPRIS,
  # which is the bus playerctl and the noctalia bar already use.
  services.mpris-proxy.enable = true;

  # Raw config trees, deployed as read-only symlinks into ~/.config.
  xdg.configFile."niri".source = ../dotfiles/niri;
  xdg.configFile."kitty".source = ../dotfiles/kitty;

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

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono

    # Arabic. The locale is ar_EG and the keyboard is "us,ara", but nothing
    # shipped an Arabic face — fontconfig was falling back to DejaVu Sans,
    # which has no Arabic coverage, so Arabic rendered as boxes everywhere.
    noto-fonts

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
    # because niri ships none of it.
    #
    # nwg-displays is the GUI: it drives wlr-output-management and can write
    # niri output blocks directly. Note cfg/outputs.kdl here is a read-only
    # store symlink, so let it save elsewhere and copy the numbers in by hand.
    nwg-displays
    wlr-randr # the same thing for scripts and one-off queries
    # Mirroring, which niri has no native support for. Still the right tool for
    # a projector that will not take an extended desktop — but with the
    # SAL_USE_VCLPLUGIN fix in ./apps.nix, presenting no longer needs it.
    wl-mirror

    # network / opening
    curl
    jq
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
  ];
}
