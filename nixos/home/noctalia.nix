# Noctalia: the bar, control center, lockscreen and wallpaper handling.
{
  inputs,
  pkgs,
  lib,
  config,
  isNixOS,
  profile,
  ...
}:
let
  plugins = pkgs.callPackage ../pkgs/noctalia-plugins.nix {
    src = inputs.noctalia-plugins;
  };
  settings = builtins.fromTOML (builtins.readFile ../dotfiles/noctalia/config.toml);
  reconcilePython = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  themeDir = "${config.xdg.stateHome}/noctalia/theme";
  community = inputs.noctalia-templates;
  builtin = "${inputs.noctalia}/assets/templates";
  render = input: output: {
    input_path = toString input;
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
      for root in "''${XDG_CONFIG_HOME:-$HOME/.config}/zen" "$HOME/.zen"; do
        [[ -d "$root" ]] || continue
        while IFS= read -r -d "" prefs; do
          profile_dir=$(dirname "$prefs")
          for file in "$profile_dir/user.js" "$profile_dir/chrome/userChrome.css" "$profile_dir/chrome/userContent.css"; do
            if [[ -f "$file" && ! -e "$file.noctalia-backup" ]]; then
              cp -p -- "$file" "$file.noctalia-backup"
            fi
          done
        done < <(find "$root" -mindepth 2 -maxdepth 2 -type f -name prefs.js -print0)
      done
      exec bash ${community}/zen-browser/apply.sh
    '';
  };
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # Opt-in reconciliation, not a hook that silently discards future GUI changes.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "noctalia-reconcile";
      text = ''
        exec ${reconcilePython}/bin/python3 ${../pkgs/reconcile-noctalia.py} \
          ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"} \
          ${lib.escapeShellArg "${config.xdg.configHome}/noctalia/config.toml"} "$@"
      '';
    })
  ];

  programs.noctalia = {
    enable = true;

    # Keep visual settings in TOML; adapt backend-specific fields declaratively.
    # Upstream checks this config during builds; warnings need review too.
    checkConfig = true;
    settings =
      lib.recursiveUpdate
        (
          settings
          // lib.optionalAttrs (!isNixOS) {
            widget = builtins.removeAttrs settings.widget [ "nix-monitor" ];
            plugin_settings = builtins.removeAttrs settings.plugin_settings [
              "avivbintangaringga/nix-monitor"
            ];
          }
        )
        {
          shell.polkit_agent = isNixOS;
          plugins.enabled = builtins.filter (
            id: isNixOS || id != "avivbintangaringga/nix-monitor"
          ) settings.plugins.enabled;
          bar.default.start = builtins.filter (id: isNixOS || id != "nix-monitor") settings.bar.default.start;
          plugin_settings = lib.optionalAttrs isNixOS {
            "avivbintangaringga/nix-monitor" = {
              update_command = "${pkgs.nh}/bin/nh os switch --hostname ${lib.escapeShellArg profile.hostName} ${lib.escapeShellArg "path:${profile.configRepo}"}";
              hide_clean_button = true;
              hide_optimize_button = true;
            };
          };
          theme.templates.user = {
            kitty.output_path = "${themeDir}/kitty.conf";
            umbriel = render ../dotfiles/noctalia/templates/umbriel.toml "${themeDir}/umbriel.toml";
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

  # The package comes from the module: homeModules.default sets
  # programs.noctalia.package to noctalia's own build with mkDefault, which is
  # what keeps the cachix substituter hitting. That is why it is no longer
  # listed by hand in desktop.nix.

  # Templates are immutable; all rendered palettes are writable runtime data.
  xdg.configFile."noctalia/templates".source = ../dotfiles/noctalia/templates;

  # VSCodium only installs its theme watcher after a successful initial load.
  # Seed a missing palette with Noctalia itself, including in the GNOME fallback.
  home.activation.initializeNoctaliaVscode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e ${lib.escapeShellArg "${themeDir}/vscode.json"} && ! -L ${lib.escapeShellArg "${themeDir}/vscode.json"} ]]; then
      run mkdir -p ${lib.escapeShellArg themeDir}
      run ${config.programs.noctalia.package}/bin/noctalia theme ${../dotfiles/Pictures/Wallpapers/dark-mountain.jpg} \
        --scheme ${lib.escapeShellArg config.programs.noctalia.settings.theme.wallpaper_scheme} \
        --render ${lib.escapeShellArg "${community}/vscode/vscode.json:${themeDir}/vscode.json"} -o /dev/null
    fi
  '';

  # Immutable local plugins take precedence over downloaded Git sources.
  # Tailscale is available but inactive while the host service is disabled.
  # Local discovery reads the manifests, so directory names need no author prefix.
  xdg.dataFile =
    lib.genAttrs
      (map (name: "noctalia/plugins/${name}") [
        "screen-toolkit"
        "nix-monitor"
        "phone-connect"
        "pomodoro"
        "tailscale"
        "game-launcher"
      ])
      (path: {
        source = "${plugins}/${lib.removePrefix "noctalia/plugins/" path}";
      });

  # The wallpapers config.toml points at. This is not decoration: theme.source
  # is "wallpaper", so the entire palette is generated from whichever of these
  # is selected. Without them deployed, a fresh machine gets no wallpaper and a
  # fallback palette instead of yours.
  #
  # config.toml refers to them by their ~/Pictures path rather than a store
  # path, because it is real TOML and cannot interpolate one. That also keeps
  # switching wallpapers from the noctalia UI working.
  #
  # Read-only, like the kitty tree, so adding a wallpaper means
  # dropping it in dotfiles/Pictures/Wallpapers and rebuilding.
  home.file."Pictures/Wallpapers".source = ../dotfiles/Pictures/Wallpapers;
}
