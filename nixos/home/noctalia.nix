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
  reconcilePython = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  community = inputs.noctalia-templates;
  appThemes = import ../pkgs/noctalia-app-themes.nix {
    inherit pkgs lib config;
    templates = community;
  };

in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # Manual reconciliation previews changes unless --apply is supplied.
  home.packages = [
    appThemes.libreoffice
    (pkgs.writeShellApplication {
      name = "noctalia-reconcile";
      text = ''
        exec ${reconcilePython}/bin/python3 ${../pkgs}/reconcile-noctalia.py \
          ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"} \
          ${lib.escapeShellArg "${config.xdg.configHome}/noctalia/config.toml"} "$@"
      '';
    })
  ];

  programs.noctalia = {
    enable = true;

    # Keep preferences in Nix and application palettes in writable state files.
    # Upstream checks this config during builds; warnings need review too.
    checkConfig = true;
    settings = lib.recursiveUpdate settings {
      # Later sources win: keep the patched Nix plugins ahead of Git catalog copies.
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

    # Umbriel owns the shell lifecycle.
    systemd.enable = false;
  };

  # Only seed missing palettes, using saved runtime choices where available.
  home.activation.initializeNoctaliaTemplates =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        run ${pkgs.python3}/bin/python3 ${../pkgs}/seed-noctalia.py \
          ${config.programs.noctalia.package}/bin/noctalia \
          ${config.xdg.configFile."noctalia/config.toml".source} \
          ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/Pictures/Wallpapers"} \
          ${../assets/wallpapers}
      '';

  # GUI edits preview a setting until the next rebuild. Keep runtime-only keys
  # (e.g. theme mode/current wallpaper) and back up any overridden preferences.
  home.activation.noctaliaDeclarativeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    state=${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"}
    if [[ -e "$state" || -L "$state" ]]; then
      run ${reconcilePython}/bin/python3 ${../pkgs}/reconcile-noctalia.py \
        "$state" ${config.xdg.configFile."noctalia/config.toml".source} --managed --apply
    fi
  '';

  # Remove the former managed directory link, then keep a writable folder.
  # Bundled samples are individual links; personal files are never replaced.
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
