{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true; # singular here; the NixOS option is plural
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreAllDups = true;
    };
  };

  programs.starship.enable = true;
  programs.yazi.enable = true;

  # These are declared as programs rather than packages so home-manager writes
  # the zsh integration itself — the zoxide hook, the fzf ctrl-r/ctrl-t
  # bindings — instead of us hand-writing rc lines that then drift.
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.lazygit.enable = true;

  # No shell integration to speak of, so plain packages.
  home.packages = with pkgs; [
    ripgrep
    fd
    btop
    tealdeer # `tldr`
  ];
}
