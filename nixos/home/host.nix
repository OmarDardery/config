# Machine-specific settings. This is the only file under home/ that assumes
# anything about THIS laptop: where the config repo lives, what the flake is
# called, and which disks are mounted. Everything else in home/ is portable —
# drop this file and replace it when moving to another machine.
{ ... }:
{
  # Which flake `nh` acts on. This is the only place the repo path is written,
  # so `up` below no longer has to repeat it.
  programs.nh.flake = "/home/oad/configs/nixos";

  programs.zsh.shellAliases = {
    up = "nh os switch";
    cnf = "sudo nano ~/configs/nixos/configuration.nix";
    lc = "cd /mnt/storage/Coding";
  };
}
