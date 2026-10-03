# The language toolchain, in one place.
#
# Three editors are configured in this directory and all three want the same
# servers, formatters and linters. Neovim and Doom each take theirs as
# `extraPackages` / `extraBinPackages`, which puts the binaries on that
# editor's *wrapper* PATH and nowhere else. VSCode extensions cannot use that:
# they spawn `gopls`, `ruff`, `shfmt` and friends from the session PATH, so
# whatever they need has to be a real installed package.
#
# So this file is the single list, and ./default.nix installs it into
# home.packages. Each editor still adds its own extras on top — see the
# consumers for what is deliberately local to one of them.
#
# Plain function, not a NixOS module: it is `import`ed, not `imports`ed.
{ pkgs }:
{
  # Shared by GUI editors and the general development shells.
  runtimes = with pkgs; [
    go
    uv
    bun
    python3
    # Node-shebang tools must not depend on Bun's Node-API compatibility layer.
    nodejs
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
      # Applications use Home Manager's policy-scoped set, even on NixOS.
      nixpkgs.expr = "(builtins.getFlake ${quote "path:${profile.configRepo}"}).homeConfigurations.${quote profile.profileName}.pkgs";
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

  # Servers, formatters and linters shared by Neovim, Doom and VSCodium.
  languageServers = with pkgs; [
    # Nix. nixd over nil/rnix-lsp: it is the only one of the three installed, so
    # both eglot and nvim-lspconfig resolve to it. statix is what nvim-lint
    # points at for .nix files; without it every write logs "Error running
    # statix: ENOENT".
    nixd
    nixfmt
    statix
    # Lua
    lua-language-server
    stylua
    # C/C++ — clangd and clang-format both live in clang-tools
    clang-tools
    # Go. gofumpt and goimports (from gotools) are what LazyVim's go extra
    # formats with; delve is the debugger both the VSCode Go extension and
    # nvim-dap drive.
    gopls
    gofumpt
    gotools
    golangci-lint
    delve
    # Rust. rustup does not put rust-analyzer on PATH unless the component is
    # added, so the package is used instead.
    rust-analyzer
    # TypeScript / JavaScript. Both prettiers are needed: conform runs the fast
    # prettierd daemon, but LazyVim's prettier extra shells out to plain
    # `prettier --find-config-path` to decide whether a file is formattable.
    vtsls
    prettierd
    prettier
    # Python
    basedpyright
    ruff
    # Markdown
    marksman
    markdownlint-cli2
    markdown-toc
    # JSON / YAML. jsonls is vscode-json-language-server, which only ships as
    # part of vscode-langservers-extracted.
    yaml-language-server
    vscode-langservers-extracted
    # TOML
    taplo
    # Bash — LazyVim has no bash extra, so it is wired in lazyvim.nix's
    # overrides.lua by hand.
    bash-language-server
    shfmt
    shellcheck
    # Docker. Provides the `docker-langserver` binary eglot looks for.
    dockerfile-language-server
    hadolint
  ];

  # Extra clangd flags every editor here passes. --query-driver lets clangd run
  # a cross-compiler it does not recognise and ask that compiler where its own
  # system headers live. Without it an ESP32 translation unit resolves
  # <Arduino.h> from compile_commands.json and then dies on <stdio.h>: clang
  # looks for newlib in its own resource dir, which has no xtensa sysroot in it.
  # Only cross GCC drivers may be executed, not arbitrary package binaries.
  # Cover xtensa, riscv, avr and arm toolchains, not only today's installation.
  #
  # A function of the home dir rather than a hardcoded path: clangd expands
  # neither ~ nor $HOME here, so callers pass config.home.homeDirectory.
  # Flag removals for those toolchains are editor-independent and live in
  # ./clangd.nix instead.
  clangdArgs = homeDir: [
    (
      "--query-driver="
      + builtins.concatStringsSep "," (
        builtins.concatMap
          (
            target:
            map (compiler: "${homeDir}/.platformio/packages/**/bin/${target}-${compiler}") [
              "gcc"
              "g++"
            ]
          )
          [
            "xtensa-*"
            "riscv*"
            "avr"
            "arm-*"
          ]
      )
    )
  ];

  # Notebook support. Doom's `:lang org +jupyter` talks to a real Jupyter over
  # ZeroMQ, and VSCodium's ms-toolsai.jupyter needs an interpreter with
  # ipykernel in it. Same env for both.
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
