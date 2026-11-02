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
    glib
    brightnessctl
    playerctl
  ];
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
  programs.ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
}
