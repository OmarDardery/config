{ pkgs, ... }:
{
  # Bluetooth, Thunar, dconf and portals install their own integration packages.
  environment.systemPackages = with pkgs; [
    (papers.override { supportNautilus = false; })
    file-roller
    gnome-calculator
    gnome-disk-utility
    seahorse
    sshfs
    zenity
    adwaita-icon-theme
    adw-gtk3
    bibata-cursors
    glib
    pavucontrol
    brightnessctl
    playerctl
    kdePackages.kdeconnect-kde
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
