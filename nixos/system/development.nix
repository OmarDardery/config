{ pkgs, ... }:
{
  environment.sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = (import ../lib/toolchain.nix { inherit pkgs; }).pythonNativeLibraries;
  # Language toolchains belong to editor wrappers and nix develop, not system PATH.
}
