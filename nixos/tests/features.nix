# Exercise default exclusions and the complete opt-in system, not just flags.
{ flake }:
let
  inherit (flake.inputs.nixpkgs) lib;
  base = flake.nixosConfigurations.${flake.lib.deployment.hostName};
  minimal = base.extendModules {
    modules = [ {
      workstation.gaming.enable = lib.mkForce false;
      workstation.engineering.enable = lib.mkForce false;
      workstation.containers.enable = lib.mkForce false;
      workstation.printing.enable = lib.mkForce false;
    } ];
  };
  full = base.extendModules {
    modules = [ {
      workstation.gaming.enable = lib.mkForce true;
      workstation.engineering.enable = lib.mkForce true;
      workstation.containers.enable = lib.mkForce true;
      workstation.printing.enable = lib.mkForce true;
    } ];
  };
  lean = minimal.config;
  enabled = full.config;
  names = c: map lib.getName c.environment.systemPackages;
  checks = {
    leanServices = !lean.programs.steam.enable
      && !lean.programs.gamemode.enable
      && !lean.virtualisation.docker.enable
      && !lean.services.printing.enable && !lean.hardware.sane.enable;
    leanPackages = builtins.all (name: !(builtins.elem name (names lean))) [
      "freecad" "logisim-evolution" "winboat" "platformio" "simple-scan"
      "go" "rustc" "cargo" "cmake" "nodejs" "jetbrains-toolbox"
    ];
    noInsecureRuntime = (lean.nixpkgs.config.permittedInsecurePackages or [ ]) == [ ];
    leanFlatpaks = lean.services.flatpak.packages == [ ];
    completeSystem = builtins.all (a: a.assertion) enabled.assertions;
    enabledServices = enabled.programs.steam.enable && enabled.programs.gamemode.enable
      && enabled.virtualisation.docker.enable && !enabled.virtualisation.docker.enableOnBoot
      && enabled.services.printing.enable && enabled.hardware.sane.enable;
    enabledPackages = builtins.all (name: builtins.elem name (names enabled)) [
      "freecad" "logisim-evolution" "winboat" "platformio" "simple-scan"
    ];
    containerPermission = builtins.elem "docker"
      enabled.users.users.${flake.lib.deployment.username}.extraGroups
      && !(builtins.elem "docker" lean.users.users.${flake.lib.deployment.username}.extraGroups);
    scopedElectron = builtins.elem "electron-40.10.5" enabled.nixpkgs.config.permittedInsecurePackages;
    enabledFlatpaks = map (p: p.appId) enabled.services.flatpak.packages == [
      "com.orcaslicer.OrcaSlicer" "com.vysp3r.ProtonPlus"
    ];
  };
  failed = builtins.attrNames (lib.filterAttrs (_: passed: !passed) checks);
in
assert lib.assertMsg (failed == [ ]) "Feature checks failed: ${builtins.concatStringsSep ", " failed}";
checks
