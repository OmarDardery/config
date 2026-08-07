{pkgs, inputs, ...}:
{
  environment.systemPackages = with pkgs; [
    libreoffice-qt
    hunspell
    rnote
  ];
}
