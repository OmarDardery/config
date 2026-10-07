{ flake }:
let
  inherit (flake.inputs.nixpkgs) lib;
  profile = flake.lib.deployment;
  base = flake.homeConfigurations.${profile.profileName};
  alternate = profile // {
    username = "portable";
    homeDirectory = "/srv/portable user";
    configRepo = "/srv/portable user/configs/\"checkout\"/\${literal}";
    profileName = "portable-test";
    hostName = "portable-host";
    gitName = null;
    gitEmail = null;
  };
  portable = base.extendModules {
    specialArgs.profile = alternate;
    modules = [ { xdg.stateHome = "${alternate.homeDirectory}/state \"quoted\""; } ];
  };
  home = portable.config;
  system = flake.nixosConfigurations.${profile.hostName}.config;
  vscodeThemeExtension = lib.findFirst (
    extension: (extension.vscodeExtName or "") == "noctalia"
  ) null home.programs.vscodium.profiles.default.extensions;
  toolchain = import ../nixos/home/development/toolchain.nix { inherit (base) pkgs; };
  nixd = toolchain.nixdSettings {
    profile = alternate;
    isNixOS = false;
  };
  checks = {
    identity =
      home.home.username == alternate.username && home.home.homeDirectory == alternate.homeDirectory;
    noAuthorIdentity = !(home.programs.git.settings ? user);
    rebuild = home.programs.zsh.shellAliases.up == "nh home switch -c portable-test";
    repository = home.programs.nh.flake == "path:${alternate.configRepo}";
    noNixOSXkb = !(home.home.sessionVariables ? XKB_CONFIG_ROOT);
    nativeShell = home.programs.bash.enable && home.programs.zsh.enable;
    sharedAliases = home.programs.bash.shellAliases.up == home.programs.zsh.shellAliases.up;
    nixFeatures =
      home.nix.settings.experimental-features == [
        "nix-command"
        "flakes"
      ];
    nixd = home.programs.vscodium.profiles.default.userSettings."nix.serverSettings".nixd == nixd;
    noSystemOptions = !(nixd.options ? nixos);
    templates =
      home.programs.noctalia.settings.theme.templates.user.kitty.output_path
      == "${home.xdg.stateHome}/noctalia/theme/kitty.conf";
    cursor = home.programs.umbriel.settings.input.cursor.size == home.home.pointerCursor.size;
    keyboard = home.programs.umbriel.settings.input.keyboard.layout == "us,ara";
    umbrielInput =
      home.programs.umbriel.settings.input.touchpad.tap
      && home.programs.umbriel.settings.input.touchpad.natural_scroll
      && home.programs.umbriel.settings.input.mouse.accel_profile == "flat"
      && home.programs.umbriel.settings.input.focus.follows_mouse;
    umbrielLayout =
      home.programs.umbriel.settings.layout.mode == "dwindle"
      && system.home-manager.users.${profile.username}.programs.umbriel.settings.layout.mode == "dwindle"
      && home.programs.umbriel.settings.layout.gap == 6
      && home.programs.umbriel.settings.layout.tabs.default_display == "tabbed"
      && home.programs.umbriel.settings.workspaces.back_and_forth
      && home.programs.umbriel.settings.workspaces.empty_above;
    umbrielKeybinds =
      home.programs.umbriel.settings.keybinds."Mod+Return".action == "window-toggle-floating"
      &&
        home.programs.umbriel.settings.keybinds."Mod+Space".action
        == "spawn:noctalia msg panel-toggle launcher"
      && home.programs.umbriel.settings.keybinds."Mod+Shift+Left" == "output-focus-left"
      && home.programs.umbriel.settings.keybinds."Mod+Ctrl+9" == "column-move-to-workspace:9"
      && home.programs.umbriel.settings.keybinds."Mod+Tab" == "workspace-focus-last"
      && home.programs.umbriel.settings.keybinds."Mod+Escape".allow_when_inhibited
      && home.programs.umbriel.settings.keybinds."XF86AudioMicMute".allow_when_locked
      && home.programs.umbriel.settings.keybinds."Mod+Ctrl+WheelDown".cooldown_ms == 150
      && !(home.programs.umbriel.settings.keybinds ? "Mod+Shift+M");
    umbrielKeyCoverage =
      builtins.length (builtins.attrNames home.programs.umbriel.settings.keybinds) == 99;
    powerButton =
      system.services.logind.settings.Login.HandlePowerKey == "ignore"
      && system.services.logind.settings.Login.HandlePowerKeyLongPress == "ignore"
      &&
        home.programs.umbriel.settings.keybinds."XF86PowerOff".action == "spawn:noctalia msg session lock"
      && !home.programs.umbriel.settings.keybinds."XF86PowerOff".repeat
      && home.programs.umbriel.settings.keybinds."XF86PowerOff".allow_when_locked
      && home.programs.umbriel.settings.keybinds."XF86PowerOff".allow_when_inhibited;
    lockScreenPowerOptions =
      home.programs.noctalia.settings.lockscreen_widgets.widget."lockscreen-login-box@eDP-1".settings.show_session_buttons
      && home.programs.noctalia.settings.lockscreen_widgets.widget."lockscreen-login-box@eDP-2".settings.show_session_buttons
      &&
        map (entry: entry.action) home.programs.noctalia.settings.shell.session.actions == [
          "lock"
          "logout"
          "lock_and_suspend"
          "reboot"
          "shutdown"
          "suspend"
        ]
      &&
        (builtins.elemAt home.programs.noctalia.settings.shell.session.actions 5).command
        == "noctalia msg session lock-and-suspend";
    pythonNativeLibraries =
      builtins.all (package: builtins.elem package system.programs.nix-ld.libraries) (
        (import ../nixos/home/development/toolchain.nix {
          inherit (flake.nixosConfigurations.${profile.hostName}) pkgs;
        }).pythonNativeLibraries
      )
      &&
        flake.devShells.${profile.system}.python.LD_LIBRARY_PATH
        == lib.makeLibraryPath toolchain.pythonNativeLibraries
      && !(home.home.sessionVariables ? LD_LIBRARY_PATH);
    boundedJournal = builtins.all (setting: lib.hasInfix setting system.services.journald.extraConfig) [
      "SystemMaxUse=1G"
      "RuntimeMaxUse=256M"
      "MaxRetentionSec=1month"
    ];
    idlePolicy =
      home.programs.noctalia.settings.idle.behavior.lock.enabled
      && home.programs.noctalia.settings.idle.behavior.lock.timeout == 600
      && home.programs.noctalia.settings.idle.behavior.lock.action == "lock"
      && home.programs.noctalia.settings.idle.behavior."screen-off".enabled
      && home.programs.noctalia.settings.idle.behavior."screen-off".timeout == 660
      && home.programs.noctalia.settings.idle.behavior."screen-off".action == "screen_off"
      && !(home.programs.noctalia.settings.idle.behavior ? suspend);
    dockerBuildCache =
      system.virtualisation.docker.enable
      && system.virtualisation.docker.daemon.settings.builder.gc.enabled
      && system.virtualisation.docker.daemon.settings.builder.gc.defaultKeepStorage == "15GB";
    goToolPaths =
      home.programs.vscodium.profiles.default.userSettings."go.alternateTools".gofumpt
      == "${base.pkgs.gofumpt}/bin/gofumpt"
      &&
        home.programs.vscodium.profiles.default.userSettings."go.alternateTools".goimports
        == "${base.pkgs.gotools}/bin/goimports";
    umbrielTabNavigation =
      lib.hasSuffix " focus-up" home.programs.umbriel.settings.keybinds."Mod+K"
      &&
        home.programs.umbriel.settings.keybinds."Mod+WheelUp".action
        == home.programs.umbriel.settings.keybinds."Mod+K"
      &&
        home.programs.umbriel.settings.keybinds."Mod+WheelDown".action
        == home.programs.umbriel.settings.keybinds."Mod+J"
      && lib.hasSuffix " move-down" home.programs.umbriel.settings.keybinds."Mod+Ctrl+Down"
      && !home.programs.umbriel.settings.layout.tabs.wrap_focus;
    umbrielWorkspaceNavigation =
      home.programs.umbriel.settings.keybinds."Mod+Up" == "workspace-previous"
      && home.programs.umbriel.settings.keybinds."Mod+Down" == "workspace-next"
      && home.programs.umbriel.settings.keybinds."Mod+WheelUp".cooldown_ms == 150;
    umbrielLayoutSwitch =
      home.programs.umbriel.settings.keybinds."Mod+D".action == "workspace-set-layout:toggle"
      && !home.programs.umbriel.settings.keybinds."Mod+D".repeat;
    umbrielLaptopMirror =
      system.home-manager.users.${profile.username}.programs.umbriel.settings.keybinds."Mod+Shift+M".action
      == "spawn:mirror-laptop";
    umbrielTheme =
      home.programs.umbriel.settings.include.optional.files
      == [ "${home.xdg.stateHome}/noctalia/theme/umbriel.toml" ]
      &&
        home.programs.noctalia.settings.theme.templates.user.umbriel.output_path
        == "${home.xdg.stateHome}/noctalia/theme/umbriel.toml";
    noNiri =
      !system.programs.niri.enable
      && !(home.xdg.configFile ? niri)
      && !(home.xdg.portal.config ? niri)
      && !(home.programs.noctalia.settings.theme.templates.user ? niri);
    defaultDesktop = system.services.displayManager.defaultSession == "umbriel";
    noStaticPalette =
      !(home.programs.umbriel.settings ? colors) && !(home.programs.umbriel.settings.include ? files);
    vscodeTheme =
      vscodeThemeExtension != null
      && home.programs.vscodium.profiles.default.userSettings."workbench.colorTheme" == "NoctaliaTheme"
      && home.programs.vscodium.profiles.default.userSettings."window.autoDetectColorScheme"
      &&
        home.programs.vscodium.profiles.default.userSettings."workbench.preferredLightColorTheme"
        == "NoctaliaLight"
      && !(home.programs.vscodium.profiles.default.userSettings ? "workbench.colorCustomizations")
      && !(home.programs.vscodium.profiles.default.userSettings ? "editor.tokenColorCustomizations");
    applicationThemes =
      builtins.all (name: home.programs.noctalia.settings.theme.templates.user ? ${name})
        [
          "umbriel"
          "vscode"
          "steam"
          "zen_chrome"
          "zen_content"
          "kitty"
          "nvim"
          "fzf"
          "lazygit"
          "bat"
          "btop"
          "yazi"
          "yazi_syntax"
        ];
    systemThemes =
      home.qt.platformTheme.name == "kde"
      && home.programs.umbriel.settings.environment.QT_QPA_PLATFORMTHEME == "kde"
      && builtins.elem "kcolorscheme" home.programs.noctalia.settings.theme.templates.builtin_ids;
    steamHomeOwned =
      !system.programs.steam.enable
      && builtins.any (package: lib.getName package == "steam") home.home.packages
      && builtins.any (
        package: lib.getName package == "steam"
      ) system.home-manager.users.${profile.username}.home.packages
      && !(builtins.any (package: lib.getName package == "steam") system.environment.systemPackages);
    steamHostIntegration =
      system.hardware.graphics.enable32Bit
      && system.hardware.steam-hardware.enable
      && system.security.wrappers.gamemoded.capabilities == "cap_sys_nice+ep"
      && system.services.pipewire.alsa.support32Bit == system.services.pipewire.alsa.enable;
    portals = builtins.all (
      package:
      builtins.elem package home.dbus.packages && builtins.elem package home.systemd.user.packages
    ) ([ base.pkgs.xdg-desktop-portal ] ++ home.xdg.portal.extraPortals);
    userFlatpak =
      !system.services.flatpak.enable
      && builtins.elem base.pkgs.flatpak home.home.packages
      && builtins.elem "${home.xdg.dataHome}/flatpak/exports/share" home.xdg.systemDirs.data
      && home.services.flatpak.update.auto.enable
      && !home.services.flatpak.uninstallUnmanaged
      && !home.services.flatpak.uninstallUnused;
    userApplications =
      !system.services.gnome.core-apps.enable
      && !system.programs.wireshark.enable
      && home.services.kdeconnect.enable
      && system.programs.kdeconnect.package == null
      && builtins.all (package: builtins.elem package home.home.packages) [
        base.pkgs.gnome-control-center
        base.pkgs.gnome-disk-utility
        base.pkgs.wireshark
        base.pkgs.gpu-screen-recorder
        base.pkgs.gvfs
        base.pkgs.gamemode
      ];
    capturePrivileges =
      system.security.wrappers.dumpcap.capabilities == "cap_net_raw,cap_net_admin+eip"
      && system.security.wrappers.dumpcap.group == "wireshark"
      && system.security.wrappers.gsr-kms-server.group == "recording"
      && system.security.wrappers.gsr-kms-server.permissions == "u+rx,g+rx,o-rwx";
    userPackagePolicy =
      !system.home-manager.useGlobalPkgs
      && (system.nixpkgs.config.permittedInsecurePackages or [ ]) == [ ]
      && (portable.pkgs.config.permittedInsecurePackages or [ ]) == [ "electron-40.10.5" ];
    userSessionPath = builtins.elem "${home.home.homeDirectory}/.local/bin" home.home.sessionPath;
    nativeAuthentication =
      !home.programs.noctalia.settings.shell.polkit_agent
      && builtins.length home.programs.umbriel.settings.general.autostart == 2
      && system.home-manager.users.${profile.username}.programs.noctalia.settings.shell.polkit_agent;
    secretPortal =
      home.xdg.portal.config.gnome."org.freedesktop.impl.portal.Secret" == "gnome-keyring"
      && home.xdg.portal.config.umbriel."org.freedesktop.impl.portal.Secret" == "gnome-keyring"
      && system.xdg.portal.config.umbriel."org.freedesktop.impl.portal.Secret" == "gnome-keyring";
    nativeFlatpaks =
      map (p: p.appId) home.services.flatpak.packages == [
        "com.orcaslicer.OrcaSlicer"
        "com.vysp3r.ProtonPlus"
      ];
    hardwarePolicy = system.hardware.nvidia.open && system.hardware.nvidia.prime.offload.enable;
    localsendAbsent = !system.programs.localsend.enable;
    firewallPreserved =
      system.networking.firewall.enable
      && system.programs.kdeconnect.enable
      &&
        builtins.all
          (
            ranges:
            builtins.elem {
              from = 1714;
              to = 1764;
            } ranges
          )
          [
            system.networking.firewall.allowedTCPPortRanges
            system.networking.firewall.allowedUDPPortRanges
          ];
  };
  failed = builtins.attrNames (lib.filterAttrs (_: passed: !passed) checks);
in
assert lib.assertMsg (
  failed == [ ]
) "Portability checks failed: ${builtins.concatStringsSep ", " failed}";
{
  inherit checks;
  # These fixtures exercise actual generated files, not only mocked identities.
  fixtures = {
    kitty = home.xdg.configFile."kitty".source;
    umbriel = home.xdg.configFile."umbriel/config.toml".source;
    vscode = vscodeThemeExtension;
    units = home.xdg.dataFile."systemd/user".source;
    dbus = home.xdg.dataFile."dbus-1/services".source;
  };
  nixdExpressions = [
    nixd.nixpkgs.expr
    nixd.options.home_manager.expr
  ];
}
