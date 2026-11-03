# Regression checks for the failed desktop activation and retired wrappers.
{ flake }:
let
  os = flake.nixosConfigurations.nixos.config;
  home = os.home-manager.users.${flake.lib.deployment.username};
in
assert !(os.systemd.user.services ? desktop-config);
assert !(os.systemd.user.services ? flatpak-font-cache);
assert !(os.systemd.services ? flatpak-managed-install);
assert !os.services.scx.enable;
assert os.programs.steam.enable;
assert !os.services.tailscale.enable;
assert !(os.services.restic.backups ? home);
assert !(os.fileSystems ? "/mnt/storage");
assert !os.virtualisation.docker.enable && !os.services.printing.enable;
assert
  flake.lib.deployment.hardwareProfile != "generic" || !os.hardware.nvidia.prime.offload.enable;
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
assert home.programs.yazi.enableZshIntegration && home.programs.yazi.enableBashIntegration;

{
  system = os.system.build.toplevel.drvPath;
  home = home.home.activationPackage.drvPath;
}
