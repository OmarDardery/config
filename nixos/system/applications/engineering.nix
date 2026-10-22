{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    freecad
    logisim-evolution
    winboat
    inputs.webos-dev-manager.packages.${pkgs.stdenv.hostPlatform.system}.webos-dev-manager
  ];
}
