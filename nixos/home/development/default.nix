{
  pkgs,
  lib,
  isNixOS,
  ...
}:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };
  # Load compilation_db before SCons creates source nodes.
  # Skip the explicit compiledb target to avoid duplicate entries.
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
    ./lazyvim.nix
  ];

  # Install shared tools on the session PATH for GUI editors and shells.
  home = {
    packages =
      toolchain.languageServers
      ++ toolchain.runtimes
      ++ (with pkgs; [
        platformio-core
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

  programs.opencode = {
    enable = true;
    tui.theme = lib.mkIf isNixOS "noctalia";
  };

  # One explicit notebook kernel; regular Python projects select their own .venv.
  xdg.dataFile."jupyter/kernels/nix-python/kernel.json".text = builtins.toJSON {
    argv = [
      "${toolchain.jupyterPython}/bin/python3"
      "-m"
      "ipykernel_launcher"
      "-f"
      "{connection_file}"
    ];
    display_name = "Python (Nix notebooks)";
    language = "python";
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
