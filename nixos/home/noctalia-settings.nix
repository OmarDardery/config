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
  # Always-visible desktop taskbar with Smart Taskbar replacing the dock.
  bar.default = {
    position = "bottom";
    reserve_space = true;
    auto_hide = false;
    smart_auto_hide = false;

    thickness = 36;
    margin_edge = 8;
    margin_ends = 12;
    padding = 8;
    widget_spacing = 6;
    radius = 18;
    background_opacity = 0.78;
    compositor_blur = true;
    border = "outline_variant";
    border_width = 1.0;
    shadow = true;
    hover_highlight = true;
    capsule = false;

    # Navigation / context | clock | activity / status.
    start = [
      "launcher"
      "group:workspaces"
      "smart_taskbar"
    ];
    center = [ "clock" ];
    end = [
      "group:media"
      "tray"
      "privacy"
      "notifications"
      "group:status"
    ];
    capsule_group = [
      {
        id = "workspaces";
        members = [ "workspaces" ];
        fill = "surface_container";
        opacity = 0.26;
        padding = 6.0;
        radius = 12.0;
      }
      {
        id = "media";
        members = [ "media" ];
        fill = "surface_container";
        opacity = 0.20;
        padding = 6.0;
        radius = 12.0;
      }
      {
        id = "status";
        members = [
          "network"
          "bluetooth"
          "volume"
          "keyboard_layout"
          "battery"
          "control-center"
        ];
        fill = "surface_container";
        opacity = 0.26;
        padding = 6.0;
        radius = 12.0;
      }
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
  dock.enabled = false;
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
    position = "top_center";
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
    enabled = [ "omardardery/smart-taskbar" ];
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
      {
        name = "smart-taskbar";
        kind = "git";
        location = "https://github.com/OmarDardery/smart-taskbar-noctalia";
        enabled = true;
      }
    ];
  };
  shell = {
    corner_radius_scale = 1.2;
    font_family = "Inter";
    polkit_agent = true;
    greeter_sync.auto_sync = false;
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
  wallpaper = {
    transition_on_startup = true;
    transition = [ "fade" ];
    transition_duration = 500.0;
    directory = "~/Pictures/Wallpapers";
  };
  widget = {
    # Plugin settings use the manifest's exact field names. No outer capsule
    # avoids doubling background/padding and preserves the 420px width budget.
    smart_taskbar = {
      type = "omardardery/smart-taskbar:taskbar";
      capsule = false;
      capsule_padding = 0;
      scale = 1.0;
      expand_mode = "hover";
      hover_delay = 150;
      collapse_delay = 350;
      animations = true;
      animation_duration = 120;
      display_mode = "running";
      grouping = "app";
      workspace_filter = "all";
      output_filter = "current";
      show_minimized = true;
      sorting = "launch";
      min_width = 64;
      max_width = 420;
      collapsed_width = 64;
      icon_size = 22;
      icon_spacing = 4;
      overflow_behavior = "items";
      scroll_step = 1;
      show_scroll_indicators = true;
      auto_reveal_focused = true;
      collapsed_label = "none";
      duplicate_indicator = "badge";
      badge_placement = "after";
      hover_enlarge = true;
      hover_scale = 1.15;
      capsule_radius = 14;
      opacity = 0.85;
      border = false;
      active_indicator = true;
      minimized_indicator = true;
      urgent_indicator = true;
      click_behavior = "cycle";
      compositor_compatibility = "auto";
    };
    clock = {
      format = "{:%a %d %b  %H:%M}";
    };
    workspaces = {
      style = "minimal";
      show_labels = true;
      label_source = "id";
      show_icons = false;
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
