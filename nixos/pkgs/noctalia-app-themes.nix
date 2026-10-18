{
  pkgs,
  lib,
  config,
  templates,
}:
let
  cache = config.xdg.cacheHome;
in
{
  libreoffice = pkgs.writeShellApplication {
    name = "noctalia-apply-libreoffice-theme";
    runtimeInputs = with pkgs; [
      coreutils
      bash
      procps
      python3
      zip
      libreoffice
      util-linux
    ];
    text = ''
      work=${lib.escapeShellArg "${cache}/noctalia/libreoffice-template"}
      mkdir -p "$work"
      exec 9>"$work/.lock"
      flock 9
      for file in apply.sh Paths.xcu description.xml pkg-description.en; do
        cp -f -- "${templates}/libreoffice/$file" "$work/$file"
      done
      exec bash "$work/apply.sh"
    '';
  };
  blender = pkgs.writeShellApplication {
    name = "noctalia-apply-blender-theme";
    runtimeInputs = with pkgs; [
      procps
      blender
    ];
    text = ''
      if pgrep -x blender >/dev/null; then
        printf '%s\n' 'Close Blender, then run noctalia-apply-blender-theme to apply the latest palette.'
        exit 0
      fi
      script=${lib.escapeShellArg "${cache}/noctalia/blender_theme_rendered.py"}
      if [[ ! -r "$script" ]]; then
        printf '%s\n' 'Render the Noctalia palette before applying the Blender theme.' >&2
        exit 1
      fi
      exec blender --background --python "$script"
    '';
  };
  fastfetch = pkgs.symlinkJoin {
    name = "fastfetch-noctalia";
    paths = [ pkgs.fastfetch ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/fastfetch" \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.jq
          ]
        } \
        --run ${lib.escapeShellArg ''
          exec ${pkgs.bash}/bin/bash ${./noctalia-fastfetch.sh} \
            ${pkgs.fastfetch}/bin/fastfetch ${templates}/fastfetch/apply.sh \
            ${lib.escapeShellArg "${config.xdg.configHome}"} "$@"
        ''}
    '';
  };
}
