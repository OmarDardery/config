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
    specialArgs = {
      profile = alternate;
      # Exercise a generic Linux machine, independent of the deployed laptop.
      isLaptop = false;
    };
    modules = [ { xdg.stateHome = "${alternate.homeDirectory}/state \"quoted\""; } ];
  };
  tools = portable.config;
  desktop = flake.inputs.home-manager.lib.homeManagerConfiguration {
    inherit (base) pkgs;
    extraSpecialArgs = {
      inherit (flake) inputs;
      profile = alternate;
      osConfig = system;
      isNixOS = true;
      isLaptop = false;
    };
    modules = [
      ../home/nixos.nix
      { xdg.stateHome = "${alternate.homeDirectory}/state \"quoted\""; }
    ];
  };
  home = desktop.config;
  system = flake.nixosConfigurations.${profile.hostName}.config;
  vscodeThemeExtension = lib.findFirst (
    extension: (extension.vscodeExtName or "") == "noctalia"
  ) null home.programs.vscodium.profiles.default.extensions;
  toolchain = import ../home/development/toolchain.nix { inherit (base) pkgs; };
  nixd = toolchain.nixdSettings {
    profile = alternate;
    isNixOS = true;
  };
  checks = {
    performancePolicy =
      system.boot.loader.timeout == 2
      && system.boot.loader.systemd-boot.configurationLimit == 10
      && builtins.elem "-j=4" (toolchain.clangdArgs alternate.homeDirectory)
      && home.programs.vscodium.profiles.default.userSettings."rust-analyzer.numThreads" == 4
      &&
        home.programs.vscodium.profiles.default.userSettings."rust-analyzer.cargo.extraEnv".CARGO_BUILD_JOBS
        == "4"
      && !(home.home.sessionVariables ? CARGO_BUILD_JOBS)
      && system.hardware.block.defaultScheduler == null
      && !system.services.scx.enable
      && !(system.systemd.services ? scx)
      && system.specialisation == { }
      && system.boot.kernelPackages.kernel == base.pkgs.linuxPackages_latest.kernel;
    identity =
      home.home.username == alternate.username && home.home.homeDirectory == alternate.homeDirectory;
    noAuthorIdentity = !(home.programs.git.settings ? user);
    rebuild = tools.programs.zsh.shellAliases.up == "nh home switch -c portable-test";
    repository = home.programs.nh.flake == "path:${alternate.configRepo}";
    noNixOSXkb = !(tools.home.sessionVariables ? XKB_CONFIG_ROOT);
    nativeShell = tools.programs.bash.enable && tools.programs.zsh.enable;
    sharedAliases =
      builtins.all
        (name: tools.programs.bash.shellAliases.${name} == tools.programs.zsh.shellAliases.${name})
        [
          "up"
          "rebuild"
          "nbuild"
          "neval"
          "ncheck"
          "nupdate"
          "update"
          "nfmt"
          "cnf"
          "cconf"
        ];
    commandWorkflow =
      home.home.shellAliases.up == home.home.shellAliases.rebuild
      && lib.hasInfix "--no-write-lock-file" home.home.shellAliases.neval
      && lib.hasInfix "--no-build" home.home.shellAliases.neval
      && lib.hasInfix (lib.escapeShellArg alternate.configRepo) home.home.shellAliases.cnf
      && lib.hasInfix (lib.escapeShellArg alternate.configRepo) home.home.shellAliases.nfmt
      && home.home.shellAliases.lt == "eza --tree --level=2";
    nixFeatures =
      tools.nix.settings.experimental-features == [
        "nix-command"
        "flakes"
      ];
    nixd = home.programs.vscodium.profiles.default.userSettings."nix.serverSettings".nixd == nixd;
    noSystemOptions =
      !(
        (toolchain.nixdSettings {
          profile = alternate;
          isNixOS = false;
        }).options
          ? nixos
      );
    templates =
      !(builtins.elem "kitty" home.programs.noctalia.settings.theme.templates.builtin_ids)
      && home.programs.noctalia.settings.theme.templates.user ? kitty
      && home.programs.kitty.enable
      && home.xdg.configFile."kitty/kitty.conf".force
      && !(home.home.activation ? kittyWritableConfig);
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
      && home.programs.umbriel.settings.layout.gap == 8
      && home.programs.umbriel.settings.layout.tabs.default_display == "tabbed"
      && home.programs.umbriel.settings.workspaces.back_and_forth
      && home.programs.umbriel.settings.workspaces.empty_above;
    umbrielKeybinds =
      home.programs.umbriel.settings.keybinds."Mod+Return".action == "window-toggle-floating"
      &&
        home.programs.umbriel.settings.keybinds."Mod+Space".action
        == "spawn:noctalia msg panel-toggle launcher"
      &&
        home.programs.umbriel.settings.keybinds."Mod+S".action
        == "spawn:noctalia msg plugin alexander/screen-toolkit:service all toggle"
      && home.programs.umbriel.settings.keybinds."Mod+Shift+Left" == "output-focus-left"
      && home.programs.umbriel.settings.keybinds."Mod+Ctrl+9" == "column-move-to-workspace:9"
      && home.programs.umbriel.settings.keybinds."Mod+Tab" == "workspace-focus-last"
      && home.programs.umbriel.settings.keybinds."Mod+Escape".allow_when_inhibited
      && home.programs.umbriel.settings.keybinds."XF86AudioMicMute".allow_when_locked
      && home.programs.umbriel.settings.keybinds."Mod+Ctrl+WheelDown".cooldown_ms == 150
      && !(home.programs.umbriel.settings.keybinds ? "Mod+Shift+M");
    umbrielKeyCoverage = builtins.all (key: home.programs.umbriel.settings.keybinds ? ${key}) [
      "Mod+A"
      "Mod+S"
      "Mod+V"
      "Mod+N"
      "Mod+P"
      "Mod+R"
      "Mod+Shift+Space"
      "Mod+Ctrl+Space"
      "Mod+Alt+Space"
      "Mod+Alt+1"
      "Mod+Alt+2"
      "Mod+Alt+C"
      "Mod+Alt+N"
      "Mod+Alt+D"
      "Print"
    ];
    powerButton =
      system.services.logind.settings.Login.HandlePowerKey == "ignore"
      && system.services.logind.settings.Login.HandlePowerKeyLongPress == "ignore"
      &&
        home.programs.umbriel.settings.keybinds."XF86PowerOff".action == "spawn:noctalia msg session lock"
      && !home.programs.umbriel.settings.keybinds."XF86PowerOff".repeat
      && home.programs.umbriel.settings.keybinds."XF86PowerOff".allow_when_locked
      && home.programs.umbriel.settings.keybinds."XF86PowerOff".allow_when_inhibited;
    lockScreenPowerOptions =
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
        (import ../home/development/toolchain.nix {
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
      home.programs.umbriel.settings.keybinds."Mod+D".action
      == "workspace-set-layout:toggle:dwindle,scrolling"
      && !home.programs.umbriel.settings.keybinds."Mod+D".repeat;
    noMasterLayout = builtins.all (
      binding:
      let
        action = if builtins.isString binding then binding else binding.action;
      in
      !(lib.hasInfix "master" action)
    ) (builtins.attrValues home.programs.umbriel.settings.keybinds);
    editorWorkflow =
      home.programs.vscodium.profiles.default.userSettings."python.defaultInterpreterPath"
      == "\${workspaceFolder}/.venv"
      &&
        home.programs.vscodium.profiles.default.userSettings."basedpyright.analysis.typeCheckingMode"
        == "standard"
      && home.programs.vscodium.profiles.default.userSettings."go.lintOnSave" == "off"
      &&
        home.programs.vscodium.profiles.default.userSettings."basedpyright.importStrategy"
        == "fromEnvironment"
      && home.programs.vscodium.profiles.default.userSettings."ruff.importStrategy" == "fromEnvironment"
      && home.programs.vscodium.profiles.default.userSettings."basedpyright.disableOrganizeImports"
      && !(home.programs.vscodium.profiles.default.userSettings ? "ruff.path")
      && !(home.programs.vscodium.profiles.default.userSettings ? "prettier.prettierPath")
      && home.xdg.dataFile ? "jupyter/kernels/nix-python/kernel.json";
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
          "nvim"
          "fzf"
          "lazygit"
          "bat"
          "btop"
          "yazi"
          "yazi_syntax"
          "zellij"
          "opencode"
          "fastfetch"
          "libreoffice"
          "gimp"
          "inkscape"
        ];
    upstreamUmbrielTemplate = lib.hasSuffix "/assets/templates/umbriel/umbriel.toml" home.programs.noctalia.settings.theme.templates.user.umbriel.input_path;
    terminalWorkspace =
      home.programs.zellij.enable
      && tools.programs.zellij.enable
      && home.programs.zellij.settings.default_mode == "locked"
      && home.programs.zellij.settings.on_force_close == "detach"
      && home.programs.zellij.settings.theme == "noctalia"
      && !(tools.programs.zellij.settings ? theme)
      && home.programs.kitty.settings.shell == lib.getExe home.programs.zellij.package
      && !home.programs.zellij.enableZshIntegration
      && home.programs.yazi.shellWrapperName == "y"
      && home.programs.opencode.tui.theme == "noctalia";
    systemThemes =
      home.qt.platformTheme.name == "kde"
      && home.programs.umbriel.settings.environment.QT_QPA_PLATFORMTHEME == "kde"
      && builtins.elem "kcolorscheme" home.programs.noctalia.settings.theme.templates.builtin_ids;
    steamSystemOwned =
      system.programs.steam.enable
      && builtins.elem system.programs.steam.package system.environment.systemPackages
      && !(builtins.any (p: lib.getName p == "steam") home.home.packages);
    steamHostIntegration =
      system.hardware.graphics.enable32Bit
      && system.hardware.steam-hardware.enable
      && system.security.wrappers.gamemoded.capabilities == "cap_sys_nice+ep"
      && system.services.pipewire.alsa.support32Bit == system.services.pipewire.alsa.enable;
    gamemodeAuthorization =
      builtins.elem "gamemode" system.users.users.${profile.username}.extraGroups
      && builtins.any (package: package == base.pkgs.gamemode) system.environment.systemPackages;
    rustToolchain = builtins.all (package: builtins.elem package home.home.packages) [
      base.pkgs.rustc
      base.pkgs.cargo
      base.pkgs.clippy
      base.pkgs.rustfmt
      base.pkgs.stdenv.cc
    ];
    batSeedOrdering =
      builtins.elem "linkGeneration" home.home.activation.initializeNoctaliaTemplates.before
      && builtins.elem "writeBoundary" home.home.activation.initializeNoctaliaTemplates.after;
    portableDesktopBoundary =
      !tools.xdg.portal.enable
      && !tools.gtk.enable
      && !tools.qt.enable
      && !tools.programs.vscodium.enable
      && !tools.programs.kitty.enable
      && !tools.services.kdeconnect.enable
      && !tools.targets.genericLinux.gpu.enable
      && !tools.xdg.mimeApps.enable
      && !tools.xdg.configFile."nvim/lua/plugins/noctalia.lua".enable
      && !(tools.home.sessionVariables ? QT_QPA_PLATFORMTHEME)
      && !(tools.home.sessionVariables ? GIO_EXTRA_MODULES)
      && !(tools.home.sessionSearchVariables ? GIO_EXTRA_MODULES)
      && !(tools.home.sessionVariables ? LD_LIBRARY_PATH)
      && !(tools.xdg.configFile ? "umbriel/config.toml")
      && !(tools.xdg.configFile ? "noctalia/config.toml")
      && tools.systemd.user.services == { }
      && builtins.all (name: !(builtins.any (p: lib.getName p == name) tools.home.packages)) [
        "steam"
        "flatpak"
        "gvfs"
        "gamemode"
        "umbriel"
        "noctalia"
        "opentabletdriver"
      ];
    portableDevelopment =
      tools.programs.neovim.enable
      && tools.programs.git.enable
      && tools.programs.direnv.enable
      && builtins.elem base.pkgs.uv tools.home.packages;
    portals =
      system.xdg.portal.enable
      && builtins.elem system.programs.umbriel.portalPackage system.xdg.portal.extraPortals
      && !home.xdg.portal.enable;
    userFlatpak =
      system.services.flatpak.enable
      && !(builtins.elem base.pkgs.flatpak home.home.packages)
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
      ];
    fileManager =
      system.programs.thunar.enable
      && system.services.gvfs.enable
      && system.services.tumbler.enable
      && builtins.elem base.pkgs.thunar-archive-plugin system.programs.thunar.plugins
      && builtins.elem base.pkgs.thunar-volman system.programs.thunar.plugins
      && home.xdg.mimeApps.defaultApplications."inode/directory" == [ "thunar.desktop" ]
      && home.programs.umbriel.settings.keybinds."Mod+E".action == "spawn:thunar"
      && home.xfconf.settings.thunar.misc-volume-management
      && home.xdg.userDirs.createDirectories
      && !(home.home.sessionSearchVariables ? GIO_EXTRA_MODULES);
    nativeSessionServices =
      system.programs.umbriel.enable
      && home.programs.umbriel.package == system.programs.umbriel.package
      && builtins.elem system.programs.umbriel.package system.services.displayManager.sessionPackages
      && system.hardware.opentabletdriver.enable
      && system.programs.gamemode.enable
      && !(home.systemd.user.services ? opentabletdriver)
      && !(home.systemd.user.services ? gamemoded);
    noUnrequestedApplications =
      builtins.all
        (
          packages:
          !(builtins.any (
            package:
            builtins.elem (lib.getName package) [
              "nautilus"
              "obsidian"
              "gnome-maps"
              "gnome-connections"
              "epiphany"
              "sushi"
              "rnote"
              "satty"
              "protonup-ng"
            ]
          ) packages)
        )
        [
          home.home.packages
          system.home-manager.users.${profile.username}.home.packages
          system.environment.systemPackages
        ];
    capturePrivileges =
      system.security.wrappers.dumpcap.capabilities == "cap_net_raw,cap_net_admin+eip"
      && system.security.wrappers.dumpcap.group == "wireshark"
      && system.security.wrappers.gsr-kms-server.group == "recording"
      && system.security.wrappers.gsr-kms-server.permissions == "u+rx,g+rx,o-rwx";
    sharedPackagePolicy =
      system.home-manager.useGlobalPkgs
      && system.home-manager.useUserPackages
      && system.nixpkgs.config.permittedInsecurePackages == [ "electron-40.10.5" ]
      &&
        home.programs.neovim.package
        == system.home-manager.users.${profile.username}.programs.neovim.package;
    desktopBasics =
      builtins.all
        (
          configuration:
          configuration.xdg.mimeApps.defaultApplications."application/pdf" == [ "org.gnome.Papers.desktop" ]
          &&
            configuration.xdg.mimeApps.defaultApplications."application/zip"
            == [ "org.gnome.FileRoller.desktop" ]
          && configuration.xdg.mimeApps.defaultApplications."video/mp4" == [ "mpv.desktop" ]
          && configuration.xdg.mimeApps.defaultApplications."image/png" == [ "imv.desktop" ]
          && builtins.all (package: builtins.elem package configuration.home.packages) [
            base.pkgs.gimp
            base.pkgs.inkscape
            base.pkgs.simple-scan
            base.pkgs.system-config-printer
            base.pkgs.file-roller
            base.pkgs.noto-fonts-color-emoji
          ]
        )
        [
          home
          system.home-manager.users.${profile.username}
        ];
    desktopHostServices =
      system.services.pipewire.enable
      && system.services.pipewire.pulse.enable
      && system.services.pipewire.alsa.enable
      && !system.services.pulseaudio.enable
      && system.services.printing.enable
      && system.services.ipp-usb.enable
      && system.hardware.sane.enable
      && system.services.avahi.nssmdns4
      && !system.services.printing.openFirewall
      && system.programs.mtr.enable
      && system.security.wrappers.mtr-packet.capabilities == "cap_net_raw+p";
    userSessionPath = builtins.elem "${home.home.homeDirectory}/.local/bin" home.home.sessionPath;
    nativeAuthentication =
      home.programs.noctalia.settings.shell.polkit_agent
      && builtins.length home.programs.umbriel.settings.general.autostart == 1;
    secretPortal =
      system.xdg.portal.config.umbriel."org.freedesktop.impl.portal.Secret" == "gnome-keyring";
    nativeFlatpaks =
      map (p: p.appId) home.services.flatpak.packages == [
        "com.orcaslicer.OrcaSlicer"
        "com.vysp3r.ProtonPlus"
        "org.freedesktop.Platform.GL.nvidia-${
          lib.replaceStrings [ "." ] [ "-" ] system.hardware.nvidia.package.version
        }"
      ];
    hardwarePolicy = system.hardware.nvidia.open && system.hardware.nvidia.prime.offload.enable;
    localsendAbsent = !system.programs.localsend.enable;
    nixMonitorUpdatesFlakes =
      let
        settings = system.home-manager.users.${profile.username}.programs.noctalia.settings;
        command = settings.plugin_settings."avivbintangaringga/nix-monitor".update_command;
      in
      command == system.home-manager.users.${profile.username}.home.shellAliases.update
      && lib.hasInfix "/bin/config-update " command
      && builtins.elem "davemhammer/tailscale" settings.plugins.enabled;
    noctaliaSources =
      let
        settings = home.programs.noctalia.settings;
        sources = settings.plugins.source;
        managed = builtins.elemAt sources 2;
      in
      map (source: source.name) sources == [
        "official"
        "community"
        "nix-managed"
      ]
      && managed.kind == "path"
      && lib.hasPrefix builtins.storeDir managed.location
      && builtins.all (source: source.enabled) sources
      && settings.plugins.auto_update == "none"
      && !(home.xdg.dataFile ? "noctalia/plugins/screen-toolkit");
    noctaliaDesktopFlow =
      home.programs.noctalia.settings.shell.umbriel_overview_type_to_launch_enabled
      && home.programs.noctalia.settings.shell.launcher.layout == "simple"
      && home.programs.noctalia.settings.widget.privacy.hide_inactive
      && home.programs.noctalia.settings.notification.follow_focused_output
      && home.programs.noctalia.settings.notification.max_visible == 3
      && !home.programs.noctalia.settings.bar.default.reserve_space
      && !home.programs.noctalia.settings.dock.reserve_space
      &&
        home.programs.umbriel.settings.keybinds."Alt+Tab".action
        == "spawn:noctalia msg window-switcher hold"
      &&
        home.programs.umbriel.settings.keybinds."Mod+Alt+V".action
        == "spawn:noctalia msg panel-toggle davemhammer/tailscale:manager";
    tailscaleOnlyKdeConnect =
      system.networking.firewall.enable
      && system.services.tailscale.enable
      && !system.programs.kdeconnect.enable
      && system.services.tailscale.extraSetFlags == [ "--operator=${profile.username}" ]
      && !builtins.elem {
        from = 1714;
        to = 1764;
      } system.networking.firewall.allowedTCPPortRanges
      && !builtins.elem {
        from = 1714;
        to = 1764;
      } system.networking.firewall.allowedUDPPortRanges
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
            system.networking.firewall.interfaces.${system.services.tailscale.interfaceName}.allowedTCPPortRanges
            system.networking.firewall.interfaces.${system.services.tailscale.interfaceName}.allowedUDPPortRanges
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
    kitty = home.xdg.configFile."kitty/kitty.conf".source;
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
