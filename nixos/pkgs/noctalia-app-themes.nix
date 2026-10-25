{
  pkgs,
  lib,
  cacheHome,
  templates,
}:
{
  libreoffice = pkgs.writeShellApplication {
    name = "noctalia-apply-libreoffice-theme";
    runtimeInputs = with pkgs; [
      coreutils
      bash
      procps
      python3
      zip
      util-linux
    ];
    text = ''
      work=${lib.escapeShellArg "${cacheHome}/noctalia/libreoffice-template"}
      mkdir -p "$work"
      exec 9>"$work/.lock"
      flock 9
      for file in apply.sh Paths.xcu description.xml pkg-description.en; do
        cp -f -- "${templates}/libreoffice/$file" "$work/$file"
      done
      exec bash "$work/apply.sh"
    '';
  };
}
