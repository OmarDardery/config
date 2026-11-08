{ pkgs, inputs, ... }:
{
  home.packages = [
    (pkgs.callPackage ../pkgs/zen-browser.nix { zenInput = inputs.zen-browser; })
  ];
  home.sessionVariables.BROWSER = "zen";
  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "zen.desktop" ];
    "application/xhtml+xml" = [ "zen.desktop" ];
    "x-scheme-handler/http" = [ "zen.desktop" ];
    "x-scheme-handler/https" = [ "zen.desktop" ];
  };
}
