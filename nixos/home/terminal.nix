{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}:
{
  # Noctalia writes kitty.conf and themes/noctalia.conf. Preserve existing edits
  # and back up the old directory link before making its configuration writable.
  home.activation.kittyDirectoryMigration =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        run ${pkgs.python3}/bin/python3 ${../pkgs}/migrate-desktop.py kitty-directory \
          ${lib.escapeShellArg "${config.xdg.configHome}/kitty"}
      '';
  home.activation.kittyWritableConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.python3}/bin/python3 ${../pkgs}/migrate-desktop.py kitty \
      ${lib.escapeShellArg "${config.xdg.configHome}/kitty/kitty.conf"} ${../dotfiles/kitty/kitty.conf} \
      ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/theme/kitty.conf"}
  '';

  home.packages =
    (with pkgs; [
      kitty
      curl
      wget
      jq
      file
      rsync
      zip
      unzip
      _7zz
      fastfetch
      lshw
      usbutils
      pciutils
      lsof
      strace
      sysstat
      smartmontools
      nvme-cli
      dnsutils
      nmap
      iperf3
      ethtool
    ])
    ++ lib.optional (!isNixOS) pkgs.mtr;
}
