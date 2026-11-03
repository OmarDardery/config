# Native Noctalia capture, clipboard tools and editor image previews.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    grim
    slurp
    wl-clipboard
    imagemagick
  ];
}
