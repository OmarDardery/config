# Plain VSCodium, a Nix extension and the shared desktop theme.
{ pkgs, lib, config, isNixOS, desktopEnabled ? false, ... }:
let
  editorExtensions = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide
    editorconfig.editorconfig
  ];
  # Noctalia must render this file before the theme's first use. Keep the
  # manifest path inside the extension; only the symlink points outside it.
  noctaliaTheme = pkgs.vscode-utils.buildVscodeExtension {
    pname = "noctalia";
    version = "1.0.0";
    vscodeExtPublisher = "noctalia";
    vscodeExtName = "noctalia";
    vscodeExtUniqueId = "noctalia.noctalia";
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase =
      let
        manifest = pkgs.writeText "noctalia-package.json" (
          builtins.toJSON {
            name = "noctalia";
            displayName = "Noctalia";
            publisher = "noctalia";
            version = "1.0.0";
            engines.vscode = "^1.70.0";
            categories = [ "Themes" ];
            contributes.themes = [
              {
                id = "NoctaliaTheme";
                label = "NoctaliaTheme";
                uiTheme = "vs-dark";
                path = "themeJsonSymlink.json";
                _watch = true;
              }
              {
                id = "NoctaliaLight";
                label = "NoctaliaLight";
                uiTheme = "vs";
                path = "themeJsonSymlink.json";
                _watch = true;
              }
            ];
          }
        );
      in
      ''
        runHook preInstall
        mkdir -p "$out/$installPrefix"
        cp ${manifest} "$out/$installPrefix/package.json"
        ln -s ${pkgs.lib.escapeShellArg "${config.xdg.stateHome}/noctalia/theme/vscode.json"} \
          "$out/$installPrefix/themeJsonSymlink.json"
        runHook postInstall
      '';
  };
  settings = {
    "editor.lineNumbers" = "relative";
    "editor.cursorSurroundingLines" = 8;
    "editor.minimap.enabled" = false;
    "editor.formatOnSave" = true;
    "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace";
    "editor.fontSize" = 14;
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "terminal.integrated.scrollback" = 10000;
    "window.titleBarStyle" = "custom";
    "window.controlsStyle" = "hidden";
    "window.autoDetectColorScheme" = true;
    "workbench.colorTheme" = if desktopEnabled then "NoctaliaTheme" else "Default Dark Modern";
    "workbench.preferredDarkColorTheme" = if desktopEnabled then "NoctaliaTheme" else "Default Dark Modern";
    "workbench.preferredLightColorTheme" = if desktopEnabled then "NoctaliaLight" else "Default Light Modern";
    "telemetry.telemetryLevel" = "off";
    "update.mode" = "none";
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nixd";
    "nix.formatterPath" = "nixfmt";
    "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
  };
  userDefaults = pkgs.linkFarm "codium-user-starter" [{
    name = "settings.json";
    path = pkgs.writeText "codium-settings.json" (builtins.toJSON settings);
  }];
  extensionDefaults = pkgs.linkFarm "codium-extension-starter" (
    map (extension: {
      name = extension.vscodeExtUniqueId
        + lib.optionalString (!isNixOS && extension.vscodeExtUniqueId == "noctalia.noctalia") "-1.0.0";
      path = "${extension}/share/vscode/extensions/${extension.vscodeExtUniqueId}";
    }) (lib.optionals isNixOS editorExtensions ++ lib.optional desktopEnabled noctaliaTheme)
  );
  manifest = pkgs.writeText "codium-starter.json" (builtins.toJSON {
    directories = {
      "${config.xdg.configHome}/VSCodium/User" = "${userDefaults}";
      "${config.home.homeDirectory}/.vscode-oss/extensions" = "${extensionDefaults}";
    };
    extensionIndex = "${config.home.homeDirectory}/.vscode-oss/extensions/extensions.json";
  });
in
{
  # The application owns settings, profiles, keybindings and all installed extensions.
  home.packages = lib.optionals isNixOS [ pkgs.vscodium ];
  xdg.dataFile."editor-defaults/extensions.list" = {
    enable = !isNixOS;
    text = lib.concatMapStringsSep "\n" (e: "${e.vscodeExtPublisher}.${e.vscodeExtName}") editorExtensions + "\n";
  };
  home.activation.mutableVSCodium = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${../../pkgs}/migrate-desktop.py editor-defaults \
      ${manifest} ${lib.escapeShellArg "${config.xdg.stateHome}/editor-defaults/codium"}
  '';
}
