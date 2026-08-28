# PlatformIO, on the IDE side.
#
# The CLI and its udev rules are installed elsewhere — platformio-core in
# ./default.nix, the rules in ../../configuration.nix, which has to be
# system-wide. What is left is the one thing PlatformIO does not do for you:
# keep a compilation database around for clangd.
#
# Why it is needed at all: PlatformIO generates c_cpp_properties.json, which
# only Microsoft's cpptools reads, and cpptools is disabled here (see
# ./vscode.nix for why). clangd wants compile_commands.json instead, and
# without one it falls back to a bare `clang file.cpp` — no framework include
# paths, so every <Arduino.h> reports "file not found". The database is a
# per-project artifact and cannot be pinned in Nix: its include paths come from
# that project's board and framework.
#
# So instead of generating it by hand per project, every build generates it.
# `pio run -t compiledb` is not a separate mode — it just loads a SCons tool
# and asks for one extra target (builder/main.py:157,198). A pre-script can do
# the same for an ordinary `pio run`, which is what this is.
#
# The flag removals that make the result readable by clang live in
# ./clangd.nix; the --query-driver that finds the cross-compiler's own headers
# is in ./toolchain.nix. All three are needed together.
{ pkgs, ... }:
let
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
  # PlatformIO reads this as the default for `extra_scripts`
  # (project/options.py:818). It is a default, not an override — a project that
  # sets extra_scripts in its own platformio.ini shadows this, and needs the
  # script listed there instead.
  home.sessionVariables.PLATFORMIO_EXTRA_SCRIPTS = "pre:${compiledb}";
}
