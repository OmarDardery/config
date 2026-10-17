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
    input_path = "${input}";
    output_path = output;
  };
  nixosUpdate = pkgs.callPackage ../pkgs/nixos-update.nix { };
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
  zenControls = ../dotfiles/zen/zen-window-controls.css;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # Opt-in reconciliation, not a hook that silently discards future GUI changes.
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
          plugins.enabled =
            builtins.filter (id: isNixOS || id != "avivbintangaringga/nix-monitor") settings.plugins.enabled
            ++ lib.optional isNixOS "davemhammer/tailscale";
          bar.default.start = builtins.filter (id: isNixOS || id != "nix-monitor") settings.bar.default.start;
          plugin_settings = lib.optionalAttrs isNixOS {
            "avivbintangaringga/nix-monitor" = {
              update_command = "${nixosUpdate}/bin/nixos-update ${lib.escapeShellArg profile.configRepo} ${lib.escapeShellArg profile.hostName}";
              hide_clean_button = false;
              hide_optimize_button = false;
            };
          };
          theme.templates.user = {
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

  # Seed before HM's own batCache hook, including when Noctalia is not running.
  home.activation.initializeNoctaliaBat =
    lib.hm.dag.entryBetween [ "batCache" ] [ "linkGeneration" ]
      ''
        bat_theme=${lib.escapeShellArg "${config.xdg.configHome}/bat/themes/noctalia.tmTheme"}
        if [[ ! -e "$bat_theme" && ! -L "$bat_theme" ]]; then
          run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/bat/themes"}
          run ${config.programs.noctalia.package}/bin/noctalia theme ${../dotfiles/Pictures/Wallpapers/dark-mountain.jpg} \
            --scheme ${lib.escapeShellArg config.programs.noctalia.settings.theme.wallpaper_scheme} \
            --render ${lib.escapeShellArg "${community}/bat/bat.tmTheme:${config.xdg.configHome}/bat/themes/noctalia.tmTheme"} -o /dev/null
        fi
      '';

  # Migrate saved GUI state to the builtin while preserving other selections.
  home.activation.noctaliaKittyTemplate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${reconcilePython}/bin/python3 ${../pkgs}/migrate-desktop.py noctalia \
      ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/settings.toml"} \
      ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/.kitty-template-v1"}
  '';

  # Immutable local plugins take precedence over downloaded Git sources.
  # Tailscale controls are enabled on NixOS alongside the host service.
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
  # Read-only, so adding a wallpaper means
  # dropping it in dotfiles/Pictures/Wallpapers and rebuilding.
  home.file."Pictures/Wallpapers".source = ../dotfiles/Pictures/Wallpapers;
}
