{ pkgs, inputs, ... }:
{
  environment.systemPackages =
    (import ../../../non-nixos/packages.nix { inherit pkgs; }).desktop
    ++ (with pkgs; [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      (callPackage ../../../non-nixos/pkgs/zen-browser.nix { zenInput = inputs.zen-browser; })
      discord
      imagemagick
      (writeShellApplication {
        name = "screenshot-desktop";
        runtimeInputs = with pkgs; [ grim slurp wl-clipboard coreutils ];
        text = builtins.readFile ../../scripts/screenshot.sh;
      })
      gnome-disk-utility
      seahorse
      sshfs
      glib
      curl
      jq
      file
      rsync
      zip
      unzip
      _7zz
    ]);

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
