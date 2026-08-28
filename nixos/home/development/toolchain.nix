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
  # The glob covers every toolchain PlatformIO downloads — xtensa, riscv, avr —
  # not only the one installed today.
  #
  # A function of the home dir rather than a hardcoded path: clangd expands
  # neither ~ nor $HOME here, so callers pass config.home.homeDirectory.
  # Flag removals for those toolchains are editor-independent and live in
  # ./clangd.nix instead.
  clangdArgs = homeDir: [
    "--query-driver=${homeDir}/.platformio/packages/**/bin/*"
  ];

  # Notebook support. Doom's `:lang org +jupyter` talks to a real Jupyter over
  # ZeroMQ, and VSCodium's ms-toolsai.jupyter needs an interpreter with
  # ipykernel in it. Same env for both.
  jupyterPython = pkgs.python3.withPackages (ps: with ps; [
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
  ]);
}
