# Noctalia: the bar, control center, lockscreen and wallpaper handling.
{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  plugins = pkgs.callPackage ../pkgs/noctalia-plugins.nix {
    src = inputs.noctalia-plugins;
  };
  settings = import ./noctalia-settings.nix;
  appThemes = import ../pkgs/noctalia-app-themes.nix {
    inherit pkgs lib;
    cacheHome = config.xdg.cacheHome;
    templates = inputs.noctalia-templates;
  };
  reconcilePython = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);

in
{
  programs.noctalia = {
    enable = true;
    package = null;
    systemd.enable = false;
    # The native executable validates generated files in the theme-rendering check.
    checkConfig = false;
    settings = lib.recursiveUpdate settings {
      # Later sources win; the patched Nix plugins override Git catalog copies.
      plugins.source = [
        {
          name = "official";
          kind = "git";
          location = "https://github.com/noctalia-dev/official-plugins";
          enabled = true;
        }
        {
          name = "community";
          kind = "git";
          location = "https://github.com/noctalia-dev/community-plugins";
          enabled = true;
        }
        {
          name = "nix-managed";
          kind = "path";
          location = "${plugins}";
          enabled = true;
        }
      ];
      plugin_settings = {
        "avivbintangaringga/nix-monitor" = {
          update_command = config.home.shellAliases.update;
          hide_clean_button = false;
          hide_optimize_button = false;
        };
      };
      theme.templates.user = import ./noctalia-templates.nix {
        inherit
          inputs
          pkgs
          lib
          config
          ;
      };
    };

  };

  home.file.".local/bin/noctalia-apply-libreoffice-theme".source =
    "${appThemes.libreoffice}/bin/noctalia-apply-libreoffice-theme";
  home.file.".local/bin/noctalia-reconcile" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec ${reconcilePython}/bin/python3 ${../pkgs}/reconcile-noctalia.py \
        ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"} \
        ${lib.escapeShellArg "${config.xdg.configHome}/noctalia/config.toml"} "$@"
    '';
  };
  home.file.".local/bin/desktop-apply" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      command -v noctalia >/dev/null || { echo "Install Noctalia using the host distribution first." >&2; exit 1; }
      ${pkgs.python3}/bin/python3 ${../pkgs/seed-noctalia.py} \
        "$(command -v noctalia)" ${config.xdg.configFile."noctalia/config.toml".source} \
        ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"} \
        ${lib.escapeShellArg "${config.home.homeDirectory}/Pictures/Wallpapers"} ${../assets/wallpapers}
      state=${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"}
      if [[ -f "$state" ]]; then
        ${reconcilePython}/bin/python3 ${../pkgs}/reconcile-noctalia.py \
          "$state" ${config.xdg.configFile."noctalia/config.toml".source} --managed --apply \
          --reset theme.templates.user.fastfetch --reset theme.templates.user.inkscape
      fi
      if command -v bat >/dev/null 2>&1; then bat cache --build; fi
      if command -v xfconf-query >/dev/null 2>&1; then
        xfconf-query -c thunar -p /misc-volume-management --create --type bool --set true
        for property in automount-drives/enabled automount-media/enabled autobrowse/enabled; do
          xfconf-query -c thunar-volman -p "/$property" --create --type bool --set true
        done
      fi
    '';
  };

  # Link bundled samples individually into a writable personal wallpaper folder.
  xdg.dataFile."noctalia/wallpaper-samples".source = ../assets/wallpapers;
  home.activation.noctaliaWallpaperSamples = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/Pictures/Wallpapers"}
    ${lib.concatMapStringsSep "\n" (
      name:
      let
        target = "${config.home.homeDirectory}/Pictures/Wallpapers/${name}";
      in
      ''
        if [[ ! -e ${lib.escapeShellArg target} && ! -L ${lib.escapeShellArg target} ]]; then
          run ln -s ${lib.escapeShellArg "${config.xdg.dataHome}/noctalia/wallpaper-samples/${name}"} ${lib.escapeShellArg target}
        fi
      ''
    ) (builtins.attrNames (builtins.readDir ../assets/wallpapers))}
  '';
}
