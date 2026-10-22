# Editor configuration and private dependencies; no global development toolchain.
{ pkgs, ... }:
let
  toolchain = import ../../lib/toolchain.nix { inherit pkgs; };
in
{
  imports = [
    ./lazyvim.nix
    ./vscode.nix
  ];
  home.sessionVariables.PLATFORMIO_EXTRA_SCRIPTS = "pre:${toolchain.platformioCompiledb}";
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
        - -mlongcalls
        - -mtext-section-literals
        - -fstrict-volatile-bitfields
        - -fno-tree-switch-conversion
        - -freorder-blocks
  '';
}
