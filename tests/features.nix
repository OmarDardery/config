# Optional bundles must remove their services, permissions and packages together.
{ flake }:
let
  lib = flake.inputs.nixpkgs.lib;
  base = flake.nixosConfigurations.${flake.lib.deployment.hostName};
  os =
    (base.extendModules {
      modules = [
        {
          workstation =
            lib.genAttrs
              [
                "gaming"
                "engineering"
                "containers"
                "printing"
                "diagnostics"
                "tailscale"
                "backups"
              ]
              (_: {
                enable = false;
              });
        }
      ];
    }).config;
  names = map lib.getName os.environment.systemPackages;
  groups = os.users.users.${flake.lib.deployment.username}.extraGroups;
in
assert !os.programs.steam.enable && !os.programs.gamemode.enable;
assert !os.virtualisation.docker.enable;
assert !os.services.printing.enable && !os.services.ipp-usb.enable;
assert !os.services.avahi.enable && !os.hardware.sane.enable;
assert !os.services.tailscale.enable && !os.programs.mtr.enable;
assert !(os.services.restic.backups ? home);
assert !(os.systemd.services ? restic-home-password);
assert !(os.systemd.services ? tailscaled);
assert !(os.networking.firewall.interfaces ? tailscale0);
assert os.services.flatpak.packages == [ "com.epicgames.launcher" ];
assert !os.services.desktopManager.plasma6.enable;
assert !os.services.xserver.enable && !os.programs.xwayland.enable;
assert os.programs.thunar.enable;
assert builtins.all (name: !(builtins.elem name names)) [
  "freecad"
  "platformio-core"
  "simple-scan"
  "lshw"
  "nmap"
  "nvme-cli"
];
assert builtins.all (name: !(builtins.elem name groups)) [
  "docker"
  "gamemode"
  "scanner"
  "lp"
];
{
  system = os.system.build.toplevel.drvPath;
}
