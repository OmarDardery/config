{
  profile,
  config,
  pkgs,
  lib,
  ...
}:
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
    fzf
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
    settings = {
      shell = "${lib.getExe pkgs.zsh} -l";
      env = "ZDOTDIR=${profile.zshHome}";
    };
    extraConfig = builtins.readFile ../dotfiles/kitty/kitty.conf;
  };
  home.sessionVariables = {
    TERMINAL = "kitty";
    SHELL = "${config.home.profileDirectory}/bin/zsh";
    ZDOTDIR = profile.zshHome;
  };
  home.activation.setLoginShell = lib.hm.dag.entryAfter [ "installPackages" "linkGeneration" ] ''
    run ${pkgs.coreutils}/bin/env PATH=${
      lib.makeBinPath [ pkgs.coreutils ]
    }:/usr/bin:/bin:/usr/sbin:/sbin \
      ${pkgs.bash}/bin/bash ${../login-shell.sh} \
      ${lib.escapeShellArg profile.username} \
      ${lib.escapeShellArg "${config.home.profileDirectory}/bin/zsh"}
  '';
  xdg.configFile = {
    "starship.toml".source = ../dotfiles/starship.toml;
  };
  home.file.".zshenv".text = ''
    export ZDOTDIR=${lib.escapeShellArg profile.zshHome}
  '';
  home.file.".zshrc" = {
    target = "${profile.zshHome}/.zshrc";
    text = builtins.readFile ../dotfiles/zsh/.zshrc + ''
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    '';
  };
}
