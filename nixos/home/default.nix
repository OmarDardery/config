{ ... }:
{
  imports = [
    ./development
    ./apps.nix
    ./shell.nix
    ./nix-tools.nix
    ./desktop.nix
    ./host.nix
  ];

  home.username = "oad";
  home.homeDirectory = "/home/oad";

  home.stateVersion = "26.05"; # Please read the comment before changing.

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings.user.name = "OmarDardery";
    settings.user.email = "oadardery@gmail.com";
  };

  # Syntax-highlighted diffs. This is its own module rather than a git setting,
  # and it needs to be told to hook into git explicitly.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
