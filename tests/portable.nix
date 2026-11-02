{ flake }:
let
  inherit (flake.lib.deployment) username hostName system;
  lib = flake.inputs.nixpkgs.lib;
  home = flake.homeConfigurations.${username}.config;
  core = flake.homeConfigurations."${username}-core".config;
  dev = flake.homeConfigurations."${username}-dev".config;
  gaming = flake.homeConfigurations."${username}-gaming".config;
  desktop = flake.homeConfigurations."${username}-desktop".config;
  os = flake.nixosConfigurations.${hostName}.config;
  osHome = os.home-manager.users.${username};
  names = map lib.getName home.home.packages;
  has = name: builtins.elem name names;
in
assert home.programs.neovim.enable && osHome.programs.neovim.enable;
assert has "vscodium" && has "steam" && has "flatpak";
assert home.programs.direnv.enable && home.programs.direnv.nix-direnv.enable;
assert osHome.programs.direnv.enable && osHome.programs.direnv.nix-direnv.enable;
assert home.services.flatpak.enable;
assert builtins.any (p: p.appId == "com.valvesoftware.Steam") home.services.flatpak.packages;
assert !(osHome.services.flatpak.enable or false);
assert
  !os.workstation.gaming.enable || builtins.elem os.programs.steam.package osHome.home.packages;
assert builtins.all (name: !has name) [
  "go"
  "rustc"
  "cargo"
  "nodejs"
  "uv"
];
assert
  builtins.attrNames flake.devShells.${system} == [
    "cpp"
    "default"
    "go"
    "node"
    "python"
    "rust"
  ];
assert !home.programs.neovim.withPython3 && !home.programs.neovim.withNodeJs;
assert !core.programs.neovim.enable && !gaming.programs.neovim.enable;
assert !(core.services.flatpak.enable or false) && !(dev.services.flatpak.enable or false);
assert gaming.services.flatpak.enable && desktop.services.flatpak.enable;
assert !(home.programs.noctalia.enable or false) && desktop.programs.noctalia.enable;
assert !(core.programs.umbriel.enable or false) && desktop.programs.umbriel.enable;
assert !(core.xdg.configFile ? "gtk-3.0/gtk.css");
assert !(core.home.file ? ".local/bin/office-convert");
assert !lib.hasInfix "flake check" core.home.shellAliases.neval;
assert home.targets.genericLinux.nixGL.defaultWrapper == "mesa";
assert home.targets.genericLinux.nixGL.packages != null;
assert osHome.targets.genericLinux.nixGL.packages == null;
assert
  builtins.attrNames flake.templates == [
    "cpp"
    "go"
    "nix"
    "node"
    "python"
    "rust"
  ];
{
  editors = true;
  steam = true;
  direnv = true;
  optionalProfiles = true;
  graphicsWrapper = true;
  templates = true;
  toolchainsAreOnDemand = true;
}
