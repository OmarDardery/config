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
    wireshark
  ];

  environment.sessionVariables = {
    BROWSER = "zen";
    # GTK3 preserves output selection for Impress presentations over HDMI.
    SAL_USE_VCLPLUGIN = "gtk3";
  };
}
