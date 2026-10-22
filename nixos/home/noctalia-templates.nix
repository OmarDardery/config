# Upstream templates; writable outputs stay separate from declarative app configs.
{
  inputs,
  pkgs,
  lib,
  config,
}:
let
  themeDir = "${config.xdg.stateHome}/noctalia/theme";
  community = inputs.noctalia-templates;
  builtin = "${inputs.noctalia}/assets/templates";
  render = input: output: {
    input_path = "${input}";
    output_path = output;
  };
  zenApply = pkgs.writeShellApplication {
    name = "noctalia-zen-apply";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnused
    ];
    text = ''
      exec bash ${../pkgs}/zen-apply.sh ${lib.escapeShellArg "${community}/zen-browser/apply.sh"} ${lib.escapeShellArg "${zenControls}"}
    '';
  };
  zenControls = ../assets/zen-window-controls.css;
  apps = import ../pkgs/noctalia-app-themes.nix {
    inherit pkgs lib;
    configHome = config.xdg.configHome;
    cacheHome = config.xdg.cacheHome;
    templates = community;
  };
in
{
  kitty = (render "${builtin}/kitty/kitty.conf" "${themeDir}/kitty.conf") // {
    post_hook = "pkill -USR1 -x kitty || true";
  };
  umbriel = render "${builtin}/umbriel/umbriel.toml" "${themeDir}/umbriel.toml";
  vscode = render "${community}/vscode/vscode.json" "${themeDir}/vscode.json";
  steam = render "${community}/steam/steam.css" "${themeDir}/steam.css";
  zen_chrome =
    (render "${community}/zen-browser/zen-userChrome.css" "${config.xdg.cacheHome}/noctalia/zen-browser/zen-userChrome.css")
    // {
      post_hook = "${zenApply}/bin/noctalia-zen-apply";
      hook_async = false;
    };
  zen_content =
    (render "${community}/zen-browser/zen-userContent.css" "${config.xdg.cacheHome}/noctalia/zen-browser/zen-userContent.css")
    // {
      post_hook = "${zenApply}/bin/noctalia-zen-apply";
      hook_async = false;
    };
  fzf = render "${community}/fzf/fzf.sh" "${themeDir}/fzf.sh";
  lazygit = render "${community}/lazygit/lazygit.yml" "${themeDir}/lazygit.yml";
  nvim = render "${community}/neovim/matugen-template.lua" "${themeDir}/nvim.lua";
  bat =
    (render "${community}/bat/bat.tmTheme" "${config.xdg.configHome}/bat/themes/noctalia.tmTheme")
    // {
      post_hook = "bat cache --build";
      hook_async = false;
    };
  btop =
    (render "${builtin}/btop/btop.theme" "${config.xdg.configHome}/btop/themes/noctalia.theme")
    // {
      post_hook = "pkill -USR2 -x btop || true";
    };
  opencode = render "${community}/opencode/opencode.json" "${config.xdg.configHome}/opencode/themes/noctalia.json";
  gimp = render "${community}/gimp/gimp.css" "${config.xdg.configHome}/GIMP/${lib.versions.majorMinor pkgs.gimp.version}/gimp.css";
  inkscape = render "${community}/inkscape/user.css" "${config.xdg.configHome}/inkscape/ui/user.css";
  fastfetch = render "${community}/fastfetch/fastfetch-colors.jsonc" "${config.xdg.configHome}/fastfetch/themes/noctalia.jsonc";
  libreoffice =
    (render "${community}/libreoffice/Theme_Colors.xcu" "${config.xdg.stateHome}/noctalia/libreoffice-theme-staging/Theme_Colors.xcu")
    // {
      post_hook = "${apps.libreoffice}/bin/noctalia-apply-libreoffice-theme";
      hook_async = false;
    };
  yazi = render "${community}/yazi/yazi.toml" "${config.xdg.configHome}/yazi/flavors/noctalia.yazi/flavor.toml";
  yazi_syntax = render "${community}/yazi/yazi.tmTheme" "${config.xdg.configHome}/yazi/flavors/noctalia.yazi/tmtheme.xml";
}
