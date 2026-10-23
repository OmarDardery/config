# Editor configuration and private dependencies; no global development toolchain.
{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}:
let
  toolchain = import ../../lib/toolchain.nix { inherit pkgs; };
in
{
  imports = [
    ./lazyvim.nix
    ./vscode.nix
  ];
  home.sessionVariables = {
    PLATFORMIO_EXTRA_SCRIPTS = "pre:${config.xdg.configHome}/platformio/compiledb.py";
  }
  // lib.optionalAttrs (!isNixOS) {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  home.file.".local/bin/editor-setup" = {
    enable = !isNixOS;
    executable = true;
    text = "#!/usr/bin/env bash\n" + builtins.readFile ../../pkgs/native-editor-setup.sh;
  };
  xdg.configFile."platformio/compiledb.py".source = toolchain.platformioCompiledb;
  xdg.dataFile."jupyter/kernels/nix-python/kernel.json" = {
    enable = isNixOS;
    text = builtins.toJSON {
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
