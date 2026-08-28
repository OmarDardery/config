# clangd's user-level config.
#
# Editor-independent on purpose. Neovim, VSCodium and Doom all run the same
# clangd binary from ./toolchain.nix, and a compilation database is a project
# artifact rather than an editor one, so a rule that makes one database
# readable has no business being written three times. clangd reads this file
# for every project; per-project overrides still go in a .clangd at the
# project root.
#
# What it is for: PlatformIO's `pio run -t compiledb` writes the real build
# command line, which is a GCC cross-compiler's, and clangd parses it with
# clang. Three of those flags are GCC-only spellings that clang rejects
# outright, and a rejected flag is a hard error — clangd drops the whole entry
# and falls back to a bare `clang file.cpp` with none of the framework's
# include paths. That is the "'Arduino.h' file not found" everyone hits on
# ESP32.
#
# Only flags that change nothing about parsing are dropped here. They are
# codegen and optimisation switches; none of them affects which headers are
# found or which declarations exist, so removing them cannot make clangd
# disagree with the compiler about the code.
{ ... }:
{
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
