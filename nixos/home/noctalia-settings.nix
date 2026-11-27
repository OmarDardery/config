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

    # macOS order: menu and focused app | Now Playing (only while media
    # plays) | transient indicators, then persistent status, Control Center
    # and the clock at the far right.
    start = [
      "launcher"
      "active_window"
    ];
    center = [ "media" ];
    end = [
      "privacy"
      "tray"
      "keyboard_layout"
      "volume"
      "bluetooth"
      "network"
      "battery"
      "notifications"
      "control-center"
      "clock"
    ];
  };
  # Tiles in macOS Control Center order; sliders and tabs are built in.
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
        type = "notification";
      }
      {
        type = "dark_mode";
      }
      {
        type = "nightlight";
      }
      {
        type = "caffeine";
      }
      {
        type = "power_profile";
      }
      {
        type = "keyboard_layout";
      }
    ];
  };
  # Weather and night light use this location.
  location = {
    auto_locate = false;
    address = "Cairo, Egypt";
  };
  weather = {
    enabled = true;
    unit = "metric";
  };
  # macOS Sonoma-style widget column on the laptop panel (logical 1600x1000),
  # visible on an empty workspace.
  desktop_widgets =
    let
      card = {
        background = true;
        background_color = "surface";
        background_opacity = 0.45;
        background_radius = 22.0;
        background_padding = 14.0;
        shadow = true;
      };
      widget = type: cx: cy: settings: {
        inherit type cx cy;
        output = "NE140QDM-NX7";
        box_width = 0.0;
        box_height = 0.0;
        rotation = 0.0;
        inherit settings;
      };
    in
    {
      enabled = true;
      schema_version = 2;
      widget_order = [
        "desktop-clock"
        "desktop-weather"
        "desktop-calendar"
      ];
      widget = {
        desktop-clock = widget "clock" 150.0 160.0 (
          card
          // {
            clock_style = "analog";
            circle = true;
            show_seconds = false;
          }
        );
        desktop-weather = widget "weather" 150.0 340.0 (
          card
          // {
            show_forecast = true;
            forecast_days = 3;
          }
        );
        # The calendar draws no text shadow.
        desktop-calendar = widget "calendar" 190.0 580.0 (
          builtins.removeAttrs card [ "shadow" ]
          // {
            show_events = false;
            show_week_numbers = false;
          }
        );
      };
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
    # Room for magnified icons.
    cross_axis_padding = 8;
    margin_edge = 8;
    radius = 20;
    background_opacity = 0.5;
    compositor_blur = true;
    border = "outline_variant";
    border_width = 1.0;
    shadow = true;
    icon_shadow = false;
    show_running = true;
    show_dots = true;
    show_instance_count = false;
    active_scale = 1.0;
    inactive_scale = 1.0;
    active_opacity = 1.0;
    inactive_opacity = 1.0;
    # Visible on an empty desktop, hidden while windows are open; reveal at
    # the bottom edge. Windows keep the full height on the 14" panel.
    auto_hide = false;
    smart_auto_hide = true;
    auto_hide_reveal_delay_ms = 150;
    reserve_space = false;
    # Launchpad first, as on macOS.
    launcher_position = "start";
    launcher_icon = "grid-dots";
    # Grouped by task: files | web, chat | development | office | games.
    pinned = [
      "dev.noctalia.luciole"
      "zen"
      "com.discordapp.Discord"
      "dev.zed.Zed"
      "kitty"
      "libreoffice-writer"
      "steam"
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
  # macOS-style lock screen: frosted wallpaper, large clock at the top and a
  # slim password field low on the laptop panel. Other monitors keep the
  # default login box.
  lockscreen = {
    transition = [ "fade" ];
    transition_duration = 250.0;
    dnd = true;
    blur_intensity = 0.75;
    tint_intensity = 0.15;
  };
  lockscreen_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "lockscreen-clock"
      "lockscreen-login-box@laptop"
    ];
    # Logical coordinates on the 2560x1600 panel at 1.6x scale (1600x1000).
    widget.lockscreen-clock = {
      type = "clock";
      output = "NE140QDM-NX7";
      cx = 800.0;
      cy = 170.0;
      box_width = 520.0;
      box_height = 160.0;
      rotation = 0.0;
      settings = {
        clock_style = "digital";
        format = "{:%H:%M}";
        color = "on_surface";
        shadow = true;
        center_text = true;
        show_seconds = false;
      };
    };
    widget."lockscreen-login-box@laptop" = {
      type = "login_box";
      output = "NE140QDM-NX7";
      cx = 800.0;
      cy = 800.0;
      settings = {
        layout = "compact";
        show_session_buttons = false;
        show_media = false;
        show_weather = false;
        background_opacity = 0.55;
        background_radius = 20.0;
      };
    };
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
    # One launcher for Spotlight (Super+Space, type to search) and Launchpad
    # (dock grid button): an app grid with search on top.
    launcher = {
      layout = "full";
      app_grid = true;
      default_view = "all";
      search_position = "top";
      width = 1000;
      show_navigation_labels = false;
      show_settings_button = false;
      show_session_button = false;
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
    # Clicking the clock opens Notification Center, as on macOS.
    clock = {
      format = "{:%a %d %b  %H:%M}";
      actions.left = "panel-toggle notifications";
    };
    notifications = {
      hide_when_no_unread = true;
    };
    media = {
      peek = true;
      min_length = 0;
      max_length = 260;
      hide_artist = true;
      hide_when_no_media = true;
      title_scroll = "on_hover";
    };
    # Status icons open Control Center on click.
    network = {
      show_label = false;
      actions.left = "panel-toggle control-center";
    };
    bluetooth = {
      show_label = false;
      hide_when_no_connected_device = true;
      actions.left = "panel-toggle control-center";
    };
    volume = {
      show_label = false;
      actions.left = "panel-toggle control-center";
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
