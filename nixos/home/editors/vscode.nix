{ pkgs, ... }:
{
  programs.vscodium = {
    enable = true;
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        editorconfig.editorconfig
      ];
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
        "workbench.colorTheme" = "Default Dark Modern";
        "workbench.preferredDarkColorTheme" = "Default Dark Modern";
        "workbench.preferredLightColorTheme" = "Default Light Modern";
        "telemetry.telemetryLevel" = "off";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";
        "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
      };
    };
  };
}
