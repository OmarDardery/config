{
  lib,
  pkgs,
  profile,
  ...
}:
let
  mountPoint = "/mnt/storage";
  repository = "${mountPoint}/backup";
  passwordFile = "/var/lib/restic/home.password";
in
{
  services.restic.backups.home = {
    inherit repository passwordFile;
    paths = [ profile.homeDirectory ];
    createWrapper = true;
    initialize = true;
    runCheck = true;
    exclude = [
      "${profile.homeDirectory}/.cache"
      "${profile.homeDirectory}/.local/share/Trash"
      "${profile.homeDirectory}/.local/share/Steam/steamapps/common"
      "${profile.homeDirectory}/.local/share/Steam/steamapps/shadercache"
      "**/node_modules"
      "**/.venv"
      "**/.direnv"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  systemd.services.restic-home-password = {
    description = "Initialize the persistent local backup password";
    path = [
      pkgs.coreutils
      pkgs.openssl
    ];
    script = builtins.readFile ../pkgs/restic-password.sh;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "restic";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
  };

  systemd.services.restic-backups-home = {
    requires = [ "restic-home-password.service" ];
    # Wait for the real filesystem, including when it uses systemd automount.
    # Never create a repository in the root filesystem beneath an absent mount.
    unitConfig = {
      RequiresMountsFor = [ mountPoint ];
      ConditionPathIsMountPoint = mountPoint;
    };
    # This local repository does not need network-online.target.
    wants = lib.mkForce [ ];
    after = lib.mkForce [ "restic-home-password.service" ];
    serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };
}
