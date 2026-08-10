{ pkgs, inputs, ... }:
{
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

    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

    # capture / selection
    slurp
    grim
    hyprpicker

    # processing
    tesseract # OCR (all language packs by default)
    imagemagick
    zbar # zbarimg for QR/barcode
    bc

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
