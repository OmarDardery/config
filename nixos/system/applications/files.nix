{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (papers.override { supportNautilus = false; })
    file-roller
    gnome-calculator
    gnome-disk-utility
    seahorse
    sshfs
    xdg-utils
    xfconf
    zenity
    system-config-printer
    adwaita-icon-theme
    adw-gtk3
    bibata-cursors
    glib
    dconf
    pavucontrol
    brightnessctl
    playerctl
    kdePackages.kdeconnect-kde
    bluez
  ];
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
  programs.ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };
}
