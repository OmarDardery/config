{ lib, profile, ... }:
{
  programs.git = {
    enable = true;
    package = null;
    lfs = {
      enable = true;
      package = null;
    };
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

  programs.git.settings = {
    core.pager = "delta";
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictStyle = "zdiff3";
  };
  xdg.configFile."gh/config.yml".text = "git_protocol: ssh\nprompt: enabled\n";
}
