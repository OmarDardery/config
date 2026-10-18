{
  lib,
  isNixOS,
  ...
}:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings.mgr = {
      show_hidden = false;
      sort_by = "natural";
      sort_dir_first = true;
    };
    theme.flavor = lib.mkIf isNixOS {
      dark = "noctalia";
      light = "noctalia";
    };
  };
}
