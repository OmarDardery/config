{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    (inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.pixie-sddm.override {
      background = ./modules/Pictures/Wallpapers/dark-mountain.jpg;
      avatar = ./Pictures/face.jpg;
      accentColor = "#3F5F91";
      autoColor = true;
      backgroundColor = "#1A1C1E";
      textColor = "#E2E2E6";
      fontFamily = "JetBrains Mono";
    })
  ];
}
