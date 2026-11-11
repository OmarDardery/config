{ flake }:
let
  h = (builtins.head (builtins.attrValues flake.homeConfigurations)).config;
  ids = h.desktop.flatpak.packages;
  pkgs = (builtins.head (builtins.attrValues flake.homeConfigurations)).pkgs;
in
assert !h.targets.genericLinux.gpu.enable;
assert !(h.home.activation ? setLoginShell);
assert !(h.home.activation ? setupHostGraphics);
assert h.home.pointerCursor.name == "Bibata-Modern-Classic";
assert !(h.xdg.configFile ? "ly/config.ini");
assert h.xdg.configFile ? "noctalia-greeter/greeter.toml";
assert (builtins.fromTOML (builtins.readFile h.xdg.configFile."noctalia-greeter/greeter.toml".source)).session.default == "umbriel";
assert h.xdg.configFile ? "nvim/init.lua";
assert h.xdg.configFile ? "kitty/kitty.conf";
assert h.xdg.configFile ? "starship.toml";
assert h.xdg.configFile ? "zsh/common.zsh";
assert h.xdg.configFile ? "VSCodium/User/settings.json";
assert !(builtins.elem pkgs.zsh h.home.packages);
assert !(builtins.elem pkgs.starship h.home.packages);
assert !(builtins.elem pkgs.kitty h.home.packages);
assert !(builtins.elem pkgs.gitMinimal h.home.packages);
assert !h.programs.neovim.enable && !h.programs.vscodium.enable;
assert builtins.all (id: builtins.elem id ids) [ "app.zen_browser.zen" "org.libreoffice.LibreOffice" "com.github.xournalpp.xournalpp" ];
{ activation = h.home.activationPackage.drvPath; }
