{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    (callPackage ../../pkgs/zen-browser.nix { zenInput = inputs.zen-browser; })
    discord
    proton-vpn
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
    imagemagick
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

  environment.sessionVariables = {
    BROWSER = "zen";
    # GTK3 preserves output selection for Impress presentations over HDMI.
    SAL_USE_VCLPLUGIN = "gtk3";
  };
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
  programs.ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
}
