# Deployment identity, not machine hardware. Edit this for another Linux user.
rec {
  username = "oad";
  homeDirectory = "/home/${username}";
  configRepo = "${homeDirectory}/configs/nixos";
  profileName = username;
  hostName = "nixos";
  system = "x86_64-linux";
  displayName = "Omar Dardery";
  # Use null for either field if that identity should remain unmanaged.
  gitName = "OmarDardery";
  gitEmail = "oadardery@gmail.com";
}
