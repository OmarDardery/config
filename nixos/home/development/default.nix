{ pkgs, ... }:
{
  imports = [ ./vscode.nix ];

  home.packages = with pkgs; [
    # toolchains
    rustup
    go
    bun

    # Not redundant with bun. `bun run` hands a script whose bin has a
    # `#!/usr/bin/env node` shebang to the real node when one is on PATH, and
    # runs it inside bun itself when one is not. With no node installed,
    # `bun run build` in a Next.js project executed next-swc through bun's
    # Node-API layer and died with SIGILL in napi_release_threadsafe_function
    # — oven-sh/bun#24829, still open. Installing node is the fix; nothing
    # about the project or bun's own package management changes.
    nodejs

    uv
    python3

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
