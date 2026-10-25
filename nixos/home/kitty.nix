# Terminal behavior is declarative; Noctalia writes only the included palette.
{
  pkgs,
  lib,
  config,
  isNixOS,
  profile,
  ...
}:
{
  programs.kitty = {
    enable = true;
    package = null;
    # The shared shell files are plain dotfiles, so let Kitty load its own
    # integration instead of HM emitting no-rc and injecting disabled modules.
    shellIntegration.mode = null;
    font = {
      name = if isNixOS then "JetBrainsMono Nerd Font" else "JetBrains Mono";
      size = 14;
    };
    settings = {
      shell = "zsh";
      shell_integration = "enabled";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      background_opacity = "0.84";
      dynamic_background_opacity = true;
      cursor_trail = 1;
      enable_audio_bell = false;
      update_check_interval = 0;
      confirm_os_window_close = -1;
      scrollback_lines = 20000;
      scrollback_pager_history_size = 32;
      window_padding_width = 10;
      initial_window_width = "95c";
      initial_window_height = "35c";
      enabled_layouts = "splits,stack,tall";
      tab_bar_style = "powerline";
      tab_bar_min_tabs = 2;
      tab_title_template = "{index}: {title}";
    };
    keybindings = {
      "ctrl+shift+enter" = "launch --cwd=current";
      "ctrl+shift+d" = "combine : goto_layout splits : launch --location=hsplit --cwd=current";
      "ctrl+shift+alt+d" = "combine : goto_layout splits : launch --location=vsplit --cwd=current";
      "ctrl+shift+t" = "launch --type=tab --cwd=current";
      "ctrl+shift+n" = "launch --type=os-window --cwd=current";
      "ctrl+shift+j" = "next_window";
      "ctrl+shift+k" = "previous_window";
      "ctrl+shift+z" = "toggle_layout stack";
      "ctrl+shift+f2" =
        "launch --type=overlay nvim ${lib.escapeShellArg "${profile.configRepo}/home/kitty.nix"}";
      "ctrl+shift+u" = "kitten hints --type url";
    };
    # A missing palette on the first launch is harmless; Kitty's defaults apply.
    extraConfig = "include ${config.xdg.stateHome}/noctalia/theme/kitty.conf";
  };

  # Preserve the former writable configuration before HM takes ownership.
  xdg.configFile."kitty/kitty.conf".force = true;
  home.activation.kittyDeclarativeConfig =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        run ${pkgs.python3}/bin/python3 ${../pkgs}/migrate-desktop.py kitty-declarative \
          ${lib.escapeShellArg "${config.xdg.configHome}/kitty/kitty.conf"} \
          ${config.xdg.configFile."kitty/kitty.conf".source}
      '';
}
