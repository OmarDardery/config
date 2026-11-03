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
      userSettings =
        builtins.fromJSON (builtins.readFile ../../../non-nixos/dotfiles/VSCodium/User/settings.json)
        // {
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
          "nix.formatterPath" = "nixfmt";
          "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
    };
  };
}
