# Noctalia: the bar, control center, lockscreen and wallpaper handling.
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;

    # A path rather than a Nix attrset, so the config stays real TOML sitting
    # next to the niri and kitty trees instead of being translated through Nix.
    # The module copies it to ~/.config/noctalia/config.toml.
    #
    # validateConfig defaults to true, so `noctalia config validate` runs over
    # this file on every rebuild. Know what that does and does not buy you,
    # measured against 5.0.0: broken TOML syntax exits 1 and fails the build,
    # while an unknown or misspelled key only prints a WARN and exits 0, so the
    # build still succeeds — read the build output, do not just trust the exit.
    # Wrong value types and unknown widget names in the bar lists are not
    # checked at all.
    settings = ../dotfiles/noctalia/config.toml;

    # systemd.enable is deliberately left off. niri already starts noctalia with
    # `spawn-at-startup "noctalia"` in dotfiles/niri/cfg/autostart.kdl, and
    # turning this on as well would run two instances of the shell.
  };

  # The package comes from the module: homeModules.default sets
  # programs.noctalia.package to noctalia's own build with mkDefault, which is
  # what keeps the cachix substituter hitting. That is why it is no longer
  # listed by hand in desktop.nix.

  # Inputs for the two user templates declared in config.toml. Read-only is
  # correct here — noctalia only ever reads these and renders them somewhere
  # writable. They are copies of noctalia's own builtin niri/kitty templates,
  # which could not be used directly because those hardcode an output path
  # inside the read-only trees deployed by desktop.nix.
  xdg.configFile."noctalia/templates".source = ../dotfiles/noctalia/templates;

  # The wallpapers config.toml points at. This is not decoration: theme.source
  # is "wallpaper", so the entire palette is generated from whichever of these
  # is selected. Without them deployed, a fresh machine gets no wallpaper and a
  # fallback palette instead of yours.
  #
  # config.toml refers to them by their ~/Pictures path rather than a store
  # path, because it is real TOML and cannot interpolate one. That also keeps
  # switching wallpapers from the noctalia UI working.
  #
  # Read-only, like the niri and kitty trees, so adding a wallpaper means
  # dropping it in dotfiles/Pictures/Wallpapers and rebuilding.
  home.file."Pictures/Wallpapers".source = ../dotfiles/Pictures/Wallpapers;
}
