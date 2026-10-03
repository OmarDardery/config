{ lib, profile, ... }:
{
  programs.git = {
    enable = true;
    settings = lib.mkMerge [
      {
        init.defaultBranch = "main";

        # `git push` on a branch with no upstream sets one and pushes, instead of
        # failing with the --set-upstream hint every time.
        push.autoSetupRemote = true;

        # `git pull` rebases local commits onto the fetched head rather than
        # recording a merge commit for having pulled.
        pull.rebase = true;

        # Record how a conflict was resolved and replay that resolution if the
        # same conflict comes back — which it does, once per rebase attempt.
        rerere.enabled = true;

        # Slower than the default myers, but resolves moved blocks to the block
        # that moved rather than to whatever lines happen to line up.
        diff.algorithm = "histogram";

        # `git branch` most-recent-first. The alphabetical default is useless
        # past a handful of branches.
        branch.sort = "-committerdate";
      }
      (lib.optionalAttrs (profile.gitName != null) { user.name = profile.gitName; })
      (lib.optionalAttrs (profile.gitEmail != null) { user.email = profile.gitEmail; })
    ];
  };

  # Syntax-highlighted diffs. This is its own module rather than a git setting,
  # and it needs to be told to hook into git explicitly.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
