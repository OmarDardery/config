# Standalone scope: install the editors and helpers, keep desktop apps native.
{ flake }:
let
  home = flake.homeConfigurations.oad.config;
  names = map flake.inputs.nixpkgs.lib.getName home.home.packages;
in
assert home.targets.genericLinux.enable;
assert home.programs.home-manager.enable;
assert home.programs.neovim.enable && home.programs.vscodium.enable;
assert !home.programs.neovim.withPython3 && !home.programs.neovim.withNodeJs;
assert !home.programs.zsh.enable && !home.programs.kitty.enable;
assert home.xdg.configFile ? "nvim/init.lua";
assert home.xdg.configFile ? "umbriel/config.toml";
assert home.xdg.configFile ? "noctalia/config.toml";
assert home.home.file ? ".zshrc";
assert home.systemd.user.services == { };
assert builtins.all (name: builtins.elem name names) [
  "git-minimal"
  "ripgrep"
  "fd"
  "nixd"
  "nixfmt"
];
{
  activation = home.home.activationPackage.drvPath;
}
