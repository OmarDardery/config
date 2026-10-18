{
  inputs,
  pkgs,
  config,
  lib,
  isLaptop,
  profile,
  osConfig,
  ...
}:
let
  once = action: {
    inherit action;
    repeat = false;
  };
  locked = command: {
    action = "spawn:noctalia msg ${command}";
    allow_when_locked = true;
  };
  capture = event: {
    action = "spawn:noctalia msg plugin alexander/screen-toolkit:service all ${event}";
    submap = "reset";
    repeat = false;
  };
  rowNavigation = pkgs.writeShellApplication {
    name = "umbriel-row-action";
    runtimeInputs = [
      config.programs.umbriel.package
      pkgs.jq
    ];
    text = ''
      case "''${1:-}" in
        focus-up) tab_action=column-focus-tab-previous ;;
        focus-down) tab_action=column-focus-tab-next ;;
        move-up) tab_action=column-move-tab-previous ;;
        move-down) tab_action=column-move-tab-next ;;
        *) printf '%s\n' 'Expected focus-up, focus-down, move-up or move-down' >&2; exit 2 ;;
      esac
      tabbed=$(umbriel windows --json | jq -er '
        [.[] | select(.active)]
        | if length == 1 then .[0].tabbed | tostring else error("Expected one active window") end
      ')
      if [[ "$tabbed" == true ]]; then
        exec umbriel msg "$tab_action"
      else
        exec umbriel msg "window-$1"
      fi
    '';
  };
  rowAction = action: "spawn:${rowNavigation}/bin/umbriel-row-action ${action}";
  screenshotWindow = pkgs.writeShellApplication {
    name = "screenshot-window-umbriel";
    runtimeInputs = [
      config.programs.umbriel.package
      pkgs.jq
      pkgs.grim
      pkgs.wl-clipboard
    ];
    text = ''
      identifier=$(umbriel windows --json | jq -er '
        [.[] | select(.active)]
        | if length == 1 then .[0].id else error("Expected one active window") end
        | if type == "string" and length > 0 then . else error("Missing window identifier") end
      ')
      image=$(mktemp --suffix=.png)
      trap 'rm -f "$image"' EXIT
      # Capture the isolated client surface, not a crop containing other windows.
      grim -T "$identifier" "$image"
      wl-copy --type image/png < "$image"
    '';
  };
in
{
  imports = [ inputs.umbriel.homeModules.default ];
  programs.umbriel = {
    enable = true;
    package = osConfig.programs.umbriel.package;
    settings = {
      # No independent palette: Noctalia owns colors; native defaults before rendering.
      include.optional.files = [ "${config.xdg.stateHome}/noctalia/theme/umbriel.toml" ];
      general = {
        autostart = [
          "${config.programs.noctalia.package}/bin/noctalia"
        ];
        mod_key = "Super";
        show_cheatsheet = false;
        focus_on_activate = true;
        # Keep X11 games sharp at the panel resolution despite desktop scaling.
        # Changing this requires restarting the compositor session.
        xwayland_native_resolution = true;
      };
      input = {
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
          follows_mouse = true;
          # Hovering a partially visible column should not move the whole strip.
          follows_mouse_max_scroll = 0.0;
        };
        cursor = {
          theme = config.home.pointerCursor.name;
          size = config.home.pointerCursor.size;
          hide_when_typing = true;
        };
      };
      workspaces = {
        back_and_forth = true;
        empty_above = true;
      };
      layout = {
        mode = "dwindle";
        gap = 8;
        extent_presets = [
          0.33333
          0.5
          0.66667
        ];
        scrolling = {
          default_extent_fraction = 0.5;
          center_focused = "on_overflow";
          center_underfull_strip = true;
        };
        # Keep manual split choices stable when windows and outputs resize.
        dwindle.preserve_split = true;
        tabs = {
          default_display = "tabbed";
          wrap_focus = false;
        };
      };
      appearance = {
        prefer_no_csd = true;
        border_width = 1;
        outer_border_width = 1;
        corner_radius = 12;
        blur = {
          passes = 2;
          radius = 4;
        };
        shadow = {
          enabled = true;
          softness = 24;
          offset_x = 0;
          offset_y = 4;
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
        # One critically damped spring for reflow, workspaces and overview.
        curve = "spring:1,900";
        windows_in.scale = 0.96;
        windows_out = {
          curve = "spring:1,1400";
          scale = 0.96;
        };
        overview.workspace_curve = "spring:1,900";
        scratchpad.dim = 0.45;
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
        "Mod+T" = once "spawn:${pkgs.kitty}/bin/kitty";
        "Mod+Space" = once "spawn:noctalia msg panel-toggle launcher";
        "Alt+Tab" = once "spawn:noctalia msg window-switcher hold";
        "Mod+B" = once "spawn:zen";
        "Mod+Alt+L" = once "spawn:noctalia msg session lock";
        "Mod+Shift+Q" = once "spawn:noctalia msg panel-toggle session";
        "XF86PowerOff" = (locked "session lock") // {
          repeat = false;
          allow_when_inhibited = true;
        };
        "Mod+Shift+F23" = once "spawn:${pkgs.kitty}/bin/kitty";
        "Mod+E" = once "spawn:thunar";
        "Mod+I" = once "spawn:codium";
        "Mod+Ctrl+E" = once "spawn:${pkgs.kitty}/bin/kitty nvim ${lib.escapeShellArg profile.configRepo}";
        "Mod+Shift+D" = once "spawn:nwg-displays";
        "Mod+A" = once "spawn:noctalia msg panel-toggle control-center";
        "Mod+S" = once "spawn:noctalia msg plugin alexander/screen-toolkit:service all toggle";
        "Mod+Ctrl+S" = once "spawn:noctalia msg settings-toggle";
        "Mod+V" = once "spawn:noctalia msg panel-toggle clipboard";
        "Mod+N" = once "spawn:noctalia msg panel-toggle notifications";
        "Mod+Shift+N" = once "spawn:noctalia msg notification-dnd-toggle";
        "Mod+Ctrl+N" = once "spawn:noctalia msg notification-clear-active";
        "Mod+Alt+W" = once "spawn:noctalia msg panel-toggle wallpaper";
        "Mod+Alt+Right" = "column-focus-tab-next";
        "Mod+Alt+Left" = "column-focus-tab-previous";
        "Mod+Alt+C" = once "spawn:noctalia msg caffeine-toggle";
        "Mod+Alt+N" = once "spawn:noctalia msg nightlight-force-toggle";
        "Mod+Alt+D" = once "spawn:noctalia msg theme-mode-toggle";
        "Mod+Alt+P" = once "spawn:noctalia msg power-cycle";
        "Mod+Alt+A" = once "spawn:noctalia msg panel-toggle control-center audio";
        "Mod+Alt+B" = once "spawn:noctalia msg panel-toggle control-center bluetooth";
        "Mod+Alt+E" = once "spawn:noctalia msg panel-toggle launcher /emo";
        "Mod+Ctrl+Shift+R" = once "config-reload";
        "Print" = once "spawn:noctalia msg screenshot-region";
        "Shift+Print" = once "spawn:noctalia msg screenshot-fullscreen";
        "Ctrl+Print" = once "spawn:${screenshotWindow}/bin/screenshot-window-umbriel";
        "Mod+P" = once "window-toggle-pinned";
        "Alt+Print" = once "spawn:noctalia msg screenshot-annotate";
        "Mod+Alt+G" = once "spawn:noctalia msg panel-toggle alexander/game-launcher:browser";
        "Mod+Alt+V" = once "spawn:noctalia msg panel-toggle davemhammer/tailscale:manager";
        "Mod+Alt+M" = once "spawn:noctalia msg panel-toggle icefish/phone-connect:details";
        "Mod+Alt+O" = once "spawn:noctalia msg panel-toggle thepunkoff/pomodoro:panel";
        "Mod+Shift+S" = once "submap:capture";
        "submap[capture],Escape" = "submap:reset";
        "submap[capture],F1" = once "cheatsheet-open";
        "submap[capture],C" = capture "colorPicker";
        "submap[capture],O" = capture "ocr";
        "submap[capture],Q" = capture "qr";
        "submap[capture],P" = capture "palette";
        "submap[capture],L" = capture "lens";
        "submap[capture],M" = capture "measure";
        "submap[capture],A" = capture "annotate";
        "submap[capture],R" = capture "recordMp4";
        "submap[capture],F" = capture "recordFullscreenMp4";
        "submap[capture],G" = capture "record";
        "submap[capture],S" = capture "recordStop";
        "submap[capture],V" = capture "recordSave";

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

        # Maximize and center the focused column.
        "Mod+Ctrl+F" = once "window-toggle-maximize";
        "Mod+Ctrl+C" = "column-center";
        "Mod+C" = "column-center";
        "Mod+Minus" = "window-modify-primary-extent:-0.1";
        "Mod+Equal" = "window-modify-primary-extent:+0.1";
        "Mod+Shift+Minus" = "window-modify-secondary-extent:-0.1";
        "Mod+Shift+Equal" = "window-modify-secondary-extent:+0.1";
        "Mod+Return" = once "window-toggle-floating";
        "Mod+Shift+F" = once "window-toggle-fullscreen";
        "Mod+F" = once "window-toggle-maximize";
        "Mod+W" = once "column-toggle-tabbed";
        "Mod+R" = "window-cycle-primary-extent";
        "Mod+Shift+R" = "window-cycle-primary-extent-back";
        "Mod+Alt+R" = "window-cycle-secondary-extent";
        "Mod+Alt+T" = once "layout-toggle-split";
        "Mod+Shift+T" = once "window-focus-switch-floating";
        "Mod+M" = once "window-toggle-maximize-to-edges";
        "Mod+Comma" = "window-consume-or-expel-left";
        "Mod+Period" = "window-consume-or-expel-right";
        "Mod+Ctrl+Comma" = "window-consume-from-left";
        "Mod+Ctrl+Period" = "window-consume-from-right";
        "Mod+Shift+Space" = once "window-move-to-scratchpad";
        "Mod+Ctrl+Space" = once "scratchpad-toggle";
        "Mod+Alt+Space" = once "window-restore-from-scratchpad";
        "Mod+Alt+Tab" = once "scratchpad-focus-next";
        "Mod+Alt+1" = once "workspace-set-layout:dwindle";
        "Mod+Alt+2" = once "workspace-set-layout:scrolling";
        "Mod+D" = once "workspace-set-layout:toggle:dwindle,scrolling";
        "F6" = once "spawn:noctalia msg screenshot-region";
        "Ctrl+Shift+2" = once "spawn:noctalia msg screenshot-fullscreen";
        "Ctrl+Shift+3" = once "spawn:${screenshotWindow}/bin/screenshot-window-umbriel";
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
            value = "workspace-switch:${toString n}";
          }
          {
            name = "Mod+Ctrl+${toString n}";
            value = "column-move-to-workspace:${toString n}";
          }
        ]) (lib.range 1 9)
      )
      // lib.optionalAttrs isLaptop {
        "Mod+Shift+M" = once "spawn:mirror-laptop";
      };
      window_rule = [
        {
          match.app_id = "^kitty$";
          blur = true;
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
          blur_ignore_alpha = 0.5;
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
          scale = 1.5;
          position = [
            0
            0
          ];
        };
        "HDMI-A-1" = {
          mode = "1920x1080@60";
          scale = 1.0;
          position = [
            1706
            0
          ];
        };
      };
    };
  };
}
