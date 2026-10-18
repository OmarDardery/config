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
      background_opacity = 0.88;
      border = "outline";
      border_width = 1.0;
      capsule = false;
      center = [
        "clock"
      ];
      concave_edge_corners = false;
      end = [
        "media"
        "group:tools"
        "tray"
        "notifications"
        "group:status"
        "session"
      ];
      margin_edge = 8;
      margin_ends = 12;
      padding = 10;
      position = "bottom";
      radius = 12;
      shadow = true;
      thickness = 34;
      reserve_space = false;
      smart_auto_hide = true;
      start = [
        "launcher"
        "workspaces"
        "nix-monitor"
      ];
      capsule_group = [
        {
          id = "tools";
          accordion = true;
          accordion_direction = "start";
          enabled = true;
          fill = "surface_variant";
          foreground = "on_surface";
          members = [
            "screen-toolkit"
            "clipboard"
            "phone-connect"
            "pomodoro"
          ];
          opacity = 0.55;
          padding = 6.0;
          radius = 8.0;
        }
        {
          accordion = false;
          enabled = true;
          fill = "surface_variant";
          foreground = "on_surface";
          id = "status";
          members = [
            "network"
            "bluetooth"
            "power_profile"
            "battery"
            "control-center"
          ];
          opacity = 0.55;
          padding = 6.0;
          radius = 8.0;
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
    background_opacity = 0.88;
    border = "outline";
    border_width = 1.0;
    icon_size = 32;
    margin_edge = 8;
    radius = 12;
    magnification_scale = 1.2;
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
      speed = 1.5;
    };
    shadow = {
      alpha = 0.3;
    };
    panel = {
      launcher_placement = "floating";
      launcher_position = "center";
      open_near_click_launcher = false;
      open_near_click_wallpaper = true;
      transparency_mode = "glass";
    };
    clipboard_history_max_entries = 100;
    clipboard_keep_from_closed_apps = true;
    clipboard_confirm_clear_history = true;
  };
  theme = {
    source = "wallpaper";
    wallpaper_scheme = "m3-tonal-spot";
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
    clock = {
      format = "{:%a %d %b  %H:%M}";
    };
    workspaces = {
      style = "minimal";
      show_labels = true;
      show_icons = false;
    };
    media = {
      max_length = 180;
      hide_artist = true;
      hide_when_no_media = true;
      title_scroll = "on_hover";
    };
    network = {
      show_label = false;
    };
    bluetooth = {
      show_label = false;
      hide_when_no_connected_device = true;
    };
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
