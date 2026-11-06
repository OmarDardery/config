# Machine identity is generated once by the bootstrap and stays out of Git.
let
  local =
    if builtins.pathExists ./local-profile.json then
      builtins.fromJSON (builtins.readFile ./local-profile.json)
    else
      { };
in
rec {
  username = local.username or "oad";
  homeDirectory = local.homeDirectory or "/home/${username}";
  system = local.system or "x86_64-linux";
  configRepo = local.configRepo or "${homeDirectory}/config";
  stateVersion = local.stateVersion or "26.05";
  configHome = local.configHome or "${homeDirectory}/.config";
  stateHome = local.stateHome or "${homeDirectory}/.local/state";
  zshHome = local.zshHome or homeDirectory;
}
