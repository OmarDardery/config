{
  pkgs,
  lib,
  isNixOS,
  ...
}:
{
  programs.zellij = {
    enable = true;
    # Kitty starts one workspace; shell auto-start would nest it in every pane.
    settings = {
      default_shell = "${pkgs.zsh}/bin/zsh";
      default_layout = "compact";
      default_mode = "locked";
      on_force_close = "detach";
      theme = lib.mkIf isNixOS "noctalia";
    };
    layouts.dev = ''
      layout {
        default_tab_template {
          children
          pane size=1 borderless=true {
            plugin location="zellij:compact-bar"
          }
        }
        tab name="Code" focus=true {
          pane command="nvim"
        }
        tab name="Files" {
          pane command="yazi"
        }
        tab name="Git" {
          pane command="lazygit"
        }
        tab name="Shell" {
          pane
        }
      }
    '';
  };

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

  home.shellAliases = {
    zj = "zellij";
    za = "zellij attach";
    zl = "zellij list-sessions";
    zdev = "zellij --layout dev";
  };
}
