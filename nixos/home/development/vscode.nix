# VSCodium.
#
# `programs.vscodium`, NOT `programs.vscode`. As of home-manager 26.05 each
# VSCode fork has its own module, and `programs.vscode` unconditionally writes
# to upstream VS Code's paths — ~/.vscode/extensions and ~/.config/Code/User.
# Setting `programs.vscode.package = vscodium` therefore installs every
# extension into a directory VSCodium never reads, which shows up as an empty
# Extensions pane and nothing else. home-manager warns about it, but the warning
# is easy to miss in a rebuild log. This module writes to ~/.vscode-oss and
# ~/.config/VSCodium/User instead.
#
# Extensions all come from nixpkgs, so the marketplace is only used for manual
# installs. VSCodium ships pointed at Open VSX; Microsoft's marketplace terms
# forbid non-official builds from using it, and Microsoft's own proprietary
# extensions (cpptools, Pylance) refuse to activate outside a
# Microsoft-published editor anyway. The open equivalents below are also what
# ./lazyvim.nix already uses, which is the point: the two editors should
# disagree about keybindings, not about what a diagnostic says.
#
# Every server, formatter and linter referenced here is installed by
# ./toolchain.nix. Paths below are absolute store paths rather than bare names —
# an extension that spawns `ruff` picks up whatever PATH ordering gives it,
# which is how you end up debugging why one editor formats differently.
{
  pkgs,
  config,
  profile,
  isNixOS,
  ...
}:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };

  # clang-tools, vscode-langservers-extracted etc. are multi-binary packages, so
  # name the binary explicitly rather than relying on meta.mainProgram.
  bin = pkg: name: "${pkg}/bin/${name}";

  # Noctalia must render this file before the theme's first use. Keep the
  # manifest path inside the extension; only the symlink points outside it.
  noctaliaTheme = pkgs.vscode-utils.buildVscodeExtension {
    pname = "noctalia";
    version = "1.0.0";
    vscodeExtPublisher = "noctalia";
    vscodeExtName = "noctalia";
    vscodeExtUniqueId = "noctalia.noctalia";
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase =
      let
        manifest = pkgs.writeText "noctalia-package.json" (
          builtins.toJSON {
            name = "noctalia";
            displayName = "Noctalia";
            publisher = "noctalia";
            version = "1.0.0";
            engines.vscode = "^1.70.0";
            categories = [ "Themes" ];
            contributes.themes = [
              {
                id = "NoctaliaTheme";
                label = "NoctaliaTheme";
                uiTheme = "vs-dark";
                path = "themeJsonSymlink.json";
                _watch = true;
              }
              {
                id = "NoctaliaLight";
                label = "NoctaliaLight";
                uiTheme = "vs";
                path = "themeJsonSymlink.json";
                _watch = true;
              }
            ];
          }
        );
      in
      ''
        runHook preInstall
        mkdir -p "$out/$installPrefix"
        cp ${manifest} "$out/$installPrefix/package.json"
        ln -s ${pkgs.lib.escapeShellArg "${config.xdg.stateHome}/noctalia/theme/vscode.json"} \
          "$out/$installPrefix/themeJsonSymlink.json"
        runHook postInstall
      '';
  };
in
{
  programs.vscodium = {
    enable = true;

    # The FHS wrapper, not the plain package. PlatformIO downloads its own
    # toolchain binaries into ~/.platformio at runtime; those are ordinary
    # dynamically-linked ELF files that need an /lib ld.so to start.
    package = pkgs.vscodium.fhs;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # ── Languages ────────────────────────────────────────────────────
        # Nix. nix-ide is the extension; nixd and nixfmt below do the work.
        jnoortheen.nix-ide
        # Lua
        sumneko.lua
        # C/C++. clangd is the language server here; CodeLLDB handles debugging.
        llvm-vs-code-extensions.vscode-clangd
        vadimcn.vscode-lldb
        ms-vscode.cmake-tools
        # Present for exactly one reason: platformio-ide declares
        # `extensionDependencies: ["ms-vscode.cpptools"]`, and VSCodium refuses
        # to activate an extension whose hard dependency is missing — which is
        # why the PlatformIO toolbar never appeared.
        #
        # Microsoft's fork block is real, but it lives in the *native* server:
        # `bin/cpptools` in this package carries the string "The C/C++ extension
        # may be used only with Microsoft Visual Studio … and successor
        # Microsoft products". The JavaScript half activates fine. So the
        # dependency resolves, and the IntelliSense settings below make sure the
        # gated binary is never launched to fail in the first place. clangd was
        # already doing that work.
        ms-vscode.cpptools
        # Go — brings its own debug adapter, driving delve.
        golang.go
        # Rust. rust-analyzer's own extension; CodeLLDB above debugs it.
        rust-lang.rust-analyzer
        # TypeScript / JavaScript. No language extension: VSCodium bundles the
        # TypeScript server, the same way it bundles JSON support.
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        # Tauri. Rust support comes from rust-analyzer above; this adds the
        # tauri.conf.json schema, the CLI commands and the config completions.
        tauri-apps.tauri-vscode
        # Python. basedpyright, not Pylance — Pylance is proprietary and refuses
        # to run here. ms-python.python is still needed: it owns interpreter
        # selection and the test/debug UI that the others plug into.
        ms-python.python
        ms-python.debugpy
        detachhead.basedpyright
        charliermarsh.ruff
        # Notebook integration uses the configured Python kernel.
        ms-toolsai.jupyter
        # Markdown
        yzhang.markdown-all-in-one
        davidanson.vscode-markdownlint
        # YAML / TOML
        redhat.vscode-yaml
        tamasfe.even-better-toml
        # Docker. Dockerfiles are linted by hadolint, which has no extension in
        # nixpkgs — exiasr.hadolint is on Open VSX if you want it; the hadolint
        # binary itself is already on PATH from ./toolchain.nix.
        ms-azuretools.vscode-docker
        # Shell
        timonwong.shellcheck
        foxundermoon.shell-format

        # ── Embedded ─────────────────────────────────────────────────────
        platformio.platformio-vscode-ide

        # ── Tooling and UI ───────────────────────────────────────────────
        eamodio.gitlens
        mhutchie.git-graph
        mkhl.direnv
        editorconfig.editorconfig
        usernamehw.errorlens
        anthropic.claude-code
        noctaliaTheme
        pkief.material-icon-theme
      ];

      userSettings = {
        # ── Editor ───────────────────────────────────────────────────────
        # Same three deltas as nvim/lua/config/options.lua in ./lazyvim.nix.
        "editor.lineNumbers" = "relative";
        "editor.cursorSurroundingLines" = 8;
        "editor.renderWhitespace" = "boundary";

        "editor.formatOnSave" = true;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        # "JetBrainsMono Nerd Font", never "JetBrains Mono" — the nerd-fonts
        # package publishes only the patched name. Installed by the system
        # greeter configuration and ../desktop.nix.
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 14;
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";

        "workbench.colorTheme" = "NoctaliaTheme";
        # Keep the editor titlebar usable while hiding its window buttons.
        "window.titleBarStyle" = "custom";
        "window.controlsStyle" = "hidden";
        "window.autoDetectColorScheme" = true;
        "workbench.preferredDarkColorTheme" = "NoctaliaTheme";
        "workbench.preferredLightColorTheme" = "NoctaliaLight";
        "workbench.iconTheme" = "material-icon-theme";

        # Nothing here can update itself — the whole install is a store path,
        # and an extension that "updated" would be reverted on next rebuild.
        "extensions.autoUpdate" = false;
        "extensions.autoCheckUpdates" = false;
        "update.mode" = "none";

        "telemetry.telemetryLevel" = "off";

        # ── Nix ──────────────────────────────────────────────────────────
        # nix-ide defaults to no server at all; both halves must be named.
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = bin pkgs.nixd "nixd";
        "nix.formatterPath" = bin pkgs.nixfmt "nixfmt";
        # The same flake-aware options completion ./lazyvim.nix gives nixd.
        "nix.serverSettings".nixd = toolchain.nixdSettings { inherit profile isNixOS; };

        # ── Lua ──────────────────────────────────────────────────────────
        "Lua.misc.executablePath" = bin pkgs.lua-language-server "lua-language-server";

        # ── C/C++ ────────────────────────────────────────────────────────
        "clangd.path" = bin pkgs.clang-tools "clangd";
        # --query-driver, so clangd can ask PlatformIO's cross-compilers where
        # their own system headers are. Shared with Neovim; see
        # ./toolchain.nix. The flag removals that go with it are in
        # ./default.nix, which every editor picks up from clangd itself.
        "clangd.arguments" = toolchain.clangdArgs config.home.homeDirectory;
        "cmake.cmakePath" = bin pkgs.cmake "cmake";
        # cpptools is installed only to satisfy PlatformIO — see the extension
        # list. Its native server is the part Microsoft gates in forks, so the
        # engine is switched off and it is never started; leaving it on would
        # mean a licence popup on every C/C++ file and two servers publishing
        # competing diagnostics.
        "C_Cpp.intelliSenseEngine" = "disabled";
        "C_Cpp.autocomplete" = "disabled";
        "C_Cpp.errorSquiggles" = "disabled";
        "C_Cpp.formatting" = "disabled";
        # It also has no update mechanism worth running against a store path.
        "C_Cpp.updateChannel" = "Default";

        # The pinned extension prepends customPATH to the inherited PATH.
        "platformio-ide.useBuiltinPIOCore" = false;
        "platformio-ide.useBuiltinPython" = false;
        "platformio-ide.customPATH" = "${pkgs.platformio-core}/bin";

        # ── Go ───────────────────────────────────────────────────────────
        # The Go extension would otherwise offer to install these into GOPATH.
        "go.toolsManagement.autoUpdate" = false;
        "go.alternateTools" = {
          gopls = bin pkgs.gopls "gopls";
          dlv = bin pkgs.delve "dlv";
          gofumpt = bin pkgs.gofumpt "gofumpt";
          goimports = bin pkgs.gotools "goimports";
          "golangci-lint-v2" = bin pkgs.golangci-lint "golangci-lint";
        };
        "go.formatTool" = "gofumpt";
        "go.lintTool" = "golangci-lint-v2";

        # ── Rust ─────────────────────────────────────────────────────────
        # Carried over from the old ~/.config/Code/User/settings.json.
        "rust-analyzer.check.command" = "clippy";
        "rust-analyzer.numThreads" = toolchain.rustAnalyzerSettings.numThreads;
        "rust-analyzer.cachePriming.numThreads" = toolchain.rustAnalyzerSettings.cachePriming.numThreads;
        "rust-analyzer.cargo.extraEnv" = toolchain.rustAnalyzerSettings.cargo.extraEnv;
        "rust-analyzer.server.path" = bin pkgs.rust-analyzer "rust-analyzer";

        # ── Python ───────────────────────────────────────────────────────
        # The pinned extension and pkgs.basedpyright both ship 1.39.3. Use the
        # bundled server for parity without requiring it in every project env;
        # this extension has no supported external server-path setting.
        "basedpyright.importStrategy" = "useBundled";
        "ruff.importStrategy" = "fromEnvironment";
        "ruff.path" = [ (bin pkgs.ruff "ruff") ];
        "python.defaultInterpreterPath" = bin toolchain.jupyterPython "python3";
        # ms-python ships its own Pylance-flavoured analysis; basedpyright is
        # the language server here, so turn the built-in one off to stop the
        # two of them publishing duplicate diagnostics.
        "python.languageServer" = "None";

        # ── Shell ────────────────────────────────────────────────────────
        "shellcheck.executablePath" = bin pkgs.shellcheck "shellcheck";
        "shellformat.path" = bin pkgs.shfmt "shfmt";

        # ── Formatters, per language ─────────────────────────────────────
        # Mirrors conform.nvim's formatters_by_ft in ./lazyvim.nix.
        "[nix]".editor.defaultFormatter = "jnoortheen.nix-ide";
        "[python]".editor.defaultFormatter = "charliermarsh.ruff";
        "[go]".editor.defaultFormatter = "golang.go";
        "[rust]".editor.defaultFormatter = "rust-lang.rust-analyzer";
        "[shellscript]".editor.defaultFormatter = "foxundermoon.shell-format";
        "[c]".editor.defaultFormatter = "llvm-vs-code-extensions.vscode-clangd";
        "[cpp]".editor.defaultFormatter = "llvm-vs-code-extensions.vscode-clangd";
        "[lua]".editor.defaultFormatter = "sumneko.lua";
        "[javascript]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[typescript]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[typescriptreact]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[json]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[jsonc]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[yaml]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[markdown]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[toml]".editor.defaultFormatter = "tamasfe.even-better-toml";
        "prettier.prettierPath" = "${pkgs.prettier}/lib/node_modules/prettier/index.cjs";

        # ── Agent ────────────────────────────────────────────────────────
        "claudeCode.preferredLocation" = "panel";

        # Keep language-server semantic tokens enabled with Noctalia's theme.
        "editor.semanticHighlighting.enabled" = true;
      };
    };
  };
}
