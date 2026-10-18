{
  pkgs,
  isNixOS,
  ...
}:
let
  converter = pkgs.writeShellApplication {
    name = "office-convert";
    runtimeInputs = [ pkgs.python3 ] ++ pkgs.lib.optional isNixOS pkgs.libreoffice;
    text = ''
      exec python3 ${../pkgs/office-convert.py} "$@"
    '';
  };
in
{
  home.packages = [ converter ];
  home.shellAliases = {
    office2pdf = "office-convert pdf";
    ppt2pdf = "office-convert pdf";
    ppt2txt = "office-convert slides-text";
    ppt2pptx = "office-convert pptx";
    doc2pdf = "office-convert pdf";
    doc2txt = "office-convert txt";
    doc2docx = "office-convert docx";
    xls2pdf = "office-convert pdf";
    xls2csv = "office-convert csv";
    xls2xlsx = "office-convert xlsx";
  };
}
