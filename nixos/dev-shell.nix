{ pkgs }:
pkgs.mkShellNoCC {
  name = "config-development";
  packages = with pkgs; [
    bashInteractive
    git
    nixd
    nixfmt
    shellcheck
    shfmt
    bash-language-server
    python312
    uv
    ruff
    basedpyright
  ];

  CONFIG_DEV_SHELL = "1";
  NIX_PATH = "nixpkgs=${pkgs.path}";
  UV_PYTHON = "${pkgs.python312}/bin/python3";
  UV_PYTHON_DOWNLOADS = "never";
  UV_PYTHON_PREFERENCE = "only-system";
  # debugpy's attach_linux_amd64.so wheel helper links libstdc++ and libgcc_s.
  # Supply only their runtime libraries, scoped to this shell (not a compiler).
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ];
  PYTHONNOUSERSITE = "1";
  # Prevent third-party pytest plugins from the host leaking into project tests.
  PYTEST_DISABLE_PLUGIN_AUTOLOAD = "1";
}
