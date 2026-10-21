# Shared runtimes, language tools and editor settings.
# Imported by development modules and project shells.
{ pkgs }:
{
  # Shared by GUI editors and the general development shells.
  runtimes = with pkgs; [
    go
    # GUI editors and shells can compile/check Rust without downloading a toolchain.
    rustc
    cargo
    clippy
    rustfmt
    # Rust links through cc; GUI editors need the same wrapper as mkShell.
    stdenv.cc
    gnumake
    cmake
    ninja
    pkg-config
    uv
    bun
    python3
    # Node-shebang tools must not depend on Bun's Node-API compatibility layer.
    nodejs
  ];

  # Foreign Python wheels need these outside Nix's patched library linkage.
  # Shared by the opt-in Python shell and the host's foreign-binary loader.
  pythonNativeLibraries = with pkgs; [
    libglvnd
    libxcb
    glib
    stdenv.cc.cc
    zlib
  ];

  nixdSettings =
    { profile, isNixOS }:
    let
      # JSON quotes strings; additionally escape Nix interpolation in names/paths.
      quote = value: builtins.replaceStrings [ "\${" ] [ "\\\${" ] (builtins.toJSON value);
      flakeConfig = "(builtins.getFlake ${quote "path:${profile.configRepo}"}).${
        if isNixOS then
          "nixosConfigurations.${quote profile.hostName}"
        else
          "homeConfigurations.${quote profile.profileName}"
      }";
    in
    {
      nixpkgs.expr =
        if isNixOS then
          "${flakeConfig}.pkgs"
        else
          "(builtins.getFlake ${quote "path:${profile.configRepo}"}).homeConfigurations.${quote profile.profileName}.pkgs";
      formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
      options = {
        home_manager.expr =
          if isNixOS then
            "${flakeConfig}.options.home-manager.users.type.getSubOptions []"
          else
            "${flakeConfig}.options";
      }
      // pkgs.lib.optionalAttrs isNixOS {
        nixos.expr = "${flakeConfig}.options";
      };
    };

  # CLI tools and Neovim defaults. VSCodium uses native extensions where they
  # provide an integrated server, with explicit paths for external tools.
  languageServers = with pkgs; [
    # Nix: nixd, formatter and linter.
    nixd
    nixfmt
    statix
    # Lua
    lua-language-server
    stylua
    # C/C++ — clangd and clang-format both live in clang-tools
    clang-tools
    # Go. gofumpt and goimports (from gotools) are what LazyVim's go extra
    # formats with; delve is used by the VSCodium Go extension.
    gopls
    gofumpt
    gotools
    golangci-lint
    delve
    # Rust. rustup does not put rust-analyzer on PATH unless the component is
    # added, so the package is used instead.
    rust-analyzer
    # TypeScript / JavaScript. The Prettier extra uses the CLI directly.
    vtsls
    prettier
    # Python
    basedpyright
    ruff
    # Markdown
    marksman
    markdownlint-cli2
    markdown-toc
    # JSON / YAML.
    yaml-language-server
    vscode-langservers-extracted
    # TOML
    taplo
    # Bash; configured explicitly in LazyVim overrides.
    bash-language-server
    shfmt
    shellcheck
    # Docker.
    dockerfile-language-server
    hadolint
  ];

  # The debugger runs independently of each project's selected interpreter.
  debugAdapters = {
    python = pkgs.python3.withPackages (ps: [ ps.debugpy ]);
    lldb = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;
  };

  goplsSettings = {
    gofumpt = true;
    staticcheck = true;
    usePlaceholders = true;
    completeUnimported = true;
  };

  pythonAnalysis = {
    typeCheckingMode = "basic";
    diagnosticMode = "openFilesOnly";
  };

  # Keep dependency/output trees out of editor watchers, not out of file pickers.
  watcherExcludes = [
    "**/.git/objects/**"
    "**/.git/subtree-cache/**"
    "**/.direnv/**"
    "**/.venv/**"
    "**/node_modules/**"
    "**/target/**"
    "**/.next/**"
    "**/__pycache__/**"
  ];

  # Editor-only limits leave explicit builds and game processes unrestricted.
  rustAnalyzerSettings = {
    numThreads = 4;
    cachePriming.numThreads = 4;
    cargo = {
      allFeatures = false;
      extraEnv.CARGO_BUILD_JOBS = "4";
    };
    check.command = "clippy";
  };

  # Allow only PlatformIO cross-GCC drivers to supply target system headers.
  # clangd requires absolute paths here; it does not expand ~ or $HOME.
  clangdArgs =
    homeDir:
    let
      bin = "${homeDir}/.platformio/packages/**/bin";
    in
    [
      "--background-index"
      "--clang-tidy"
      "--header-insertion=iwyu"
      "--completion-style=detailed"
      "--function-arg-placeholders"
      "--fallback-style=llvm"
      "-j=4"
      (
        "--query-driver="
        + pkgs.lib.concatStringsSep "," [
          "${bin}/xtensa-*-gcc"
          "${bin}/xtensa-*-g++"
          "${bin}/riscv*-gcc"
          "${bin}/riscv*-g++"
          "${bin}/avr-gcc"
          "${bin}/avr-g++"
          "${bin}/arm-*-gcc"
          "${bin}/arm-*-g++"
        ]
      )
    ];

  # VSCodium's Jupyter extension needs an interpreter with ipykernel.
  jupyterPython = pkgs.python3.withPackages (
    ps: with ps; [
      jupyter-client
      ipykernel
      ipython
      jupytext
      nbformat
      pyzmq
      matplotlib
      plotly
      pillow
      requests
    ]
  );
}
