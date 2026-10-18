{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    freecad
    logisim-evolution
    winboat
    inputs.webos-dev-manager.packages.${pkgs.stdenv.hostPlatform.system}.webos-dev-manager
  ];
}
