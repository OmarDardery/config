{ lib, profile, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";

      push.autoSetupRemote = true;
      pull.rebase = true;
      rerere.enabled = true;
      diff.algorithm = "histogram";
      branch.sort = "-committerdate";
      user = lib.mkIf (profile.gitName != null || profile.gitEmail != null) {
        name = lib.mkIf (profile.gitName != null) profile.gitName;
        email = lib.mkIf (profile.gitEmail != null) profile.gitEmail;
      };
    };
  };

  # Syntax-highlighted diffs with Git integration.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
