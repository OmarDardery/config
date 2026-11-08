{ profile, config, pkgs, lib, ... }:
let
  shared = import ../packages.nix { inherit pkgs; };
  # Fedora's newer XML rules cannot be parsed by the pinned Fontconfig.
  baseFontsConf = pkgs.makeFontsConf {
    fontDirectories = shared.fonts;
    includes = [ ];
  };
  fontsConf = pkgs.writeText "kitty-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include>${baseFontsConf}</include>
      <include ignore_missing="yes">${lib.escapeXML config.xdg.configHome}/fontconfig/conf.d</include>
    </fontconfig>
  '';
in
{
  home.packages = with pkgs; [
    starship
    zsh
    zoxide
    direnv
  ];
  programs.kitty = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "kitty-desktop";
      paths = [ pkgs.kitty ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/kitty" --set FONTCONFIG_FILE ${fontsConf}
        for desktop in "$out/share/applications/"*.desktop; do
          target=$(readlink -f "$desktop")
          rm "$desktop"
          cp "$target" "$desktop"
          substituteInPlace "$desktop" \
            --replace-quiet "${pkgs.kitty}/bin/kitty" "$out/bin/kitty" \
            --replace-quiet "Exec=kitty" "Exec=$out/bin/kitty"
        done
      '';
      meta.mainProgram = "kitty";
    };
    extraConfig = builtins.readFile ../dotfiles/kitty/kitty.conf;
  };
  home.sessionVariables.TERMINAL = "kitty";
  xdg.configFile = {
    "starship.toml".source = ../dotfiles/starship.toml;
  };
  home.file.".zshrc" = {
    target = "${profile.zshHome}/.zshrc";
    source = ../dotfiles/zsh/.zshrc;
  };
}
