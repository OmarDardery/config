{
  pkgs,
  inputs,
  isLaptop,
  ...
}:
{
  home.packages = with pkgs; [
    (if isLaptop then callPackage ../pkgs/blender-nvidia.nix { } else blender)
    freecad
    logisim-evolution
    winboat
    inputs.webos-dev-manager.packages.${pkgs.stdenv.hostPlatform.system}.webos-dev-manager
  ];
}
