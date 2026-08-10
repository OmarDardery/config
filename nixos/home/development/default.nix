{ pkgs, ... }:
{
  imports = [ ./vscode.nix ];

  home.packages = with pkgs; [
    # toolchains
    rustup
    go
    bun
    uv

    # C/C++
    gcc
    clang-tools

    # embedded
    platformio-core
    arduino-cli

    # editors
    zed-editor
    jetbrains-toolbox
  ];

  home.sessionVariables = {
    # Foreign binaries (Zed, etc.) hardcode /usr/share/X11/xkb for keyboard layout
    # data, which doesn't exist on NixOS (no /usr). This is libxkbcommon's own
    # documented override for that lookup, pointed at the real Nix store path.
    XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
  };
}
