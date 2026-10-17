# Dependencies used by Noctalia's Screen Toolkit and editor image previews.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    slurp
    grim
    hyprpicker
    (tesseract.override {
      enableLanguages = [
        "eng"
        "ara"
      ];
    })
    imagemagick
    zbar
    bc
    pulseaudio # pactl client only; the host runs PipeWire
    procps
    wl-clipboard
    gpu-screen-recorder
    wl-screenrec
    wf-recorder # Screen Toolkit's fallback recorder
    ffmpeg
    swappy # Screen Toolkit's primary annotation editor
    translate-shell
  ];
}
