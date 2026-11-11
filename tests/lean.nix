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
assert builtins.elem "com.orcaslicer.OrcaSlicer" (map (p: p.appId) os.services.flatpak.packages);
assert builtins.elem "com.vysp3r.ProtonPlus" (map (p: p.appId) os.services.flatpak.packages);
assert !os.services.scx.enable;
assert os.services.displayManager.ly.enable;
assert !os.services.displayManager.ly.x11Support;
assert os.services.displayManager.ly.settings.animation == "matrix";
assert os.services.displayManager.defaultSession == "umbriel";
assert !os.services.greetd.enable;
assert os.security.pam.services.ly.enableGnomeKeyring;
assert !(flake.inputs ? noctalia-greeter);
assert flake.inputs ? nix-cachyos-kernel;
assert
  flake.lib.deployment.hardwareProfile != "asus-tuf-a14"
  || (
    os.hardware.bluetooth.enable
    && os.hardware.nvidia.prime.offload.enable
    && os.services.logind.settings.Login.HandleLidSwitch == "suspend"
    && os.services.logind.settings.Login.HandleLidSwitchDocked == "ignore"
    && flake.inputs.nixpkgs.lib.hasInfix "charge_control_end_threshold"
      os.services.udev.extraRules
  );
assert flake.inputs.nixpkgs.lib.hasPrefix "linux-cachyos" (flake.inputs.nixpkgs.lib.getName os.boot.kernelPackages.kernel);
assert os.programs.steam.enable;
assert os.services.tailscale.enable;
assert (os.services.restic.backups ? home) == (flake.lib.deployment.storageUUID != null);
assert (os.fileSystems ? "/mnt/storage") == (flake.lib.deployment.storageUUID != null);
assert os.virtualisation.docker.enable && !os.services.printing.enable;
assert !os.services.ipp-usb.enable && !os.hardware.sane.enable && !os.services.avahi.enable;
assert !(builtins.elem "nmap" (map flake.inputs.nixpkgs.lib.getName os.environment.systemPackages));
assert os.workstation.engineering.enable && os.workstation.diagnostics.enable;
assert os.programs.gamemode.enable;
assert
  flake.lib.deployment.hardwareProfile != "generic" || !os.hardware.nvidia.prime.offload.enable;
assert home.programs.umbriel.settings.layout.mode == "dwindle";
assert home.programs.umbriel.settings.layout.stacking.drop_zones;
assert home.programs.umbriel.settings.appearance.title_bar.mode == "on";
assert
  home.programs.umbriel.settings.keybinds."Mod+D".action
  == "workspace-set-layout toggle dwindle stacking";
assert !home.programs.noctalia.settings.shell.greeter_sync.auto_sync;
assert home.programs.vscodium.enable && home.programs.neovim.enable;
assert !home.programs.noctalia.systemd.enable;
assert home.programs.noctalia.settings.plugins.enabled == [ ];
assert !(home.home.file ? ".local/bin/desktop-apply");
assert !(home.home.activation ? mutableVSCodium);
assert !(home.home.activation ? mutableLazyVim);
assert !(home.home.activation ? kittyDeclarativeConfig);
assert !(flake.inputs ? millennium);
assert !(flake ? devShells) && !(flake ? templates);
assert !(os.security.wrappers ? dumpcap);
assert !(os.users.groups ? wireshark);
assert builtins.all (
  p:
  !(builtins.elem (flake.inputs.nixpkgs.lib.getName p) [
    "logisim-evolution"
    "wireshark"
    "wireshark-cli"
  ])
) os.environment.systemPackages;
assert home.home.shellAliases.up == "config-apply --update";
assert !(home.home.shellAliases ? update);
assert !(flake.packages.x86_64-linux ? update);
assert !(flake.apps.x86_64-linux ? update);
assert home.programs.zsh.enable && home.programs.direnv.enableZshIntegration;
assert flake.inputs.nixpkgs.lib.hasInfix "up-line-or-beginning-search" home.programs.zsh.initContent;
assert flake.inputs.nixpkgs.lib.hasInfix "fzf-tab.plugin.zsh" home.programs.zsh.initContent;
assert flake.inputs.nixpkgs.lib.hasInfix "magic-space" home.programs.zsh.initContent;
assert home.programs.zsh.autosuggestion.strategy == [ "history" "completion" ];
assert
  home.programs.kitty.settings.shell
  == "${os.users.users.${flake.lib.deployment.username}.shell}/bin/zsh -l";
assert
  home.programs.vscodium.profiles.default.userSettings."terminal.integrated.defaultProfile.linux"
  == "zsh";
assert home.programs.yazi.enableZshIntegration && home.programs.yazi.enableBashIntegration;

{
  system = os.system.build.toplevel.drvPath;
  home = home.home.activationPackage.drvPath;
}
