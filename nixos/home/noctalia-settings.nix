# Shell preferences. Palettes, theme mode and the current wallpaper remain runtime state.
{
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
      background_opacity = 0.46;
      border = "outline_variant";
      border_width = 1.0;
      capsule = false;
      center = [
        "clock"
      ];
      concave_edge_corners = false;
      end = [
        "group:activity"
        "group:tools"
        "tray"
        "privacy"
        "notifications"
        "group:status"
        "session"
      ];
      margin_edge = 10;
      margin_ends = 16;
      padding = 8;
      widget_spacing = 4;
      position = "bottom";
      radius = 20;
      shadow = true;
      thickness = 32;
      reserve_space = true;
      auto_hide = false;
      smart_auto_hide = false;
      start = [
        "launcher"
        "workspaces"
        "nix-monitor"
      ];
      capsule_group = [
        {
          id = "activity";
          enabled = true;
          members = [ "media" ];
          fill = "surface_container";
          foreground = "on_surface";
          opacity = 0.24;
          padding = 8.0;
          radius = 20.0;
          border = "outline_variant";
          border_width = 1.0;
        }
        {
          id = "tools";
          accordion = true;
          accordion_direction = "start";
          enabled = true;
          fill = "surface_container";
          foreground = "on_surface";
          members = [
            "screen-toolkit"
            "clipboard"
            "phone-connect"
            "tailscale"
            "pomodoro"
          ];
          opacity = 0.20;
          padding = 6.0;
          radius = 12.0;
        }
        {
          accordion = false;
          enabled = true;
          fill = "surface_container";
          foreground = "on_surface";
          id = "status";
          members = [
            "network"
            "bluetooth"
            "volume"
            "keyboard_layout"
            "power_profile"
            "battery"
            "control-center"
          ];
          opacity = 0.20;
          padding = 6.0;
          radius = 12.0;
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
    background_opacity = 0.52;
    border = "outline_variant";
    border_width = 1.0;
    icon_size = 32;
    margin_edge = 10;
    radius = 22;
    concave_edge_corners = false;
    magnification = true;
    magnification_scale = 1.35;
    show_dots = true;
    active_monitor_only = true;
    position = "right";
    reserve_space = false;
    smart_auto_hide = true;
  };
  notification = {
    follow_focused_output = true;
    max_visible = 3;
    background_opacity = 0.82;
    offset_x = 12;
    offset_y = 8;
  };
  osd = {
    position = "top_center";
    hide_delay_ms = 1000;
    background_opacity = 0.78;
  };
  lockscreen = {
    transition = [ "fade" "zoom" ];
    transition_duration = 650.0;
  };
  lockscreen_widgets = {
    enabled = false;
  };
  plugin_settings = {
    "davemhammer/tailscale" = {
      refresh_interval = 30;
      notify_on_peer_change = false;
    };
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
      "davemhammer/tailscale"
    ];
    # Catalogs can be refreshed in Settings; Nix-managed plugins follow the flake pin.
    auto_update = "none";
  };
  shell = {
    corner_radius_scale = 1.2;
    font_family = "Inter";
    polkit_agent = true;
    greeter_sync.auto_sync = true;
    setup_wizard_enabled = false;
    settings_window_translucent = true;
    umbriel_overview_type_to_launch_enabled = true;
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
      enabled = true;
      speed = 1.0;
    };
    shadow = {
      alpha = 0.35;
    };
    panel = {
      launcher_placement = "floating";
      launcher_position = "center";
      clipboard_placement = "floating";
      clipboard_position = "center";
      open_near_click_launcher = false;
      open_near_click_wallpaper = true;
      transparency_mode = "glass";
      borders = true;
      border_width = 1.0;
      shadow = true;
      control_center_placement = "floating";
      control_center_position = "bottom_right";
      floating_offset = 12;
    };
    launcher = {
      layout = "simple";
      category_icons_only = true;
      search_position = "top";
    };
    clipboard_history_max_entries = 100;
    clipboard_keep_from_closed_apps = true;
    clipboard_confirm_clear_history = true;
  };
  theme = {
    source = "wallpaper";
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
    transition = [ "fade" "disc" "melt" ];
    transition_duration = 1100.0;
    directory = "~/Pictures/Wallpapers";
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
      max_length = 140;
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
    volume = {
      show_label = false;
    };
    privacy = {
      hide_inactive = true;
    };
    keyboard_layout = {
      hide_when_single_layout = true;
      show_glyph = false;
    };
    battery = {
      display_mode = "graphic";
    };
    tailscale = {
      type = "davemhammer/tailscale:status";
      show_counts = false;
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
