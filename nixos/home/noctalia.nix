# Noctalia owns runtime state, wallpaper colors and template rendering.
{ inputs, config, ... }:
{
  programs.noctalia = {
    enable = true;
    package = null;
    systemd.enable = false;
    checkConfig = false; # CI validates using the pinned Noctalia executable.
    settings = (import ./noctalia-settings.nix) // {
      theme = {
        source = "wallpaper";
        templates = {
          builtin_ids = [
            "gtk3"
            "gtk4"
            "kcolorscheme"
          ];
          community_ids = [ ];
          user = {
            kitty = {
              input_path = "${inputs.noctalia}/assets/templates/kitty/kitty.conf";
              output_path = "${config.xdg.stateHome}/noctalia/theme/kitty.conf";
              post_hook = "pkill -USR1 -x kitty || true";
            };
            umbriel = {
              input_path = "${inputs.noctalia}/assets/templates/umbriel/umbriel.toml";
              output_path = "${config.xdg.stateHome}/noctalia/theme/umbriel.toml";
            };
            # Luciole reads its palette from colors.toml beside its settings
            # and applies changes live.
            luciole = {
              input_path = "${../assets/templates/luciole/colors.toml}";
              output_path = "${config.xdg.configHome}/luciole/colors.toml";
            };
          };
        };
      };
    };
  };
  xdg.dataFile."noctalia/wallpaper-samples".source = ../assets/wallpapers;
}
