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
  tools = portable.config;
  desktop = flake.inputs.home-manager.lib.homeManagerConfiguration {
    inherit (base) pkgs;
    extraSpecialArgs = {
      inherit (flake) inputs;
      profile = alternate;
      isNixOS = true;
      isLaptop = false;
      desktopEnabled = true;
    };
    modules = [
      flake.modules.homeManager.desktop
      { xdg.stateHome = "${alternate.homeDirectory}/state \"quoted\""; }
    ];
  };
  home = desktop.config;
  nativeDesktop = flake.homeConfigurations."${profile.profileName}-desktop".config;
  system = flake.nixosConfigurations.${profile.hostName}.config;
  integrated = system.home-manager.users.${profile.username};
  toolchain = import ../lib/toolchain.nix { inherit (base) pkgs; };
  nixd = toolchain.nixdSettings {
    profile = alternate;
    isNixOS = true;
  };
  vscodeThemeExtension = lib.findFirst (
    e: (e.vscodeExtName or "") == "noctalia"
  ) null home.programs.vscodium.profiles.default.extensions;
  onlyEditors =
    c:
    builtins.all (
      p:
      builtins.elem p (
        [ c.home.sessionVariablesPackage ]
        ++ lib.optional c.programs.neovim.enable c.programs.neovim.finalPackage
        ++ lib.optional (c.programs.vscodium.package != null) c.programs.vscodium.package
      )
    ) c.home.packages;
  checks = {
    packageBoundary = builtins.all onlyEditors [
      tools
      home
      nativeDesktop
      integrated
    ];
    nativeConfigurationOnly =
      builtins.all
        (
          c:
          c.home.packages == [ c.home.sessionVariablesPackage ]
          && !c.programs.neovim.enable
          && c.programs.vscodium.package == null
          && c.programs.vscodium.profiles.default.extensions == [ ]
          && c.xdg.configFile."nvim/init.lua".enable
          && c.xdg.configFile."umbriel/config.toml".enable
          && c.xdg.configFile."noctalia/config.toml".enable
          && c.xdg.configFile."kitty/kitty.conf".enable
          && c.home.file.".zshrc".enable
        )
        [
          tools
          nativeDesktop
        ];
    nativeToolPaths =
      builtins.all
        (
          c:
          !lib.hasInfix "/nix/store/" (
            builtins.toJSON {
              vscode = c.programs.vscodium.profiles.default.userSettings;
              lua = lib.mapAttrs (_: f: f.text) (
                lib.filterAttrs (name: f: f.enable && f.text != null && lib.hasPrefix "nvim/" name) c.xdg.configFile
              );
            }
          )
        )
        [
          tools
          nativeDesktop
        ];
    nixosEditors = builtins.all (c: c.programs.neovim.enable && c.programs.vscodium.package != null) [
      home
      integrated
    ];
    kittyShellIntegration =
      builtins.all
        (
          c:
          c.programs.kitty.shellIntegration.mode == null
          && c.programs.kitty.settings.shell_integration == "enabled"
          && c.programs.kitty.settings.confirm_os_window_close == -1
          && !c.programs.kitty.shellIntegration.enableBashIntegration
          && !c.programs.kitty.shellIntegration.enableZshIntegration
        )
        [
          tools
          home
          nativeDesktop
          integrated
        ];
    oneYaziWrapper =
      builtins.all (c: !c.programs.yazi.enableBashIntegration && !c.programs.yazi.enableZshIntegration)
        [
          tools
          home
          nativeDesktop
          integrated
        ];
    steamMultilib = system.hardware.graphics.enable32Bit;
    nativePromptTools =
      builtins.elem base.pkgs.zsh system.environment.systemPackages
      && builtins.elem base.pkgs.starship system.environment.systemPackages;
    noHomeServices = builtins.all (c: c.systemd.user.services == { } && c.systemd.user.timers == { }) [
      tools
      home
      nativeDesktop
      integrated
    ];
    noHomeDesktopInstall =
      builtins.all
        (
          c:
          !c.gtk.enable
          && !c.qt.enable
          && !c.xdg.portal.enable
          && c.programs.kitty.package == null
          && c.programs.yazi.package == null
          && c.programs.git.package == null
          && !c.programs.home-manager.enable
        )
        [
          tools
          home
          nativeDesktop
          integrated
        ];
    portableBoundary =
      !tools.targets.genericLinux.gpu.enable
      && tools.xdg.configFile ? "umbriel/config.toml"
      && tools.xdg.configFile ? "noctalia/config.toml"
      && !(tools.home.sessionVariables ? LD_LIBRARY_PATH)
      && !(tools.home.sessionVariables ? XKB_CONFIG_ROOT);
    optionalDesktopFiles =
      nativeDesktop.xdg.configFile ? "umbriel/config.toml"
      && nativeDesktop.xdg.configFile ? "noctalia/config.toml"
      && !nativeDesktop.programs.umbriel.settings ? output;
    identity =
      tools.home.username == alternate.username
      && tools.home.homeDirectory == alternate.homeDirectory
      && !(tools.programs.git.settings ? user);
    portableCommands =
      lib.hasInfix "#home-manager" tools.home.shellAliases.up
      && lib.hasInfix (lib.escapeShellArg "path:${alternate.configRepo}#${alternate.profileName}") tools.home.shellAliases.up
      && tools.home.shellAliases.up == tools.home.shellAliases.rebuild
      && tools.home.sessionVariables.NH_FLAKE == "path:${alternate.configRepo}";
    nativeBrowser =
      nativeDesktop.xdg.mimeApps.defaultApplications."x-scheme-handler/https"
      == [ "config-browser.desktop" ]
      && nativeDesktop.home.file.".local/bin/desktop-browser".executable
      && nativeDesktop.programs.umbriel.settings.keybinds."Mod+B".action == "spawn:desktop-browser"
      && integrated.xdg.mimeApps.defaultApplications."x-scheme-handler/https" == [ "zen.desktop" ];
    nativeEditorDiscovery =
      builtins.elem "${tools.home.profileDirectory}/bin" tools.home.sessionPath
      && builtins.elem "${tools.home.profileDirectory}/share" tools.home.sessionSearchVariables.XDG_DATA_DIRS;
    nativeShell =
      lib.hasInfix "command -v starship" tools.home.file.".zshrc".text
      && lib.hasInfix "fzf --zsh" tools.home.file.".zshrc".text
      && tools.programs.bash.package == null
      && tools.programs.kitty.settings.shell == "zsh";
    noActivationDownloads =
      builtins.all
        (
          c:
          !(c.home.activation ? flatpak-managed-install)
          && !(c.home.activation ? reloadSystemd && c.systemd.user.services != { })
          && !(c.home.activation ? initializeNoctaliaTemplates)
          && !(c.home.activation ? noctaliaDeclarativeSettings)
        )
        [
          tools
          home
          nativeDesktop
          integrated
        ];
    nativeInitialization =
      system.systemd.user.services.desktop-config.serviceConfig.Type == "oneshot"
      && home.home.file.".local/bin/desktop-apply".executable
      && lib.hasInfix "command -v noctalia" home.home.file.".local/bin/desktop-apply".text;
    installedDesktop =
      builtins.elem system.programs.umbriel.package system.environment.systemPackages
      &&
        builtins.elem flake.inputs.noctalia.packages.${profile.system}.default
          system.environment.systemPackages
      && builtins.elem base.pkgs.kitty system.environment.systemPackages;
    systemFlatpak =
      system.services.flatpak.enable
      && system.systemd.services.flatpak-managed-install.serviceConfig.Type == "exec"
      && system.systemd.services.flatpak-managed-install-timer.serviceConfig.Type == "exec"
      &&
        map (p: p.appId) system.services.flatpak.packages == [
          "com.orcaslicer.OrcaSlicer"
          "com.vysp3r.ProtonPlus"
        ];
    nativeUserServices =
      system.systemd.user.services.kdeconnect.serviceConfig.Type == "dbus"
      &&
        system.systemd.user.services.mpris-proxy.unitConfig.ConditionPathExists == "/sys/class/bluetooth";
    defaultDesktop =
      system.services.displayManager.defaultSession == "umbriel"
      && system.services.displayManager.noctalia-greeter.enable
      && system.services.greetd.enable
      && !system.services.displayManager.gdm.enable
      && !system.services.displayManager.sddm.enable
      && !system.services.desktopManager.gnome.enable
      && system.security.pam.services.greetd.enableGnomeKeyring;
    noDesktopIndexers =
      !system.services.gnome.localsearch.enable
      && !system.services.gnome.evolution-data-server.enable
      && !system.services.gnome.gnome-online-accounts.enable;
    performancePolicy =
      system.boot.kernelPackages.kernel == base.pkgs.linuxPackages_latest.kernel
      && system.services.scx.scheduler == "scx_lavd"
      && system.services.scx.extraArgs == [ "--autopower" ]
      && system.services.power-profiles-daemon.enable
      && !system.services.tlp.enable
      && !system.services.auto-cpufreq.enable
      && system.hardware.block.defaultScheduler == null;
    hardwarePolicy = system.hardware.nvidia.open && system.hardware.nvidia.prime.offload.enable;
    desktopHostServices =
      system.services.pipewire.enable
      && system.services.pipewire.pulse.enable
      && !system.services.pulseaudio.enable
      && system.services.udisks2.enable
      && system.services.printing.enable
      && system.hardware.sane.enable;
    layout =
      home.programs.umbriel.settings.layout.mode == "dwindle"
      &&
        home.programs.umbriel.settings.keybinds."Mod+D".action
        == "workspace-set-layout:toggle:dwindle,scrolling"
      && builtins.all (b: !lib.hasInfix "master" (if builtins.isString b then b else b.action)) (
        builtins.attrValues home.programs.umbriel.settings.keybinds
      );
    keyBindings =
      home.programs.umbriel.settings.keybinds."Mod+S".action
      == "spawn:noctalia msg plugin alexander/screen-toolkit:service all toggle"
      && home.programs.umbriel.settings.keybinds."Mod+T".action == "spawn:kitty"
      && home.programs.umbriel.settings.general.autostart == [ "noctalia" ];
    dynamicTheme =
      !(home.programs.umbriel.settings ? colors)
      && !(home.programs.noctalia.settings.theme ? wallpaper_scheme)
      && !(home.programs.noctalia.settings.wallpaper ? default)
      && !home.programs.noctalia.settings.bar.default.reserve_space
      && home.programs.noctalia.settings.shell.greeter_sync.auto_sync;
    nativeCommands =
      home.programs.kitty.settings.shell == "zsh"
      && lib.hasInfix "umbriel windows" home.home.file.".local/bin/umbriel-row-action".text
      && lib.hasInfix "grim -T" home.home.file.".local/bin/screenshot-window-umbriel".text;
    editorWorkflow =
      tools.programs.vscodium.profiles.default.userSettings."python.defaultInterpreterPath"
      == "\${workspaceFolder}/.venv/bin/python"
      &&
        tools.programs.vscodium.profiles.default.userSettings."basedpyright.analysis.typeCheckingMode"
        == "basic"
      && tools.programs.vscodium.profiles.default.userSettings."python.useEnvironmentsExtension"
      && !tools.xdg.dataFile."jupyter/kernels/nix-python/kernel.json".enable
      && integrated.xdg.dataFile."jupyter/kernels/nix-python/kernel.json".enable
      && !(builtins.elem base.pkgs.vscode-extensions.usernamehw.errorlens tools.programs.vscodium.profiles.default.extensions);
    privateEditorTools =
      builtins.elem base.pkgs.rustc home.programs.neovim.extraPackages
      && builtins.elem base.pkgs.basedpyright home.programs.neovim.extraPackages
      && lib.hasInfix "/bin/notebook-kernel" home.xdg.configFile."nvim/lua/plugins/jupyter.lua".text;
    independentThemes =
      tools.xdg.configFile."nvim/lua/plugins/noctalia.lua".enable
      && home.xdg.configFile."nvim/lua/plugins/noctalia.lua".enable
      && nativeDesktop.xdg.configFile."nvim/lua/plugins/noctalia.lua".enable
      && tools.programs.vscodium.profiles.default.userSettings."workbench.colorTheme" == "NoctaliaTheme"
      && vscodeThemeExtension != null;
    nixd = home.programs.vscodium.profiles.default.userSettings."nix.serverSettings".nixd == nixd;
    tailscaleFirewall =
      system.networking.firewall.enable
      && system.services.tailscale.enable
      && !system.programs.kdeconnect.enable
      &&
        builtins.elem
          {
            from = 1714;
            to = 1764;
          }
          system.networking.firewall.interfaces.${system.services.tailscale.interfaceName}.allowedTCPPortRanges;
  };
  failed = builtins.attrNames (lib.filterAttrs (_: passed: !passed) checks);
in
assert lib.assertMsg (
  failed == [ ]
) "Portability checks failed: ${builtins.concatStringsSep ", " failed}";
{
  inherit checks;
  fixtures = {
    kitty = home.xdg.configFile."kitty/kitty.conf".source;
    umbriel = home.xdg.configFile."umbriel/config.toml".source;
    vscode = vscodeThemeExtension;
  };
  nixdExpressions = [
    nixd.nixpkgs.expr
    nixd.options.home_manager.expr
  ];
}
