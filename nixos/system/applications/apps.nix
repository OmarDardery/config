{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    (callPackage ../../pkgs/zen-browser.nix { zenInput = inputs.zen-browser; })
    (callPackage ../../pkgs/jetbrains-toolbox.nix { })
    discord
    proton-vpn
    libreoffice
    hunspell
    hunspellDicts.en_US
    xournalpp
    mpv
    imv
    gimp
    simple-scan
    wireshark
  ];

  environment.sessionVariables = {
    BROWSER = "zen";
    # GTK3 preserves output selection for Impress presentations over HDMI.
    SAL_USE_VCLPLUGIN = "gtk3";
  };
}
