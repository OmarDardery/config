{
  profile,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./editors
    ./desktop.nix
    ./terminal.nix
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
    };
  };
  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
  # Follow the distro's session; switching a home generation must not restart apps.
  systemd.user.startServices = false;
  programs.man.enable = false;
  manual.manpages.enable = false;
  home.packages =
    (with pkgs; [
      gitMinimal
      ripgrep
      fd
    ])
    ++ [
      (pkgs.writeShellScriptBin "config-apply" ''
        exec nix --extra-experimental-features 'nix-command flakes' run \
          --no-write-lock-file ${lib.escapeShellArg "path:${profile.configRepo}/non-nixos"} \
          -- --repo-dir ${lib.escapeShellArg profile.configRepo} "$@"
      '')
    ];
}
