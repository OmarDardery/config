{
  pkgs,
  config,
  profile,
  ...
}:
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
      userSettings = builtins.fromJSON (builtins.readFile ../../dotfiles/VSCodium/User/settings.json) // {
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.profiles.linux".zsh = {
          path = "${pkgs.zsh}/bin/zsh";
          args = [ "-l" ];
        };
        "terminal.integrated.env.linux".ZDOTDIR = profile.zshHome or config.home.homeDirectory;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";
        "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
      };
    };
  };
}
