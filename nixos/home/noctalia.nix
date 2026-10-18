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
  builtin = "${inputs.noctalia}/assets/templates";
  render = input: output: {
    input_path = "${input}";
    output_path = output;
  };
  zenApply = pkgs.writeShellApplication {
    name = "noctalia-zen-apply";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnused
    ];
    text = ''
      exec bash ${../pkgs}/zen-apply.sh ${lib.escapeShellArg "${community}/zen-browser/apply.sh"} ${lib.escapeShellArg "${zenControls}"}
    '';
  };
  zenControls = ../assets/zen-window-controls.css;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # Manual reconciliation previews changes unless --apply is supplied.
  home.packages = [
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
      theme.templates.user = {
        kitty = (render "${builtin}/kitty/kitty.conf" "${themeDir}/kitty.conf") // {
          post_hook = "${pkgs.procps}/bin/pkill -USR1 -x kitty || true";
        };
        umbriel = render ../assets/umbriel.toml "${themeDir}/umbriel.toml";
        vscode = render "${community}/vscode/vscode.json" "${themeDir}/vscode.json";
        steam = render "${community}/steam/steam.css" "${themeDir}/steam.css";
        zen_chrome =
          (render "${community}/zen-browser/zen-userChrome.css" "${config.xdg.cacheHome}/noctalia/zen-browser/zen-userChrome.css")
          // {
            post_hook = "${zenApply}/bin/noctalia-zen-apply";
            hook_async = false;
          };
        zen_content =
          (render "${community}/zen-browser/zen-userContent.css" "${config.xdg.cacheHome}/noctalia/zen-browser/zen-userContent.css")
          // {
            post_hook = "${zenApply}/bin/noctalia-zen-apply";
            hook_async = false;
          };
        fzf = render "${community}/fzf/fzf.sh" "${themeDir}/fzf.sh";
        lazygit = render "${community}/lazygit/lazygit.yml" "${themeDir}/lazygit.yml";
        nvim = render "${community}/neovim/matugen-template.lua" "${themeDir}/nvim.lua";
        bat =
          (render "${community}/bat/bat.tmTheme" "${config.xdg.configHome}/bat/themes/noctalia.tmTheme")
          // {
            post_hook = "${pkgs.bat}/bin/bat cache --build";
            hook_async = false;
          };
        btop =
          (render "${builtin}/btop/btop.theme" "${config.xdg.configHome}/btop/themes/noctalia.theme")
          // {
            post_hook = "${pkgs.procps}/bin/pkill -USR2 -x btop || true";
          };
        yazi = render "${community}/yazi/yazi.toml" "${config.xdg.configHome}/yazi/flavors/noctalia.yazi/flavor.toml";
        yazi_syntax = render "${community}/yazi/yazi.tmTheme" "${config.xdg.configHome}/yazi/flavors/noctalia.yazi/tmtheme.xml";
      };
    };

    # Umbriel starts the shell; no global service inside GNOME.
    systemd.enable = false;
  };

  # VSCodium only installs its theme watcher after a successful initial load.
  # Seed a missing palette with Noctalia itself, including in the GNOME fallback.
  home.activation.initializeNoctaliaVscode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e ${lib.escapeShellArg "${themeDir}/vscode.json"} && ! -L ${lib.escapeShellArg "${themeDir}/vscode.json"} ]]; then
      run mkdir -p ${lib.escapeShellArg themeDir}
      run ${config.programs.noctalia.package}/bin/noctalia theme ${../assets/wallpapers/dark-mountain.jpg} \
        --scheme ${lib.escapeShellArg config.programs.noctalia.settings.theme.wallpaper_scheme} \
        --render ${lib.escapeShellArg "${community}/vscode/vscode.json:${themeDir}/vscode.json"} -o /dev/null
    fi
  '';

  # Seed before HM's own batCache hook, including when Noctalia is not running.
  home.activation.initializeNoctaliaBat =
    lib.hm.dag.entryBetween [ "batCache" ] [ "linkGeneration" ]
      ''
        bat_theme=${lib.escapeShellArg "${config.xdg.configHome}/bat/themes/noctalia.tmTheme"}
        if [[ ! -e "$bat_theme" && ! -L "$bat_theme" ]]; then
          run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/bat/themes"}
          run ${config.programs.noctalia.package}/bin/noctalia theme ${../assets/wallpapers/dark-mountain.jpg} \
            --scheme ${lib.escapeShellArg config.programs.noctalia.settings.theme.wallpaper_scheme} \
            --render ${lib.escapeShellArg "${community}/bat/bat.tmTheme:${config.xdg.configHome}/bat/themes/noctalia.tmTheme"} -o /dev/null
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
