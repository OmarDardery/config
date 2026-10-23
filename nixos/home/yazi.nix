{
  lib,
  desktopEnabled ? false,
  ...
}:
{
  programs.yazi = {
    enable = true;
    package = null;
    # The shared shell dotfiles provide y() for both native Bash and Zsh.
    enableBashIntegration = false;
    enableZshIntegration = false;
    shellWrapperName = "y";
    settings.mgr = {
      show_hidden = false;
      sort_by = "natural";
      sort_dir_first = true;
    };
    theme.flavor = lib.mkIf desktopEnabled {
      dark = "noctalia";
      light = "noctalia";
    };
  };
}
