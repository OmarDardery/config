{
  pkgs,
  lib,
  isNixOS,
  ...
}:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };
in
{
  imports = [
    ./clangd.nix
    ./git.nix
    ./platformio.nix
    ./vscode.nix
    ./lazyvim.nix
    #./doom-emacs.nix
  ];

  # Language servers, formatters and linters. These are installed rather than
  # left on the editor wrappers' private PATHs because VSCodium's extensions
  # spawn them from the session PATH — see ./toolchain.nix.
  home = {
    packages =
      toolchain.languageServers
      ++ toolchain.runtimes
      ++ (with pkgs; [
        jetbrains-toolbox
        platformio-core
      ]);

    # Foreign binaries (Zed, etc.) hardcode /usr/share/X11/xkb for keyboard layout
    # data, which doesn't exist on NixOS (no /usr). This is libxkbcommon's own
    # documented override for that lookup, pointed at the real Nix store path.
    sessionVariables = lib.optionalAttrs isNixOS {
      XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
    };
    sessionPath = [ "$HOME/.bun/bin" ];
  };
}
