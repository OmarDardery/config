{ pkgs, lib, ... }:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };
in
{
  imports = [
    ./clangd.nix
    ./platformio.nix
    ./vscode.nix
    ./lazyvim.nix
    ./doom-emacs.nix
  ];

  # Language servers, formatters and linters. These are installed rather than
  # left on the editor wrappers' private PATHs because VSCodium's extensions
  # spawn them from the session PATH — see ./toolchain.nix.
  home.packages = toolchain.languageServers ++ (with pkgs; [
    # toolchains.
    #
    # rustup is lowPrio because it ships a `rust-analyzer` shim that collides
    # with the real rust-analyzer in ./toolchain.nix. The shim is the wrong one
    # to keep: it only forwards to a component rustup has been told to install,
    # which this setup never does, so it fails at startup. lowPrio applies only
    # where there is a conflict — cargo, rustc and rustup itself are unaffected.
    (lib.lowPrio rustup)
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

    # C/C++. clangd and clang-format come from clang-tools in ./toolchain.nix.
    gcc

    # embedded
    platformio-core
    arduino-cli

    # editors
    jetbrains-toolbox
  ]);

  home.sessionVariables = {
    # Foreign binaries (Zed, etc.) hardcode /usr/share/X11/xkb for keyboard layout
    # data, which doesn't exist on NixOS (no /usr). This is libxkbcommon's own
    # documented override for that lookup, pointed at the real Nix store path.
    XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
    PATH = "/home/oad/.bun/bin:$PATH";
  };
}
