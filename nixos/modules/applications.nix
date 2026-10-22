{
  flake.modules.nixos.applications = {
    imports = [
      ../system/applications/apps.nix
      ../system/applications/tools.nix
      ../system/applications/files.nix
      ../system/applications/capture.nix
      ../system/applications/displays.nix
      ../system/applications/engineering.nix
      ../system/applications/gaming.nix
      ../system/applications/services.nix
    ];
  };
}
