{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    (callPackage ../pkgs/zen-browser.nix { zenInput = inputs.zen-browser; })
    (callPackage ../pkgs/jetbrains-toolbox.nix { })
    discord
    proton-vpn
    libreoffice
    hunspell
    hunspellDicts.en_US
    xournalpp
    mpv
    imv
    gimp
    inkscape
    simple-scan
    wireshark
  ];

  home.sessionVariables = {
    BROWSER = "zen";
    # GTK3 preserves output selection for Impress presentations over HDMI.
    SAL_USE_VCLPLUGIN = "gtk3";
  };
}
