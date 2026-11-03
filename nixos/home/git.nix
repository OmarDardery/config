{
  pkgs,
  lib,
  profile,
  ...
}:
{
  home.packages = [ pkgs.delta ];
  programs.git = {
    enable = true;
    lfs.enable = true;
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
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      merge.conflictStyle = "zdiff3";
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}
