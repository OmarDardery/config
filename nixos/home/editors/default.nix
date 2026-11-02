{ ... }:
{
  imports = [
    ./lazyvim.nix
    ./vscode.nix
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
