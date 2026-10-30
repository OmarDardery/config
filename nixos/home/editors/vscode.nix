# Use the VSCodium-specific Home Manager module for its config and extension paths.
# NixOS pins extensions/tool paths; other distributions use native tools and gallery extensions.
{
  pkgs,
  lib,
  config,
  profile,
  isNixOS,
  desktopEnabled ? false,
  ...
}:
let
  toolchain = import ../../lib/toolchain.nix { inherit pkgs; };
  editorExtensions = with pkgs.vscode-extensions; [
    # Languages
    # Nix. nix-ide is the extension; nixd and nixfmt below do the work.
    jnoortheen.nix-ide
    # Lua
    sumneko.lua
    # C/C++. clangd is the language server here; CodeLLDB handles debugging.
    llvm-vs-code-extensions.vscode-clangd
    vadimcn.vscode-lldb
    ms-vscode.cmake-tools
    # PlatformIO requires the cpptools extension. Its IntelliSense engine is disabled;
    # clangd provides C/C++ language support.
    ms-vscode.cpptools
    # Go — brings its own debug adapter, driving delve.
    golang.go
    # Rust. rust-analyzer's own extension; CodeLLDB above debugs it.
    rust-lang.rust-analyzer
    # TypeScript / JavaScript. No language extension: VSCodium bundles the
    # TypeScript server, the same way it bundles JSON support.
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    # Tauri schemas and project commands.
    tauri-apps.tauri-vscode
    # Python supplies environment selection and test/debug UI; basedpyright supplies analysis.
    ms-python.python
    ms-python.vscode-python-envs
    ms-python.debugpy
    detachhead.basedpyright
    charliermarsh.ruff
    # Notebook integration uses the configured Python kernel.
    ms-toolsai.jupyter
    ms-toolsai.jupyter-renderers
    ms-toolsai.jupyter-keymap
    # Markdown
    yzhang.markdown-all-in-one
    davidanson.vscode-markdownlint
    # YAML / TOML
    redhat.vscode-yaml
    tamasfe.even-better-toml
    # Docker UI; hadolint is available through the shared toolchain.
    ms-azuretools.vscode-docker
    # Shell
    timonwong.shellcheck
    foxundermoon.shell-format

    # Embedded
    platformio.platformio-vscode-ide

    # Tooling and UI
    eamodio.gitlens
    mhutchie.git-graph
    mkhl.direnv
    editorconfig.editorconfig
    gruntfuggly.todo-tree
    github.vscode-pull-request-github
    anthropic.claude-code
    pkief.material-icon-theme
  ];

  # clang-tools, vscode-langservers-extracted etc. are multi-binary packages, so
  # name the binary explicitly rather than relying on meta.mainProgram.
  bin = pkg: name: if isNixOS then "${pkg}/bin/${name}" else name;

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
  xdg.configFile."VSCodium/User/extensions.list" = {
    enable = !isNixOS;
    text =
      lib.concatMapStringsSep "\n" (e: "${e.vscodeExtPublisher}.${e.vscodeExtName}") editorExtensions
      + "\n";
  };
  home.file.".vscode-oss/extensions/noctalia.noctalia-1.0.0/package.json" = {
    enable = !isNixOS && desktopEnabled;
    text = builtins.toJSON {
      name = "noctalia";
      publisher = "noctalia";
      version = "1.0.0";
      engines.vscode = "^1.70.0";
      contributes.themes = [
        {
          id = "NoctaliaTheme";
          label = "NoctaliaTheme";
          uiTheme = "vs-dark";
          path = "theme.json";
        }
        {
          id = "NoctaliaLight";
          label = "NoctaliaLight";
          uiTheme = "vs";
          path = "theme.json";
        }
      ];
    };
  };
  home.file.".vscode-oss/extensions/noctalia.noctalia-1.0.0/theme.json" = {
    enable = !isNixOS && desktopEnabled;
    source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/noctalia/theme/vscode.json";
  };
  programs.vscodium = {
    enable = true;

    # PlatformIO downloads foreign toolchain binaries; use the FHS wrapper.
    package =
      if !isNixOS then
        null
      else
        pkgs.symlinkJoin {
          name = "vscodium-with-tools";
          inherit (pkgs.vscodium) version;
          paths = [ pkgs.vscodium.fhs ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram "$out/bin/codium" --prefix PATH : ${
              lib.makeBinPath toolchain.editorPackages
            }
          '';
          meta.mainProgram = "codium";
        };
    # Give the editor and its terminals explicit tool paths.
    # wrapProgram is applied to both the regular and FHS launcher.

    profiles.default = {
      extensions =
        lib.optionals isNixOS editorExtensions ++ lib.optional (isNixOS && desktopEnabled) noctaliaTheme;

      keybindings = [
        {
          key = "ctrl+alt+o";
          command = "workbench.action.terminal.newWithProfile";
          args.profileName = "OpenCode";
        }
      ];

      userSettings = {
        # Editor
        "editor.lineNumbers" = "relative";
        "editor.cursorSurroundingLines" = 8;
        "editor.renderWhitespace" = "boundary";

        "editor.formatOnSave" = true;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.watcherExclude" = lib.genAttrs toolchain.watcherExcludes (_: true);
        "editor.stickyScroll.enabled" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.linkedEditing" = true;
        "editor.minimap.enabled" = false;
        "explorer.confirmDragAndDrop" = true;
        "terminal.integrated.scrollback" = 10000;
        "terminal.integrated.profiles.linux".OpenCode = {
          path = bin pkgs.opencode "opencode";
          icon = "sparkle";
        };
        "notebook.lineNumbers" = "on";
        "notebook.output.scrolling" = true;
        "notebook.output.textLineLimit" = 200;
        "notebook.formatOnSave.enabled" = true;
        "jupyter.askForKernelRestart" = true;
        "todo-tree.ripgrep.ripgrep" = bin pkgs.ripgrep "rg";
        "todo-tree.filtering.useBuiltInExcludes" = "file and search excludes";
        "todo-tree.filtering.excludeGlobs" = toolchain.watcherExcludes;

        # Use the family name provided by the installed Nerd Font.
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 14;
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace";

        "workbench.colorTheme" = if desktopEnabled then "NoctaliaTheme" else "Default Dark Modern";
        # Keep the editor titlebar usable while hiding its window buttons.
        "window.titleBarStyle" = "custom";
        "window.controlsStyle" = "hidden";
        "window.autoDetectColorScheme" = true;
        "workbench.preferredDarkColorTheme" =
          if desktopEnabled then "NoctaliaTheme" else "Default Dark Modern";
        "workbench.preferredLightColorTheme" =
          if desktopEnabled then "NoctaliaLight" else "Default Light Modern";
        "workbench.iconTheme" = "material-icon-theme";

        # Native extensions update through Codium; NixOS keeps pinned extensions.
        "extensions.autoUpdate" = !isNixOS;
        "extensions.autoCheckUpdates" = !isNixOS;
        "update.mode" = "none";

        "telemetry.telemetryLevel" = "off";

        # Nix
        # nix-ide defaults to no server at all; both halves must be named.
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = bin pkgs.nixd "nixd";
        "nix.formatterPath" = bin pkgs.nixfmt "nixfmt";
        # The same flake-aware options completion ./lazyvim.nix gives nixd.
        "nix.serverSettings".nixd = toolchain.nixdSettings { inherit profile isNixOS; };

        # Lua
        "Lua.misc.executablePath" = bin pkgs.lua-language-server "lua-language-server";

        # C/C++
        "clangd.path" = bin pkgs.clang-tools "clangd";
        # Share cross-compiler arguments with Neovim; common flag removals are in default.nix.
        "clangd.arguments" = toolchain.clangdArgs config.home.homeDirectory;
        "cmake.cmakePath" = bin pkgs.cmake "cmake";
        # Keep the dependency installed without starting a second C/C++ language server.
        "C_Cpp.intelliSenseEngine" = "disabled";
        "C_Cpp.autocomplete" = "disabled";
        "C_Cpp.errorSquiggles" = "disabled";
        "C_Cpp.formatting" = "disabled";
        # It also has no update mechanism worth running against a store path.
        "C_Cpp.updateChannel" = "Default";

        # The pinned extension prepends customPATH to the inherited PATH.
        "platformio-ide.useBuiltinPIOCore" = !isNixOS;
        "platformio-ide.useBuiltinPython" = !isNixOS;
        "platformio-ide.customPATH" = if isNixOS then "${pkgs.platformio-core}/bin" else "";

        # Go
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
        "go.lintOnSave" = "off";
        "gopls" = toolchain.goplsSettings;

        # Rust
        "rust-analyzer.check.command" = toolchain.rustAnalyzerSettings.check.command;
        "rust-analyzer.numThreads" = toolchain.rustAnalyzerSettings.numThreads;
        "rust-analyzer.cachePriming.numThreads" = toolchain.rustAnalyzerSettings.cachePriming.numThreads;
        "rust-analyzer.cargo.allFeatures" = toolchain.rustAnalyzerSettings.cargo.allFeatures;
        "rust-analyzer.cargo.extraEnv" = toolchain.rustAnalyzerSettings.cargo.extraEnv;
        "rust-analyzer.checkOnSave" = true;
        "rust-analyzer.server.path" = bin pkgs.rust-analyzer "rust-analyzer";

        # Python
        # Prefer project versions; extensions provide a fallback when available.
        "basedpyright.importStrategy" = "fromEnvironment";
        "basedpyright.disableOrganizeImports" = true;
        "ruff.importStrategy" = "fromEnvironment";
        "python.defaultInterpreterPath" = "\${workspaceFolder}/.venv/bin/python";
        "python.useEnvironmentsExtension" = true;
        "python.terminal.activateEnvironment" = true;
        "python.testing.pytestEnabled" = true;
        "python.testing.unittestEnabled" = false;
        "python.testing.autoTestDiscoverOnSaveEnabled" = false;
        "basedpyright.analysis.typeCheckingMode" = toolchain.pythonAnalysis.typeCheckingMode;
        "basedpyright.analysis.diagnosticMode" = toolchain.pythonAnalysis.diagnosticMode;
        # basedpyright owns Python diagnostics.
        "python.languageServer" = "None";

        # Shell
        "shellcheck.executablePath" = bin pkgs.shellcheck "shellcheck";
        "shellformat.path" = bin pkgs.shfmt "shfmt";

        # Formatters, per language
        # Use each language extension's formatter integration.
        "[nix]".editor.defaultFormatter = "jnoortheen.nix-ide";
        "[python]" = {
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.codeActionsOnSave" = {
            "source.fixAll.ruff" = "explicit";
            "source.organizeImports.ruff" = "explicit";
          };
        };
        "[go]".editor.defaultFormatter = "golang.go";
        "[rust]".editor.defaultFormatter = "rust-lang.rust-analyzer";
        "[shellscript]".editor.defaultFormatter = "foxundermoon.shell-format";
        "[c]".editor.defaultFormatter = "llvm-vs-code-extensions.vscode-clangd";
        "[cpp]".editor.defaultFormatter = "llvm-vs-code-extensions.vscode-clangd";
        "[lua]".editor.defaultFormatter = "sumneko.lua";
        "[javascript]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[typescript]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[typescriptreact]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[javascriptreact]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[html]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[css]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[scss]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[json]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[jsonc]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[yaml]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[markdown]".editor.defaultFormatter = "esbenp.prettier-vscode";
        "[toml]".editor.defaultFormatter = "tamasfe.even-better-toml";

        "eslint.format.enable" = false;
        "eslint.run" = "onSave";
        "[javascript][javascriptreact][typescript][typescriptreact]"."editor.codeActionsOnSave" = {
          "source.fixAll.eslint" = "explicit";
          "source.organizeImports" = "explicit";
        };
        "errorLens.enabledDiagnosticLevels" = [
          "error"
          "warning"
        ];
        "gitlens.codeLens.enabled" = false;

        # F5 works in a newly opened project; workspace launch.json can override.
        "launch" = {
          version = "0.2.0";
          configurations = [
            {
              name = "Python: current file";
              type = "debugpy";
              request = "launch";
              program = "\${file}";
              cwd = "\${workspaceFolder}";
              console = "integratedTerminal";
              justMyCode = true;
            }
            {
              name = "Go: current package";
              type = "go";
              request = "launch";
              mode = "auto";
              program = "\${fileDirname}";
              cwd = "\${workspaceFolder}";
            }
          ];
        };

        # Agent
        "claudeCode.preferredLocation" = "panel";

        # Keep language-server semantic tokens enabled with Noctalia's theme.
        "editor.semanticHighlighting.enabled" = true;
      };
    };
  };
}
