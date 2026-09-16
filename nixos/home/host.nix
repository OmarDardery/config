# Machine-specific settings. This is the only file under home/ that assumes
# anything about THIS laptop: where the config repo lives, what the flake is
# called, and which disks are mounted. Everything else in home/ is portable —
# drop this file and replace it when moving to another machine.
{ ... }:
let
  configRepo = "/home/oad/configs/nixos";
in
{
  # Make the machine-specific repository location available to editor modules
  # as well as nh, without repeating it in otherwise portable files.
  _module.args = { inherit configRepo; };
  programs.nh.flake = configRepo;

  programs.zsh.shellAliases = {
    up = "nh os switch";
    cnf = "sudo nano ~/configs/nixos/configuration.nix";
    lc = "cd /mnt/storage/Coding";
  };
}
