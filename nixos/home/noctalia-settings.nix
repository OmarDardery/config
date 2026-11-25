# Shell preferences. Palettes, theme mode and the current wallpaper remain runtime state.
{
  idle = {
    behavior_order = [
      "lock"
      "screen-off"
      "suspend"
    ];
    pre_action_fade_seconds = 1.0;
    behavior = {
      lock = {
        enabled = true;
        timeout = 600;
        action = "lock";
      };
      suspend = {
        enabled = false;
        timeout = 1200;
        action = "lock_and_suspend";
      };
      screen-off = {
        enabled = true;
        timeout = 900;
        action = "screen_off";
      };
    };
  };
  battery.warning_threshold = 15;
  audio = {
    enable_volume_sounds = false;
    enable_screenshot_sounds = false;
    sound_volume = 0.25;
  };
  # macOS-style menu bar: edge-to-edge, translucent, at the top.
  bar.default = {
    position = "top";
    reserve_space = true;
    auto_hide = false;
    smart_auto_hide = false;

    thickness = 28;
    margin_edge = 0;
    margin_ends = 0;
    padding = 10;
    widget_spacing = 4;
    radius = 0;
    concave_edge_corners = false;
    background_opacity = 0.55;
    compositor_blur = true;
    border_width = 0.0;
    shadow = false;
    hover_highlight = true;
    capsule = false;

    # Menu (Spotlight) and focused app | status icons and clock.
    start = [
      "launcher"
      "active_window"
    ];
    center = [ ];
    end = [
      "media"
      "tray"
      "privacy"
      "keyboard_layout"
      "battery"
      "bluetooth"
      "network"
      "volume"
      "notifications"
      "control-center"
      "clock"
    ];
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
        type = "caffeine";
      }
    ];
  };
  desktop_widgets = {
    enabled = false;
  };
  # Floating, magnifying dock with running-app dots and a Launchpad button.
  dock = {
    enabled = true;
    position = "bottom";
    icon_size = 48;
    magnification = true;
    magnification_scale = 1.6;
    item_spacing = 6;
    main_axis_padding = 10;
    cross_axis_padding = 6;
    margin_edge = 8;
    radius = 20;
    background_opacity = 0.5;
    compositor_blur = true;
    border = "outline_variant";
    border_width = 1.0;
    shadow = true;
    icon_shadow = true;
    show_running = true;
    show_dots = true;
    show_instance_count = false;
    active_scale = 1.0;
    inactive_scale = 1.0;
    active_opacity = 1.0;
    inactive_opacity = 1.0;
    auto_hide = false;
    smart_auto_hide = false;
    reserve_space = true;
    launcher_position = "end";
    launcher_icon = "grid-dots";
    pinned = [
      "dev.noctalia.luciole"
      "zen"
      "kitty"
      "codium"
      "com.discordapp.Discord"
      "libreoffice-writer"
    ];
  };
  notification = {
    follow_focused_output = true;
    max_visible = 2;
    position = "top_right";
    layer = "top";
    history_retention_hours = 72;
    background_opacity = 0.92;
    offset_x = 12;
    offset_y = 12;
    filter.discord = {
      match = "discord";
      play_sound = false;
      override_duration = 5000;
      allow_permanent = false;
    };
  };
  osd = {
    position = "top_right";
    hide_delay_ms = 1000;
    background_opacity = 0.78;
  };
  lockscreen = {
    transition = [ "fade" ];
    transition_duration = 250.0;
  };
  lockscreen_widgets = {
    enabled = false;
  };
  # Declarative plugin sources; Noctalia owns fetching, updates and runtime cache.
  plugins = {
    enabled = [ ];
    auto_update = "all";
    source = [
      {
        name = "official";
        kind = "git";
        location = "https://github.com/noctalia-dev/official-plugins";
        enabled = true;
      }
      {
        name = "community";
        kind = "git";
        location = "https://github.com/noctalia-dev/community-plugins";
        enabled = true;
      }
    ];
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
      speed = 1.15;
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
      control_center_position = "top_right";
      floating_offset = 12;
    };
    # Spotlight: a compact, centered search field.
    launcher = {
      layout = "simple";
      categories = false;
      search_position = "top";
    };
    # Cmd+Tab: a row of app icons in most-recently-used order.
    window_switcher = {
      style = "icons";
      mru = true;
      show_caption = true;
    };
    clipboard_history_max_entries = 100;
    clipboard_keep_from_closed_apps = true;
    clipboard_confirm_clear_history = true;
  };
  wallpaper = {
    transition_on_startup = true;
    transition = [ "fade" ];
    transition_duration = 500.0;
    directory = "~/Pictures/Wallpapers";
  };
  widget = {
    launcher = {
      glyph = "command";
    };
    active_window = {
      display = "text_only";
      max_length = 260;
      title_scroll = "none";
    };
    clock = {
      format = "{:%a %d %b  %H:%M}";
    };
    notifications = {
      hide_when_no_unread = true;
    };
    media = {
      peek = true;
      min_length = 0;
      max_length = 150;
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
    control-center = {
      glyph = "settings";
    };
  };
}
