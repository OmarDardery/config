# Validate the complete desktop and the explicit no-Flatpak recovery mode.
{ flake }:
let
  configuration = builtins.head (builtins.attrValues flake.homeConfigurations);
  home = configuration.config;
  inherit (configuration) pkgs;
  lib = flake.inputs.nixpkgs.lib;
  withoutFlatpaks =
    (configuration.extendModules {
      modules = [ { desktop.flatpak.enable = false; } ];
    }).config;
  required = with pkgs; [
    gitMinimal
    ripgrep
    fd
    nixd
    nixfmt
    kitty
    zsh
    starship
    xournalpp
    libreoffice
    thunar
    file-roller
    keepassxc
    mpv
    imv
    gimp
  ];
  ids = home.desktop.flatpak.packages;
in
assert home.targets.genericLinux.enable;
assert home.programs.home-manager.enable;
assert home.programs.neovim.enable && home.programs.vscodium.enable;
assert !home.programs.neovim.withPython3 && !home.programs.neovim.withNodeJs;
assert builtins.all (package: builtins.elem package home.home.packages) required;
assert home.fonts.fontconfig.enable;
assert !(home.home.sessionVariables ? BROWSER);
assert !(home.xdg.mimeApps.defaultApplications ? "text/html");
assert home.xdg.configFile ? "nvim/init.lua";
assert home.xdg.configFile ? "umbriel/config.toml";
assert home.home.file ? ".zshrc";
assert home.systemd.user.services == { };
assert home.desktop.flatpak.enable && home.home.activation ? desktopFlatpaks;
assert !(withoutFlatpaks.home.activation ? desktopFlatpaks);
assert lib.hasInfix (
  "XDG_DATA_HOME=" + lib.escapeShellArg home.xdg.dataHome
) home.home.activation.desktopFlatpaks.data;
assert lib.hasInfix (
  "XDG_STATE_HOME=" + lib.escapeShellArg home.xdg.stateHome
) home.home.activation.desktopFlatpaks.data;
assert builtins.length ids == builtins.length (lib.unique ids);
assert
  if pkgs.stdenv.hostPlatform.isx86_64 then
    builtins.all (id: builtins.elem id ids) [
      "com.valvesoftware.Steam"
      "com.vysp3r.ProtonPlus"
      "com.orcaslicer.OrcaSlicer"
      "com.discordapp.Discord"
    ]
  else
    ids == [ ];
{
  activation = home.home.activationPackage.drvPath;
  flatpakInstaller = home.desktop.flatpak.installer.drvPath;
}
