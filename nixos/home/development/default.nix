{
  pkgs,
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
      ++ (with pkgs; [
        # Compilers and runtimes live in the flake's devShells. Language servers
        # stay global because graphical VSCodium sessions need them on PATH.
        # editors
        jetbrains-toolbox
      ]);

    # Foreign binaries (Zed, etc.) hardcode /usr/share/X11/xkb for keyboard layout
    # data, which doesn't exist on NixOS (no /usr). This is libxkbcommon's own
    # documented override for that lookup, pointed at the real Nix store path.
    sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
    sessionPath = [ "$HOME/.bun/bin" ];
  };
}
