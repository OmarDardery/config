# Shared terminal defaults; Noctalia writes only the optional runtime palette.
{
  lib,
  config,
  profile,
  ...
}:
{
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ../../non-nixos/dotfiles/kitty/kitty.conf + ''
      include ${config.xdg.stateHome}/noctalia/theme/kitty.conf
    '';
    keybindings."ctrl+shift+f2" =
      "launch --type=overlay nvim ${lib.escapeShellArg "${profile.configRepo}/non-nixos/dotfiles/kitty/kitty.conf"}";
  };
}
