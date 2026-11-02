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
assert os.programs.steam.enable && os.hardware.nvidia.prime.offload.enableOffloadCmd;
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
assert home.programs.zsh.enable && home.programs.direnv.enableZshIntegration;
assert home.programs.yazi.enableZshIntegration && home.programs.yazi.enableBashIntegration;

{
  system = os.system.build.toplevel.drvPath;
  home = home.home.activationPackage.drvPath;
}
