{
  pkgs,
  lib,
  isNixOS,
  ...
}:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };
  # A pre-script, not a post one: the tool works by wrapping the object
  # builder's emitter, so it has to be loaded before $BUILD_SCRIPT creates the
  # source nodes. PlatformIO runs pre-scripts at builder/main.py:172, post ones
  # at :183 — after the sources exist, which would leave the database empty.
  #
  # The guard keeps `pio run -t compiledb` working: PlatformIO loads the same
  # tool itself for that target, and applying it twice records every
  # translation unit twice.
  compiledb = pkgs.writeText "pio-compiledb.py" ''
    Import("env")
    from SCons.Script import COMMAND_LINE_TARGETS, Default

    if "compiledb" not in COMMAND_LINE_TARGETS:
        env.Tool("compilation_db")
        db = env.CompilationDatabase("$COMPILATIONDB_PATH")
        # Rewrite it every build. SCons would otherwise consider a database
        # that already exists up to date, and a stale one is worse than none:
        # clangd reads it happily and reports errors against last week's flags.
        env.AlwaysBuild(db)
        Default(db)
  '';
in
{
  imports = [
    ./git.nix
    ./vscode.nix
    ./lazyvim.nix
  ];

  # Language servers, formatters and linters. These are installed rather than
  # left on the editor wrappers' private PATHs because VSCodium's extensions
  # spawn them from the session PATH — see ./toolchain.nix.
  home = {
    packages =
      toolchain.languageServers
      ++ toolchain.runtimes
      ++ (with pkgs; [
        (callPackage ../../pkgs/jetbrains-toolbox.nix { })
        platformio-core
        opencode
        (callPackage ../../pkgs/antigravity-cli.nix { })
      ]);

    # Foreign binaries (Zed, etc.) hardcode /usr/share/X11/xkb for keyboard layout
    # data, which doesn't exist on NixOS (no /usr). This is libxkbcommon's own
    # documented override for that lookup, pointed at the real Nix store path.
    sessionVariables = {
      PLATFORMIO_EXTRA_SCRIPTS = "pre:${compiledb}";
    }
    // lib.optionalAttrs isNixOS {
      XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
    };
    sessionPath = [ "$HOME/.bun/bin" ];
  };

  xdg.configFile."clangd/config.yaml".text = ''
    CompileFlags:
      Remove:
        # Xtensa (ESP32) codegen. clang errors on all three.
        - -mlongcalls
        - -mtext-section-literals
        - -fstrict-volatile-bitfields
        # GCC-only optimisation spellings. clang errors on the first and warns
        # on the second, which shows up as a diagnostic on line 1 of every file.
        - -fno-tree-switch-conversion
        - -freorder-blocks
  '';
}
