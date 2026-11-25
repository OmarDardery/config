# Regression checks for the failed desktop activation and retired wrappers.
{ flake }:
let
  os = flake.nixosConfigurations.${flake.lib.deployment.hostName}.config;
  home = os.home-manager.users.${flake.lib.deployment.username};
in
assert !(os.systemd.user.services ? desktop-config);
assert !(os.systemd.user.services ? flatpak-font-cache);
assert os.systemd.services ? flatpak-managed-install;
assert os.services.flatpak.enable;
assert !os.services.flatpak.uninstallUnmanaged;
assert builtins.all (id: builtins.elem id (map (p: p.appId) os.services.flatpak.packages)) [
  "com.epicgames.launcher"
  "com.discordapp.Discord"
];
assert !(builtins.elem "discord" (map flake.inputs.nixpkgs.lib.getName os.environment.systemPackages));
assert !os.services.scx.enable;
assert os.services.displayManager.noctalia-greeter.enable;
assert os.services.displayManager.noctalia-greeter.settings.session.default == "umbriel";
assert os.services.displayManager.noctalia-greeter.settings.user.default == flake.lib.deployment.username;
assert os.services.displayManager.noctalia-greeter.settings.appearance.wallpaper.blur == 0.75;
assert os.services.displayManager.noctalia-greeter.settings.appearance.wallpaper.tint == 0.15;
assert os.services.displayManager.noctalia-greeter.settings.appearance.wallpaper.fill_color == "#11151e";
assert !(os.services.displayManager.noctalia-greeter.settings.appearance ? scheme);
assert !(os.services.displayManager.noctalia-greeter.settings.appearance ? palette);
assert !(os.services.displayManager.noctalia-greeter.settings.appearance.wallpaper ? path);
assert os.services.displayManager.defaultSession == "umbriel";
assert os.services.greetd.enable;
assert os.services.accounts-daemon.enable;
assert os.security.pam.services.greetd.enableGnomeKeyring;
assert os.services.displayManager.noctalia-greeter.passwordless-sync-users == [ flake.lib.deployment.username ];
assert flake.inputs ? noctalia-greeter;
assert flake.inputs ? nix-cachyos-kernel;
assert flake.inputs.nixpkgs.lib.hasPrefix "linux-cachyos" (flake.inputs.nixpkgs.lib.getName os.boot.kernelPackages.kernel);
assert os.programs.steam.enable;
assert os.services.tailscale.enable;
assert (os.services.restic.backups ? home) == (flake.lib.deployment.storageUUID != null);
assert (os.fileSystems ? "/mnt/storage") == (flake.lib.deployment.storageUUID != null);
assert os.virtualisation.docker.enable && !os.services.printing.enable;
assert !os.services.ipp-usb.enable && !os.hardware.sane.enable && !os.services.avahi.enable;
assert !(builtins.elem "nmap" (map flake.inputs.nixpkgs.lib.getName os.environment.systemPackages));
assert !(builtins.elem "winboat" (map flake.inputs.nixpkgs.lib.getName os.environment.systemPackages));
assert builtins.any (
  p:
  flake.inputs.nixpkgs.lib.getName p == "winboat"
  && flake.inputs.nixpkgs.lib.getVersion p == "0.9.2"
) home.home.packages;
assert os.workstation.engineering.enable && os.workstation.diagnostics.enable;
assert os.programs.gamemode.enable;
assert
  flake.lib.deployment.hardwareProfile != "generic" || !os.hardware.nvidia.prime.offload.enable;
assert home.programs.umbriel.settings.layout.mode == "stacking";
assert
  flake.lib.deployment.hardwareProfile != "asus-tuf-a14"
  || (os.hardware.nvidia.powerManagement.finegrained && os.systemd.user.services ? power-policy);
assert home.programs.umbriel.settings.input.focus.follows_mouse == "sloppy";
assert home.programs.umbriel.settings.keybinds."Ctrl+Alt+Delete".action == "spawn noctalia msg panel-toggle session";
assert os.programs.luciole.enable && os.programs.kdeconnect.enable;
assert os.services.gvfs.enable && os.services.udisks2.enable;
assert os.services.pipewire.enable && os.services.gnome.gnome-keyring.enable;
assert home.programs.umbriel.settings.layout.stacking.drop_zones;
assert home.programs.umbriel.settings.keybinds.Print.action == "spawn screenshot-desktop region";
assert home.programs.umbriel.settings.keybinds."Shift+Print".action == "spawn screenshot-desktop fullscreen";
assert home.programs.umbriel.settings.appearance.title_bar.mode == "on";
assert home.programs.umbriel.settings.appearance.title_bar.button_position == "left";
assert home.programs.umbriel.settings.hot_corners.top_left.action == "overview-toggle";
assert
  home.programs.umbriel.settings.keybinds."Mod+D".action
  == "workspace-set-layout toggle stacking scrolling";
assert home.programs.noctalia.settings.shell.greeter_sync.auto_sync;
assert home.programs.zed-editor.enable && home.programs.neovim.enable;
assert !home.programs.vscodium.enable;
assert !home.programs.noctalia.systemd.enable;
assert home.programs.noctalia.settings.plugins.enabled == [ ];
assert home.programs.noctalia.settings.dock.enabled && home.programs.noctalia.settings.dock.magnification;
assert home.programs.noctalia.settings.bar.default.position == "top";
assert
  home.programs.noctalia.settings.theme.templates.user.luciole.output_path
  == "${home.xdg.configHome}/luciole/colors.toml";
assert !(home.programs.noctalia.settings.widget ? smart_taskbar);
assert !(home.home.file ? ".local/bin/desktop-apply");
assert !(home.home.activation ? mutableVSCodium);
assert !(home.home.activation ? mutableLazyVim);
assert !(home.home.activation ? kittyDeclarativeConfig);
assert !(flake.inputs ? millennium);
assert !(flake ? devShells) && !(flake ? templates);
assert os.security.wrappers.dumpcap.group == "wireshark";
assert os.security.wrappers.dumpcap.capabilities == "cap_net_raw,cap_net_admin+eip";
assert !os.programs.wireshark.usbmon.enable;
assert os.programs.wireshark.package.pname == "wireshark-qt";
assert builtins.elem "wireshark" os.users.users.${flake.lib.deployment.username}.extraGroups;
assert builtins.all (
  p: flake.inputs.nixpkgs.lib.getName p != "logisim-evolution"
) os.environment.systemPackages;
assert home.home.shellAliases.up == "config-apply --update";
assert !(home.home.shellAliases ? update);
assert !(flake.packages.x86_64-linux ? update);
assert !(flake.apps.x86_64-linux ? update);
assert home.programs.zsh.enable && home.programs.direnv.enableZshIntegration;
assert flake.inputs.nixpkgs.lib.hasInfix "up-line-or-beginning-search" home.programs.zsh.initContent;
assert flake.inputs.nixpkgs.lib.hasInfix "fzf-tab.plugin.zsh" home.programs.zsh.initContent;
assert flake.inputs.nixpkgs.lib.hasInfix "magic-space" home.programs.zsh.initContent;
assert flake.inputs.nixpkgs.lib.hasInfix "HIST_IGNORE_SPACE" home.programs.zsh.initContent;
assert flake.inputs.nixpkgs.lib.hasInfix "alias failed=" home.programs.zsh.initContent;
assert home.programs.zsh.autosuggestion.strategy == [ "history" "completion" ];
assert
  home.programs.kitty.settings.shell
  == "${os.users.users.${flake.lib.deployment.username}.shell}/bin/zsh -l";
assert
  home.programs.zed-editor.userSettings.terminal.shell.with_arguments.program
  == "${os.users.users.${flake.lib.deployment.username}.shell}/bin/zsh";

{
  system = os.system.build.toplevel.drvPath;
  home = home.home.activationPackage.drvPath;
}
