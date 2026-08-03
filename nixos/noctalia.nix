{ pkgs, inputs, ... }:
{
  programs.gpu-screen-recorder.enable = true;
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  # capture / selection
    slurp
    grim
    hyprpicker
  # processing
    tesseract        # OCR (all language packs by default)
    imagemagick
    zbar             # zbarimg for QR/barcode
    bc

  # network / opening
    curl
    jq
    xdg-utils
    wl-clipboard

  # recording
    wl-screenrec     # region recording + mic audio
    wf-recorder      # fallback
    ffmpeg           # also provides ffprobe

  # annotation + extras
    swappy
    satty
    translate-shell  # `trans`, for OCR translation
  ];
}
