# Personal defaults; generated deployment identity stays local.
let
  local = if builtins.pathExists ./local-profile.nix then import ./local-profile.nix else { };
in
rec {
  username = local.username or "oad";
  homeDirectory = local.homeDirectory or "/home/${username}";
  configRepo = local.configRepo or "${homeDirectory}/config";
  hostName = local.hostName or "nixos";
  system = local.system or "x86_64-linux";
  displayName = "Omar Dardery";
  gitName = "OmarDardery";
  gitEmail = "oadardery@gmail.com";
}
