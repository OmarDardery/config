# Shell preferences. Palettes, theme mode and the current wallpaper remain runtime state.
{
  backdrop = {
    blur_intensity = 0.56;
    tint_intensity = 0.35;
  };
  idle = {
    behavior_order = [
      "lock"
      "screen-off"
    ];
    behavior = {
      lock = {
        enabled = true;
        timeout = 600;
        action = "lock";
      };
      screen-off = {
        enabled = true;
        timeout = 660;
        action = "screen_off";
      };
    };
  };
  bar = {
    default = {
      background_opacity = 0.6;
      border = "on_primary";
      capsule = true;
      capsule_border = "on_primary";
      capsule_foreground = "primary";
      capsule_opacity = 0.39;
      capsule_thickness = 0.61;
      center = [
        "clock"
      ];
      concave_edge_corners = false;
      end = [
        "screen-toolkit"
        "phone-connect"
        "pomodoro"
        "media"
        "tray"
        "notifications"
        "clipboard"
        "group:g1"
        "session"
      ];
      margin_edge = 5;
      margin_ends = 12;
      padding = 6;
      position = "bottom";
      radius = 13;
      shadow = false;
      thickness = 29;
      reserve_space = true;
      smart_auto_hide = true;
      start = [
        "launcher"
        "workspaces"
        "nix-monitor"
      ];
      capsule_group = [
        {
          accordion = false;
          accordion_direction = "end";
          border = "on_primary";
          enabled = true;
          fill = "surface_variant";
          foreground = "primary";
          id = "g1";
          members = [
            "network"
            "bluetooth"
            "power_profile"
            "battery"
            "control-center"
          ];
          opacity = 0.39;
          padding = 6.0;
        }
      ];
    };
  };
  control_center = {
    show_shortcut_labels = true;
    shortcuts = [
      {
        type = "wifi";
      }
      {
        type = "bluetooth";
      }
      {
        type = "nightlight";
      }
      {
        type = "notification";
      }
      {
        type = "alexander/screen-toolkit:toggle";
      }
      {
        type = "caffeine";
      }
    ];
  };
  desktop_widgets = {
    enabled = false;
  };
  dock = {
    enabled = true;
    icon_size = 31;
    launcher_icon = "gpu-usage";
    position = "right";
    reserve_space = false;
    smart_auto_hide = true;
  };
  lockscreen_widgets = {
    enabled = false;
  };
  plugin_settings = {
    "avivbintangaringga/nix-monitor" = {
      branch = "nixos-26.05";
      system_stats_check_mode = "off";
    };
  };
  plugins = {
    enabled = [
      "alexander/screen-toolkit"
      "avivbintangaringga/nix-monitor"
      "icefish/phone-connect"
      "thepunkoff/pomodoro"
      "alexander/game-launcher"
    ];
    source = [ ];
    auto_update = "none";
  };
  shell = {
    polkit_agent = true;
    session = {
      actions = [
        {
          action = "lock";
          shortcut = "1";
        }
        {
          action = "logout";
          shortcut = "2";
        }
        {
          action = "lock_and_suspend";
          shortcut = "3";
        }
        {
          action = "reboot";
          shortcut = "4";
        }
        {
          action = "shutdown";
          variant = "destructive";
          shortcut = "5";
        }
        {
          action = "suspend";
          shortcut = "6";
          command = "noctalia msg session lock-and-suspend";
        }
      ];
    };
    animation = {
      speed = 2.0;
    };
    panel = {
      launcher_placement = "attached";
      open_near_click_launcher = true;
      open_near_click_wallpaper = true;
      transparency_mode = "glass";
    };
    clipboard_history_max_entries = 100;
    clipboard_keep_from_closed_apps = true;
    clipboard_confirm_clear_history = true;
  };
  theme = {
    source = "wallpaper";
    wallpaper_scheme = "m3-rainbow";
    templates = {
      builtin_ids = [
        "gtk3"
        "gtk4"
        "kcolorscheme"
        "starship"
      ];
      community_ids = [ ];
    };
  };
  wallpaper = {
    transition_on_startup = true;
    automation = {
      interval_seconds = 300;
    };
    default = {
      path = "~/Pictures/Wallpapers/wp9432445-4k-mountains-desktop-wallpapers.jpg";
    };
  };
  widget = {
    control-center = {
      glyph = "settings";
    };
    nix-monitor = {
      show_text = false;
      type = "avivbintangaringga/nix-monitor:nix-monitor";
    };
    screen-toolkit = {
      type = "alexander/screen-toolkit:widget";
    };
    phone-connect = {
      type = "icefish/phone-connect:bar";
    };
    pomodoro = {
      type = "thepunkoff/pomodoro:widget";
    };
  };
}
