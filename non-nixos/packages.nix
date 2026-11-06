# Shared selections; each host keeps its own services and integration.
{ pkgs }:
{
  desktop = with pkgs; [
    libreoffice
    hunspell
    hunspellDicts.en_US
    xournalpp
    mpv
    imv
    gimp
    grim
    slurp
    wl-clipboard
    (papers.override { supportNautilus = false; })
    file-roller
    gnome-calculator
    brightnessctl
    playerctl
  ];
  fonts = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
