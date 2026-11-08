{ pkgs, zenInput }:
let
  system = pkgs.stdenv.hostPlatform.system;
  packages = zenInput.packages.${system};
in
# This release asset was replaced after the upstream flake recorded its hash.
# Keep the workaround limited to that version and architecture.
if system == "x86_64-linux" && packages.zen-browser-unwrapped.version == "1.23.3b" then
  packages.default.override {
    zen-browser-unwrapped = packages.zen-browser-unwrapped.override {
      hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
    };
  }
else
  packages.default
