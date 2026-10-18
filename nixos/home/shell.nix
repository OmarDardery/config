{
  config,
  lib,
  pkgs,
  isNixOS,
  ...
}:
let
  themeDir = "${config.xdg.stateHome}/noctalia/theme";
  fzfTheme = lib.optionalString isNixOS ''
    if [ -r ${lib.escapeShellArg "${themeDir}/fzf.sh"} ]; then
      . ${lib.escapeShellArg "${themeDir}/fzf.sh"}
    fi
  '';
in
{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  programs.bash.enable = !isNixOS;
  programs.bash.initExtra = lib.mkAfter fzfTheme;
  home.shellAliases = {
    lt = "eza --tree --level=2";
    edit = "sudo -e";
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true; # singular here; the NixOS option is plural
    syntaxHighlighting.enable = true;
    initContent = lib.mkAfter fzfTheme;

    history = {
      size = 10000;
      save = 10000;
      ignoreAllDups = true;
    };
  };

  programs.starship.enable = true;
  programs.yazi = {
    enable = true;
    theme.flavor = lib.mkIf isNixOS {
      dark = "noctalia";
      light = "noctalia";
    };
  };

  # These are declared as programs rather than packages so home-manager writes
  # the zsh integration itself — the zoxide hook, the fzf ctrl-r/ctrl-t
  # bindings — instead of us hand-writing rc lines that then drift.
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
  programs.bat = {
    enable = true;
    config.theme = lib.mkIf isNixOS "noctalia";
  };
  programs.eza = {
    enable = true;
    icons = "auto";
    extraOptions = [ "--group-directories-first" ];
  };
  programs.lazygit = {
    enable = true;
    # Resolve the overlay at launch, including when invoked by Neovim. Never
    # replace the user's config or require a theme before the first render.
    package =
      if !isNixOS then
        pkgs.lazygit
      else
        pkgs.symlinkJoin {
          name = "lazygit-noctalia";
          paths = [ pkgs.lazygit ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          inherit (pkgs.lazygit) meta;
          postBuild = ''
            wrapProgram "$out/bin/lazygit" --run ${lib.escapeShellArg ''
              theme=${lib.escapeShellArg "${themeDir}/lazygit.yml"}
              if [ -r "$theme" ]; then
                base=${lib.escapeShellArg "${config.xdg.configHome}/lazygit/config.yml"}
                configs="''${LG_CONFIG_FILE:-}"
                if [ -z "$configs" ] && [ -f "$base" ]; then
                  configs="$base"
                fi
                export LG_CONFIG_FILE="''${configs:+$configs,}$theme"
              fi
            ''}
          '';
        };
  };
  programs.btop = {
    enable = true;
    settings.color_theme = lib.mkIf isNixOS "noctalia";
  };

  # No shell integration to speak of, so plain packages.
  home.packages = with pkgs; [
    ripgrep
    fd
    tealdeer # `tldr`
  ];
}
