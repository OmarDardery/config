# Plain VSCodium, a Nix extension and the shared desktop theme.
{ pkgs, lib, config, isNixOS, desktopEnabled ? false, ... }:
let
  editorExtensions = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide
    editorconfig.editorconfig
  ];
  command = package: name: if isNixOS then "${package}/bin/${name}" else name;
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
in
{
  xdg.configFile."VSCodium/User/extensions.list" = {
    enable = !isNixOS;
    text = lib.concatMapStringsSep "\n" (e: "${e.vscodeExtPublisher}.${e.vscodeExtName}") editorExtensions + "\n";
  };
  home.file.".vscode-oss/extensions/noctalia.noctalia-1.0.0/package.json" = {
    enable = !isNixOS && desktopEnabled;
    text = builtins.toJSON {
      name = "noctalia";
      publisher = "noctalia";
      version = "1.0.0";
      engines.vscode = "^1.70.0";
      contributes.themes = [
        { id = "NoctaliaTheme"; label = "NoctaliaTheme"; uiTheme = "vs-dark"; path = "theme.json"; }
        { id = "NoctaliaLight"; label = "NoctaliaLight"; uiTheme = "vs"; path = "theme.json"; }
      ];
    };
  };
  home.file.".vscode-oss/extensions/noctalia.noctalia-1.0.0/theme.json" = {
    enable = !isNixOS && desktopEnabled;
    source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/noctalia/theme/vscode.json";
  };
  programs.vscodium = {
    enable = true;
    package = if isNixOS then pkgs.vscodium else null;
    mutableExtensionsDir = true;
    profiles.default = {
      extensions = lib.optionals isNixOS editorExtensions
        ++ lib.optional (isNixOS && desktopEnabled) noctaliaTheme;
      userSettings = {
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
        "nix.serverPath" = command pkgs.nixd "nixd";
        "nix.formatterPath" = command pkgs.nixfmt "nixfmt";
        "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
      };
    };
  };
}
