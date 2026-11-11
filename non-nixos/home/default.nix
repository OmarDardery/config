{
  profile,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./flatpak.nix
  ];
  home = {
    inherit (profile) username homeDirectory stateVersion;
    sessionPath = [ "${profile.homeDirectory}/.local/bin" ];
  };
  xdg = {
    enable = true;
    inherit (profile) configHome stateHome dataHome;
    configFile = {
      "umbriel/config.toml".source = ../dotfiles/umbriel/config.toml;
      "noctalia/config.toml".source = ../dotfiles/noctalia/config.toml;
      "kitty/kitty.conf".source = ../dotfiles/kitty/kitty.conf;
      "zsh/common.zsh".source = ../dotfiles/zsh/common.zsh;
      "starship.toml".source = ../dotfiles/starship.toml;
      "nvim/init.lua".source = ../dotfiles/nvim/init.lua;
      "nvim/lua/config/options.lua".source = ../dotfiles/nvim/lua/config/options.lua;
      "nvim/lua/plugins/tools.lua".source = ../dotfiles/nvim/lua/plugins/tools.lua;
      "VSCodium/User/settings.json".source = ../dotfiles/VSCodium/User/settings.json;
      "noctalia-greeter/greeter.toml".source = ../dotfiles/noctalia-greeter/greeter.toml;
    };
  };
  home.file.".zshenv".text = "export ZDOTDIR=${lib.escapeShellArg profile.zshHome}\n";
  home.file.".zshrc" = {
    target = "${profile.zshHome}/.zshrc";
    source = ../dotfiles/zsh/.zshrc;
  };
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  targets.genericLinux.enable = true;
  targets.genericLinux.gpu.enable = false;
  programs.home-manager.enable = true;
  # Follow the distro's session; switching a home generation must not restart apps.
  systemd.user.startServices = false;
  programs.man.enable = false;
  manual.manpages.enable = false;
  home.packages = [
    (pkgs.writeShellScriptBin "config-apply" ''
      exec nix --extra-experimental-features 'nix-command flakes' run \
        --no-write-lock-file ${lib.escapeShellArg "path:${profile.configRepo}/non-nixos"} \
        -- --repo-dir ${lib.escapeShellArg profile.configRepo} "$@"
    '')
  ];
}
