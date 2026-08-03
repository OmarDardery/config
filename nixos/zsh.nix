{ pkgs, inputs, ... }:
{
  #zsh config
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      up = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      cnf = "sudo nano ~/configurations/nixos/configuration.nix";
      lc = "cd /mnt/storage/Coding";
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };
  programs.starship.enable = true;
  programs.atuin.enable = true;
  programs.atuin.settings.search_mode = "fuzzy";
}
