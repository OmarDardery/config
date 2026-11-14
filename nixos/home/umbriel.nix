{
  config,
  lib,
  isLaptop,
  profile,
  ...
}:
let
  display = import ../lib/display.nix;
  once = action: {
    inherit action;
    repeat = false;
  };
  locked = command: {
    action = "spawn noctalia msg ${command}";
    allow_when_locked = true;
  };
  rowAction = action: "window-${action}";
in
{
  programs.umbriel = {
    enable = true;
    package = null;
    settings = {
      # No independent palette: Noctalia owns colors; native defaults before rendering.
      include.optional.files = [ "${config.xdg.stateHome}/noctalia/theme/umbriel.toml" ];
      general = {
        autostart = [ "noctalia" ];
        mod_key = "Super";
        show_cheatsheet = false;
        focus_on_activate = true;
      };
      input = {
        # Desktop-style focus and pointer controls.
        client_window_drag = true;
        mod_right_double_click = "maximize";
        keyboard = {
          layout = "us,ara";
          options = "grp:alt_shift_toggle";
          numlock_toggle = true;
        };
        touchpad = {
          tap = true;
          natural_scroll = true;
        };
        mouse.accel_profile = "flat";
        focus = {
          follows_mouse = "sloppy";
        };
        cursor = {
          theme = config.home.pointerCursor.name;
          size = config.home.pointerCursor.size;
          hide_when_typing = true;
        };
      };
      workspaces = {
        back_and_forth = true;
        empty_above = false;
      };
      scratchpad = [
        { name = "stash"; }
        {
          name = "terminal";
          spawn_when_empty = "kitty --class scratchpad-terminal";
        }
        {
          name = "calculator";
          spawn_when_empty = "gnome-calculator";
        }
      ];
      layout = {
        # Default to master tiling; switch to floating/stacking with Super+D.
        mode = "master";
        gap = 10;
        extent_presets = [
          0.33333
          0.5
          0.66667
        ];
        stacking.drop_zones = true;
        master = {
          position = "left";
          default_width_fraction = 0.60;
          new_on_top = true;
          new_becomes_master = false;
        };
        tabs = {
          default_display = "normal";
          wrap_focus = false;
        };
      };
      appearance = {
        prefer_no_csd = true;
        title_bar.mode = "on";
        border_width = 2;
        outer_border_width = 0;
        corner_radius = 16;
        drag_opacity = 0.95;
        blur = {
          enabled = true;
          passes = 2;
          radius = 6;
          noise = 0.015;
          brightness = 1.0;
          contrast = 1.0;
          saturation = 1.15;
        };
        shadow = {
          enabled = true;
          softness = 28;
          offset_x = 0;
          offset_y = 8;
        };
        tab_bar = {
          style = "indicator";
          position = "right";
          height = 2;
          hide_when_single = true;
          tab_gap = 2;
          corner_radius = 4;
        };
      };
      animation = {
        enabled = true;
        curve = "spring:1,1100";
        windows_in = {
          style = "popin";
          curve = "spring:1,1200";
          scale = 0.96;
        };
        windows_out = {
          style = "popin";
          curve = "spring:1,1200";
          scale = 0.94;
        };
        workspaces = {
          style = "slide";
          curve = "spring:1,1000";
        };
        overview = {
          curve = "spring:1,1000";
          workspace_curve = "spring:1,1100";
        };
        windows_drag.physics = false;
        border.curve = "spring:1,1000";
        scratchpad = {
          dim = 0.35;
          blur = true;
        };
      };
      environment = {
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "kde";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };
      # Explicit navigation takes precedence over Umbriel's built-in bindings.
      keybinds = {
        "Mod+Shift+Escape" = once "cheatsheet-open";
        "Mod+T" = once "spawn kitty";
        "Mod+grave" = once "scratchpad-toggle terminal";
        "Mod+Ctrl+Return" = once "scratchpad-toggle calculator";
        "Mod+Ctrl+P" = once "spawn noctalia msg notification-dnd-set on && noctalia msg caffeine-enable";
        "Mod+Ctrl+Shift+P" =
          once "spawn noctalia msg caffeine-disable && noctalia msg notification-dnd-set off";
        "Mod+Space" = once "spawn noctalia msg panel-toggle launcher";
        "Alt+Tab" = once "spawn noctalia msg window-switcher hold";
        "Mod+B" = once "spawn zen";
        "Mod+Alt+L" = once "spawn noctalia msg session lock";
        "Mod+Shift+Q" = once "spawn noctalia msg panel-toggle session";
        "XF86PowerOff" = (locked "session lock") // {
          repeat = false;
          allow_when_inhibited = true;
        };
        "Mod+Shift+F23" = once "spawn kitty";
        "Mod+E" = once "spawn thunar";
        "Mod+Shift+E" = once "spawn kitty yazi";
        "Mod+I" = once "spawn codium";
        "Mod+Ctrl+E" = once "spawn kitty nvim ${lib.escapeShellArg profile.configRepo}";
        "Mod+Shift+D" = once "spawn nwg-displays";
        "Mod+A" = once "spawn noctalia msg panel-toggle control-center";
        "Mod+Ctrl+S" = once "spawn noctalia msg settings-toggle";
        "Mod+V" = once "spawn noctalia msg panel-toggle clipboard";
        "Mod+N" = once "spawn noctalia msg panel-toggle notifications";
        "Mod+Shift+N" = once "spawn noctalia msg notification-dnd-toggle";
        "Mod+Ctrl+N" = once "spawn noctalia msg notification-clear-active";
        "Mod+Alt+W" = once "spawn noctalia msg panel-toggle wallpaper";
        "Mod+Ctrl+Alt+W" = once "spawn noctalia msg settings-open theme";
        "Mod+Alt+Right" = "column-focus-tab-next";
        "Mod+Alt+Left" = "column-focus-tab-previous";
        "Mod+Alt+C" = once "spawn noctalia msg caffeine-toggle";
        "Mod+Alt+N" = once "spawn noctalia msg nightlight-force-toggle";
        "Mod+Alt+D" = once "spawn noctalia msg theme-mode-toggle";
        "Mod+Alt+P" = once "spawn noctalia msg power-cycle";
        "Mod+Alt+A" = once "spawn noctalia msg panel-toggle control-center audio";
        "Mod+Alt+B" = once "spawn noctalia msg panel-toggle control-center bluetooth";
        "Mod+Alt+E" = once "spawn noctalia msg panel-toggle launcher /emo";
        "Mod+Ctrl+Shift+R" = once "config-reload";
        "Print" = once "spawn screenshot-desktop region";
        "Mod+Shift+S" = once "spawn screenshot-desktop region";
        "Shift+Print" = once "spawn screenshot-desktop fullscreen";
        "Ctrl+Print" = once "spawn noctalia msg screenshot-window";
        "Mod+P" = once "window-toggle-pinned";
        "Alt+Print" = once "spawn noctalia msg screenshot-annotate";

        "XF86AudioRaiseVolume" = locked "volume-up";
        "XF86AudioLowerVolume" = locked "volume-down";
        "XF86AudioMute" = (locked "volume-mute") // {
          repeat = false;
        };
        "XF86AudioMicMute" = (locked "mic-mute") // {
          repeat = false;
        };
        "XF86AudioNext" = locked "media next";
        "XF86AudioPrev" = locked "media previous";
        "XF86AudioPlay" = (locked "media toggle") // {
          repeat = false;
        };
        "XF86AudioPause" = (locked "media toggle") // {
          repeat = false;
        };
        "XF86MonBrightnessUp" = locked "brightness-up";
        "XF86MonBrightnessDown" = locked "brightness-down";

        "Mod+Q" = once "window-close";
        "Mod+Left" = "window-focus-left";
        "Mod+H" = "window-focus-left";
        "Mod+Right" = "window-focus-right";
        "Mod+L" = "window-focus-right";
        "Mod+Up" = "workspace-previous";
        "Mod+K" = rowAction "focus-up";
        "Mod+Down" = "workspace-next";
        "Mod+J" = rowAction "focus-down";
        "Mod+Ctrl+Left" = "column-move-left";
        "Mod+Ctrl+H" = "column-move-left";
        "Mod+Ctrl+Right" = "column-move-right";
        "Mod+Ctrl+L" = "column-move-right";
        "Mod+Ctrl+Up" = rowAction "move-up";
        "Mod+Ctrl+K" = rowAction "move-up";
        "Mod+Ctrl+Down" = rowAction "move-down";
        "Mod+Ctrl+J" = rowAction "move-down";
        "Mod+Home" = "column-focus-first";
        "Mod+End" = "column-focus-last";
        "Mod+Ctrl+Home" = "column-move-to-first";
        "Mod+Ctrl+End" = "column-move-to-last";
        "Mod+Shift+Left" = "output-focus-left";
        "Mod+Shift+Right" = "output-focus-right";
        "Mod+Shift+Up" = "output-focus-up";
        "Mod+Shift+Down" = "output-focus-down";
        "Mod+Ctrl+Shift+Left" = "column-move-to-output-left";
        "Mod+Ctrl+Shift+Right" = "column-move-to-output-right";
        "Mod+Ctrl+Shift+Up" = "column-move-to-output-up";
        "Mod+Ctrl+Shift+Down" = "column-move-to-output-down";

        "Mod+WheelDown" = {
          action = rowAction "focus-down";
          cooldown_ms = 150;
        };
        "Mod+WheelUp" = {
          action = rowAction "focus-up";
          cooldown_ms = 150;
        };
        "Mod+Ctrl+WheelDown" = {
          action = "column-move-to-workspace-next";
          cooldown_ms = 150;
        };
        "Mod+Ctrl+WheelUp" = {
          action = "column-move-to-workspace-previous";
          cooldown_ms = 150;
        };
        "Mod+WheelRight" = "window-focus-right";
        "Mod+WheelLeft" = "window-focus-left";
        "Mod+Ctrl+WheelRight" = "column-move-right";
        "Mod+Ctrl+WheelLeft" = "column-move-left";
        "Mod+Shift+WheelDown" = "window-focus-right";
        "Mod+Shift+WheelUp" = "window-focus-left";
        "Mod+Ctrl+Shift+WheelDown" = "column-move-right";
        "Mod+Ctrl+Shift+WheelUp" = "column-move-left";
        "Mod+Tab" = "workspace-focus-last";

        # Column sizing and placement.
        "Mod+Ctrl+F" = once "window-toggle-maximize";
        "Mod+Ctrl+C" = "column-center";
        "Mod+C" = "column-center";
        "Mod+Minus" = "window-modify-primary-extent -0.05";
        "Mod+Equal" = "window-modify-primary-extent +0.05";
        "Mod+Shift+Minus" = "window-modify-secondary-extent -0.05";
        "Mod+Shift+Equal" = "window-modify-secondary-extent +0.05";
        "Mod+Shift+F" = once "window-toggle-maximize";
        "Mod+F" = once "window-toggle-fullscreen";
        "Mod+W" = once "column-toggle-tabbed";
        "Mod+R" = "window-cycle-primary-extent";
        "Mod+Shift+R" = "window-cycle-primary-extent-back";
        "Mod+Alt+R" = "window-cycle-secondary-extent";
        "Mod+M" = once "window-toggle-maximize-to-edges";
        "Mod+Comma" = "window-consume-or-expel-left";
        "Mod+Period" = "window-consume-or-expel-right";
        "Mod+Ctrl+Comma" = "window-consume-from-left";
        "Mod+Ctrl+Period" = "window-consume-from-right";
        "Mod+Shift+Space" = once "window-move-to-scratchpad stash";
        "Mod+Ctrl+Space" = once "scratchpad-toggle stash";
        "Mod+Alt+Space" = once "window-restore-from-scratchpad stash";
        "Mod+Alt+Tab" = once "scratchpad-focus-next stash";
        "Mod+Alt+1" = once "workspace-set-layout master";
        "Mod+Alt+2" = once "workspace-set-layout stacking";
        "Mod+D" = once "workspace-set-layout toggle master stacking";
        "Mod+Escape" = (once "shortcuts-inhibit-toggle") // {
          allow_when_inhibited = true;
        };
        "Ctrl+Alt+Delete" = once "session-quit";
        "Mod+Shift+P" = once "dpms-off";
        "Mod+O" = once "overview-toggle";
      }
      // lib.listToAttrs (
        lib.concatMap (n: [
          {
            name = "Mod+${toString n}";
            value = "workspace-switch ${toString n}";
          }
          {
            name = "Mod+Ctrl+${toString n}";
            value = "column-move-to-workspace ${toString n}";
          }
        ]) (lib.range 1 9)
      )
      // lib.optionalAttrs isLaptop {
        "Mod+Shift+M" = once "spawn mirror-laptop";
        "Mod+Ctrl+Alt+T" = once "spawn otd-gui";
      };
      window_rule = [
        {
          match.app_id = "^scratchpad-terminal$";
          default_scratchpad = "terminal";
          default_focused = true;
          default_floating_size_px = {
            width = 1000;
            height = 620;
          };
        }
        {
          match.app_id = "^(org\\.gnome\\.Calculator|gnome-calculator)$";
          default_scratchpad = "calculator";
          default_focused = true;
        }
        {
          match.app_id = "^(kitty|scratchpad-terminal)$";
          blur = true;
          blur_optimized = false;
        }
        {
          match.app_id = "^(thunar|Thunar|org\\.xfce\\.Thunar)$";
          blur = true;
        }
        {
          match.app_id = "^zen";
          blur = true;
          shadow = false;
        }
        # Retain Umbriel's shell and share-picker placement rules.
        {
          match.app_id = "^dev.noctalia.Noctalia$";
          blur = true;
          default_floating = true;
          default_floating_size_px = {
            width = 1020;
            height = 900;
          };
        }
        {
          match.app_id = "^dev.noctalia.UmbrielSharePicker$";
          default_floating = true;
          default_floating_size_px = {
            width = 800;
            height = 600;
          };
        }
        {
          match.title = "^(Picture-in-Picture|Picture in picture)$";
          default_floating = true;
          default_maximize = false;
          default_position = {
            x = 20;
            y = 20;
            anchor = "bottom_right";
          };
        }
        {
          match.title = "^notificationtoasts_.+_desktop";
          default_position = {
            x = 0;
            y = 0;
            anchor = "bottom_right";
          };
          default_focused = false;
          default_pinned = true;
        }
      ];
      layer_rule = [
        {
          match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|window-switcher|desktop-widget-[^\"]*)$";
          blur = true;
          blur_ignore_alpha = 0.1;
          blur_popups = true;
          # Preserve live window content behind the shell, not wallpaper-only blur.
          blur_optimized = false;
        }
      ];
    }
    // lib.optionalAttrs isLaptop {
      output = {
        # Match the display identity, not the racing eDP connector number.
        "BOE NE140QDM-NX7 Unknown" = {
          mode = "2560x1600@165";
          scale = display.laptopScale;
          position = [
            0
            0
          ];
        };
        "HDMI-A-1" = {
          # Let each monitor/projector choose its preferred resolution and refresh.
          enabled = true;
          scale = 1.0;
          position = [
            (builtins.ceil (2560 / display.laptopScale))
            0
          ];
        };
      };
    };
  };
}
