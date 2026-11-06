{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    kitty
    starship
    zsh
    xournalpp
    libreoffice
    hunspell
    hunspellDicts.en_US
    (papers.override { supportNautilus = false; })
    thunar
    file-roller
    gnome-calculator
    mpv
    imv
    keepassxc
    gimp
    grim
    slurp
    wl-clipboard
    xclip
    brightnessctl
    playerctl
    pavucontrol
    btop
    zoxide
    direnv
    unzip
    _7zz
    inter
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    BROWSER = "firefox";
    TERMINAL = "kitty";
    SAL_USE_VCLPLUGIN = "gtk3";
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "inode/directory" = [ "thunar.desktop" ];
      "application/pdf" = [ "org.gnome.Papers.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "text/plain" = [ "codium.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/jpeg" = [ "imv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
    };
  };
}
