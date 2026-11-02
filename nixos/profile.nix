# Personal defaults; generated deployment identity and GPU overrides stay local.
let
  local = if builtins.pathExists ./local-profile.nix then import ./local-profile.nix else { };
  localGpu = if builtins.pathExists ./local-gpu.nix then import ./local-gpu.nix else { };
in
rec {
  username = local.username or "oad";
  homeDirectory = local.homeDirectory or "/home/${username}";
  configRepo = local.configRepo or "${homeDirectory}/config";
  profileName = local.profileName or username;
  hostName = local.hostName or "nixos";
  system = local.system or "x86_64-linux";
  gpu = {
    backend = "mesa";
    nvidiaVersion = null;
    nvidiaHash = null;
    nvidiaAcceptLicense = false;
  }
  // localGpu;
  displayName = "Omar Dardery";
  gitName = "OmarDardery";
  gitEmail = "oadardery@gmail.com";
}
