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
  themeDir = "${config.xdg.stateHome}/noctalia/theme";
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

  # Seed missing generated palettes before applications observe new HM links.
  # Explicit --render performs no apply hooks or application preference changes.
  home.activation.initializeNoctaliaTemplates =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        noctalia_renders=()
        ${lib.concatMapStringsSep "\n" (
          name:
          let
            template = config.programs.noctalia.settings.theme.templates.user.${name};
          in
          ''
            if [[ ! -e ${lib.escapeShellArg template.output_path} && ! -L ${lib.escapeShellArg template.output_path} ]]; then
              run mkdir -p ${lib.escapeShellArg (builtins.dirOf template.output_path)}
              noctalia_renders+=(--render ${lib.escapeShellArg "${template.input_path}:${template.output_path}"})
            fi
          ''
        ) (builtins.attrNames config.programs.noctalia.settings.theme.templates.user)}
        if (( ''${#noctalia_renders[@]} > 0 )); then
          run ${config.programs.noctalia.package}/bin/noctalia theme ${../assets/wallpapers/dark-mountain.jpg} \
            --scheme ${lib.escapeShellArg config.programs.noctalia.settings.theme.wallpaper_scheme} \
            "''${noctalia_renders[@]}" -o /dev/null
        fi
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

  # Paths stay portable through the shell's ~ expansion. Add wallpapers here
  # and rebuild; the selected wallpaper and generated palettes remain writable.
  home.file."Pictures/Wallpapers".source = ../assets/wallpapers;
}
