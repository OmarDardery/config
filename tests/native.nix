{ flake }:
let
  h = (builtins.head (builtins.attrValues flake.homeConfigurations)).config;
  ids = h.desktop.flatpak.packages;
in
assert !h.targets.genericLinux.gpu.enable;
assert !(h.home.activation ? setLoginShell);
assert !(h.home.activation ? setupHostGraphics);
assert h.home.pointerCursor.name == "Bibata-Modern-Classic";
assert h.xdg.configFile ? "ly/config.ini";
assert h.xdg.configFile ? "nvim/init.lua";
assert builtins.all (id: builtins.elem id ids) [ "app.zen_browser.zen" "org.libreoffice.LibreOffice" "com.github.xournalpp.xournalpp" ];
{ activation = h.home.activationPackage.drvPath; }
