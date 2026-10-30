{ lib, isNixOS, ... }:
{
  imports = [ ./lazyvim.nix ./vscode.nix ];
  home.sessionVariables = lib.mkIf (!isNixOS) {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  home.file.".local/bin/editor-setup" = {
    enable = !isNixOS;
    executable = true;
    text = "#!/usr/bin/env bash\n" + builtins.readFile ../../pkgs/native-editor-setup.sh;
  };
}
