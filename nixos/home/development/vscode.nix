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
  configRepo,
  ...
}:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };

  # clang-tools, vscode-langservers-extracted etc. are multi-binary packages, so
  # name the binary explicitly rather than relying on meta.mainProgram.
  bin = pkg: name: "${pkg}/bin/${name}";

  # ── Palette ───────────────────────────────────────────────────────────
  # Eight colours, assigned by role rather than by taste. The ratios in the
  # comments are measured against the surface each colour actually sits on, so
  # re-pointing a role means re-checking its number.
  #
  # The shape of it: three near-black surfaces form an elevation ladder, three
  # greys carry structure, and the two lightest carry meaning. Chrome recedes
  # and the editor is the brightest large surface, which is what makes code the
  # thing your eye lands on when the window opens.
  p = {
    recessed = "#071319"; # activity bar, sidebar, tab bar — furthest back
    editor = "#0F1C22"; # the work surface
    raised = "#182529"; # panel, terminal, hovers, menus, widgets
    subtle = "#2B3235"; # selection, active line              — 1.33 on editor
    border = "#3B3E42"; # borders, indent guides, rulers      — 1.62
    muted = "#5E5054"; # line numbers, whitespace, disabled  — 2.27
    accent = "#916B70"; # cursor, focus, active tab, badges   — 3.75
    text = "#AFA3AB"; # primary text                        — 7.15, AAA
  };

  # `accent` is deliberately never used for body text. At 3.75 it fails AA,
  # which is exactly the property wanted from something that must be *noticed*
  # rather than *read*.

  # ── Semantic colours ──────────────────────────────────────────────────
  # The palette has no red, green or yellow, and diagnostics, git decorations
  # and the terminal's 16 ANSI slots all need hues that cannot be faked with
  # emphasis. These are derived rather than borrowed: s25–35 / l50–60, which
  # puts them beside `accent` in weight instead of shouting over it. Every
  # `normal` clears 4.5:1 on the editor background, every `bright` clears 6:1.
  c = {
    red = "#BC767A"; # 4.97      brightRed = 6.25
    green = "#5B9A72"; # 5.22      brightGreen = 7.52
    yellow = "#B39965"; # 6.33      brightYellow = 9.12
    blue = "#6D94B0"; # 5.38      brightBlue = 7.79
    magenta = "#AA749A"; # 4.69      brightMagenta = 6.93
    cyan = "#5E9CA1"; # 5.58      brightCyan = 7.92

    brightRed = "#CD898D";
    brightGreen = "#7AB891";
    brightYellow = "#CEBA8D";
    brightBlue = "#90B2CB";
    brightMagenta = "#C695B7";
    brightCyan = "#7FB9BD";
    brightWhite = "#D5CCD1";
  };

  # Alpha-suffixed variants. VSCode composites these over whatever is beneath,
  # which is the only way to tint a selection or a diff without hiding the text
  # under it.
  a = colour: alpha: "${colour}${alpha}";

  # `muted` measures 2.27 on the editor and 2.46 on the chrome, which is fine
  # for a rule or an indent guide and too dim for anything you actually read.
  # Several places need a step between it and full-strength text, and the
  # palette has no such colour — so these are `text` composited down against
  # each surface, computed once here rather than eyeballed. Not new colours:
  # the same ink at lower opacity.
  dim = {
    onEditor = "#6F6D74"; # text @60% over editor    — 3.40
    onChrome = "#8D868E"; # text @80% over recessed  — 5.32
    tab = "#6C6971"; # text @60% over recessed  — 3.49
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
        # C/C++. clangd is the language server here, not cpptools. Debugging
        # comes from CodeLLDB, which is what nvim-dap uses on this machine too.
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
        # Notebooks, against the same kernel Doom uses.
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
        catppuccin.catppuccin-vsc
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
        # package publishes only the patched name, the same trap documented at
        # ./doom-emacs.nix:179. Installed in ../../configuration.nix and
        # ../desktop.nix.
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 14;
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";

        # Base layer only. Everything visible is overridden by the
        # colorCustomizations block below; the base theme is still worth having
        # because it supplies the couple of hundred keys not listed there.
        "workbench.colorTheme" = "Catppuccin Mocha";
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
        "nix.serverSettings".nixd = {
          nixpkgs.expr = ''(builtins.getFlake "${configRepo}").nixosConfigurations.nixos.pkgs'';
          formatting.command = [ (bin pkgs.nixfmt "nixfmt") ];
          options = {
            nixos.expr = ''(builtins.getFlake "${configRepo}").nixosConfigurations.nixos.options'';
            home_manager.expr = ''(builtins.getFlake "${configRepo}").nixosConfigurations.nixos.options.home-manager.users.type.getSubOptions []'';
          };
        };

        # ── Lua ──────────────────────────────────────────────────────────
        "Lua.misc.executablePath" = bin pkgs.lua-language-server "lua-language-server";

        # ── C/C++ ────────────────────────────────────────────────────────
        "clangd.path" = bin pkgs.clang-tools "clangd";
        # --query-driver, so clangd can ask PlatformIO's cross-compilers where
        # their own system headers are. Shared with Neovim; see
        # ./toolchain.nix. The flag removals that go with it are in
        # ./clangd.nix, which every editor picks up from clangd itself.
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

        # ── Go ───────────────────────────────────────────────────────────
        # The Go extension would otherwise offer to install these into GOPATH.
        "go.toolsManagement.autoUpdate" = false;
        "go.alternateTools" = {
          gopls = bin pkgs.gopls "gopls";
          dlv = bin pkgs.delve "dlv";
          "golangci-lint" = bin pkgs.golangci-lint "golangci-lint";
        };
        "go.formatTools" = "gofumpt";
        "go.lintTool" = "golangci-lint";

        # ── Rust ─────────────────────────────────────────────────────────
        # Carried over from the old ~/.config/Code/User/settings.json.
        "rust-analyzer.check.command" = "clippy";
        "rust-analyzer.server.path" = bin pkgs.rust-analyzer "rust-analyzer";

        # ── Python ───────────────────────────────────────────────────────
        # fromEnvironment: use the basedpyright on PATH instead of the copy
        # bundled in the extension, so nvim and VSCodium run the same version.
        "basedpyright.importStrategy" = "fromEnvironment";
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

        # ── Workbench colours ────────────────────────────────────────────
        # See the `p` and `c` bindings at the top of this file for the roles
        # and the measured contrast behind each choice.
        "workbench.colorCustomizations" = {
          # Base
          "foreground" = p.text;
          "descriptionForeground" = dim.onChrome;
          "disabledForeground" = p.muted;
          "focusBorder" = p.accent;
          "errorForeground" = c.brightRed;
          "widget.border" = p.border;
          "widget.shadow" = a p.recessed "99";
          "selection.background" = a p.accent "66";
          "icon.foreground" = p.text;
          "sash.hoverBorder" = p.accent;

          # Editor
          "editor.background" = p.editor;
          "editor.foreground" = p.text;
          "editorLineNumber.foreground" = dim.onEditor;
          "editorLineNumber.activeForeground" = p.accent;
          "editorCursor.foreground" = p.accent;
          "editor.lineHighlightBackground" = a p.raised "80";
          "editor.selectionBackground" = a p.accent "40";
          "editor.selectionHighlightBackground" = a p.accent "26";
          "editor.wordHighlightBackground" = a p.subtle "cc";
          "editor.wordHighlightStrongBackground" = a p.accent "33";
          "editor.findMatchBackground" = a c.yellow "59";
          "editor.findMatchHighlightBackground" = a c.yellow "33";
          "editor.hoverHighlightBackground" = a p.subtle "cc";
          "editor.rangeHighlightBackground" = a p.subtle "80";
          "editorWhitespace.foreground" = p.muted;
          "editorIndentGuide.background1" = p.border;
          "editorIndentGuide.activeBackground1" = p.muted;
          "editorRuler.foreground" = p.border;
          "editorCodeLens.foreground" = p.muted;
          "editorBracketMatch.background" = a p.accent "33";
          "editorBracketMatch.border" = p.accent;
          "editorInlayHint.background" = a p.raised "b3";
          "editorInlayHint.foreground" = p.muted;

          # Diagnostics
          "editorError.foreground" = c.red;
          "editorWarning.foreground" = c.yellow;
          "editorInfo.foreground" = c.blue;
          "editorHint.foreground" = p.muted;
          "editorGutter.background" = p.editor;
          "editorGutter.modifiedBackground" = c.blue;
          "editorGutter.addedBackground" = c.green;
          "editorGutter.deletedBackground" = c.red;
          "editorOverviewRuler.border" = p.border;
          "editorOverviewRuler.errorForeground" = c.red;
          "editorOverviewRuler.warningForeground" = c.yellow;
          "editorOverviewRuler.infoForeground" = c.blue;
          "problemsErrorIcon.foreground" = c.brightRed;
          "problemsWarningIcon.foreground" = c.brightYellow;
          "problemsInfoIcon.foreground" = c.brightBlue;

          # Bracket pair colourisation. Rotating through the muted semantics
          # keeps nested calls readable without turning into confetti.
          "editorBracketHighlight.foreground1" = p.text;
          "editorBracketHighlight.foreground2" = c.blue;
          "editorBracketHighlight.foreground3" = c.magenta;
          "editorBracketHighlight.foreground4" = c.cyan;
          "editorBracketHighlight.foreground5" = c.yellow;
          "editorBracketHighlight.foreground6" = p.accent;
          "editorBracketHighlight.unexpectedBracket.foreground" = c.brightRed;

          # Diffs. Backgrounds only — the text keeps its syntax colour.
          "diffEditor.insertedTextBackground" = a c.green "26";
          "diffEditor.removedTextBackground" = a c.red "26";
          "diffEditor.insertedLineBackground" = a c.green "1a";
          "diffEditor.removedLineBackground" = a c.red "1a";
          "diffEditor.border" = p.border;
          "merge.currentHeaderBackground" = a c.blue "59";
          "merge.incomingHeaderBackground" = a c.green "59";

          # Activity bar and sidebar — the recessed layer
          "activityBar.background" = p.recessed;
          "activityBar.foreground" = p.text;
          "activityBar.inactiveForeground" = dim.tab;
          "activityBar.border" = p.recessed;
          "activityBar.activeBorder" = p.accent;
          "activityBarBadge.background" = p.accent;
          "activityBarBadge.foreground" = p.recessed;
          "sideBar.background" = p.recessed;
          "sideBar.foreground" = p.text;
          "sideBar.border" = p.recessed;
          "sideBarTitle.foreground" = dim.onChrome;
          "sideBarSectionHeader.background" = p.recessed;
          "sideBarSectionHeader.foreground" = dim.onChrome;
          "sideBarSectionHeader.border" = p.border;

          # Tabs. The active tab is lifted to the editor's own colour so it
          # reads as physically continuous with the surface below it.
          "editorGroupHeader.tabsBackground" = p.recessed;
          "editorGroupHeader.noTabsBackground" = p.recessed;
          "editorGroup.border" = p.border;
          "tab.activeBackground" = p.editor;
          "tab.activeForeground" = p.text;
          "tab.activeBorderTop" = p.accent;
          "tab.inactiveBackground" = p.recessed;
          "tab.inactiveForeground" = dim.tab;
          "tab.border" = p.recessed;
          "tab.hoverBackground" = p.raised;
          "tab.unfocusedActiveBackground" = p.raised;

          # Panel and terminal
          "panel.background" = p.raised;
          "panel.border" = p.border;
          "panelTitle.activeForeground" = p.text;
          "panelTitle.activeBorder" = p.accent;
          "panelTitle.inactiveForeground" = dim.tab;
          "terminal.background" = p.raised;
          "terminal.foreground" = p.text;
          "terminalCursor.foreground" = p.accent;
          "terminal.selectionBackground" = a p.accent "40";
          "terminal.ansiBlack" = p.raised;
          "terminal.ansiRed" = c.red;
          "terminal.ansiGreen" = c.green;
          "terminal.ansiYellow" = c.yellow;
          "terminal.ansiBlue" = c.blue;
          "terminal.ansiMagenta" = c.magenta;
          "terminal.ansiCyan" = c.cyan;
          "terminal.ansiWhite" = p.text;
          "terminal.ansiBrightBlack" = p.border;
          "terminal.ansiBrightRed" = c.brightRed;
          "terminal.ansiBrightGreen" = c.brightGreen;
          "terminal.ansiBrightYellow" = c.brightYellow;
          "terminal.ansiBrightBlue" = c.brightBlue;
          "terminal.ansiBrightMagenta" = c.brightMagenta;
          "terminal.ansiBrightCyan" = c.brightCyan;
          "terminal.ansiBrightWhite" = c.brightWhite;

          # Status bar. The debugging and no-folder states get the same
          # treatment as the normal one — VSCode's stock orange and purple
          # would be the only saturated things on screen.
          "statusBar.background" = p.recessed;
          "statusBar.foreground" = dim.onChrome;
          "statusBar.border" = p.border;
          "statusBar.debuggingBackground" = p.accent;
          "statusBar.debuggingForeground" = p.recessed;
          "statusBar.noFolderBackground" = p.recessed;
          "statusBarItem.remoteBackground" = p.subtle;
          "statusBarItem.remoteForeground" = p.text;
          "statusBarItem.errorBackground" = a c.red "00";
          "statusBarItem.errorForeground" = c.brightRed;
          "statusBarItem.warningBackground" = a c.yellow "00";
          "statusBarItem.warningForeground" = c.brightYellow;
          "statusBarItem.hoverBackground" = a p.text "14";

          # Title bar and menus
          "titleBar.activeBackground" = p.recessed;
          "titleBar.activeForeground" = p.text;
          "titleBar.inactiveBackground" = p.recessed;
          "titleBar.inactiveForeground" = p.muted;
          "titleBar.border" = p.border;
          "menu.background" = p.raised;
          "menu.foreground" = p.text;
          "menu.border" = p.border;
          "menu.selectionBackground" = p.subtle;
          "menu.selectionForeground" = p.text;
          "menubar.selectionBackground" = p.subtle;

          # Lists and trees
          "list.activeSelectionBackground" = p.subtle;
          "list.activeSelectionForeground" = p.text;
          "list.inactiveSelectionBackground" = a p.subtle "b3";
          "list.hoverBackground" = a p.text "0f";
          "list.highlightForeground" = p.accent;
          "list.focusOutline" = p.accent;
          "list.errorForeground" = c.brightRed;
          "list.warningForeground" = c.brightYellow;
          "tree.indentGuidesStroke" = p.border;

          # Git decorations in the explorer
          "gitDecoration.addedResourceForeground" = c.green;
          "gitDecoration.modifiedResourceForeground" = c.blue;
          "gitDecoration.deletedResourceForeground" = c.red;
          "gitDecoration.untrackedResourceForeground" = c.cyan;
          "gitDecoration.ignoredResourceForeground" = p.muted;
          "gitDecoration.conflictingResourceForeground" = c.magenta;
          "gitDecoration.stageModifiedResourceForeground" = c.brightBlue;

          # Inputs, dropdowns, buttons, badges
          "input.background" = p.raised;
          "input.foreground" = p.text;
          "input.border" = p.border;
          "input.placeholderForeground" = dim.onEditor;
          "inputOption.activeBorder" = p.accent;
          "inputValidation.errorBackground" = p.raised;
          "inputValidation.errorBorder" = c.red;
          "dropdown.background" = p.raised;
          "dropdown.foreground" = p.text;
          "dropdown.border" = p.border;
          "button.background" = p.accent;
          "button.foreground" = p.recessed;
          "button.hoverBackground" = c.brightRed;
          "button.secondaryBackground" = p.subtle;
          "button.secondaryForeground" = p.text;
          "badge.background" = p.accent;
          "badge.foreground" = p.recessed;
          "progressBar.background" = p.accent;
          "textLink.foreground" = p.accent;
          "textLink.activeForeground" = c.brightRed;

          # Peek, quick input, notifications
          "quickInput.background" = p.raised;
          "quickInputList.focusBackground" = p.subtle;
          "editorWidget.background" = p.raised;
          "editorWidget.border" = p.border;
          "editorSuggestWidget.background" = p.raised;
          "editorSuggestWidget.selectedBackground" = p.subtle;
          "editorSuggestWidget.highlightForeground" = p.accent;
          "editorHoverWidget.background" = p.raised;
          "editorHoverWidget.border" = p.border;
          "peekViewEditor.background" = p.editor;
          "peekViewResult.background" = p.raised;
          "peekViewTitle.background" = p.raised;
          "peekView.border" = p.accent;
          "notifications.background" = p.raised;
          "notifications.border" = p.border;
          "notificationCenterHeader.background" = p.recessed;

          # Scrollbars and minimap
          "scrollbar.shadow" = a p.recessed "99";
          "scrollbarSlider.background" = a p.border "99";
          "scrollbarSlider.hoverBackground" = a p.muted "cc";
          "scrollbarSlider.activeBackground" = p.accent;
          "minimap.background" = p.editor;
          "minimap.findMatchHighlight" = c.yellow;
          "minimap.errorHighlight" = c.red;
          "minimap.warningHighlight" = c.yellow;
          "minimapSlider.background" = a p.border "66";
          "minimapSlider.hoverBackground" = a p.muted "80";
          "minimapGutter.addedBackground" = c.green;
          "minimapGutter.modifiedBackground" = c.blue;
          "minimapGutter.deletedBackground" = c.red;
        };

        # ── Syntax ───────────────────────────────────────────────────────
        # Emphasis, not hue. With a palette this narrow, colouring twelve token
        # classes would mean twelve indistinguishable muted greys, so the
        # hierarchy is carried by weight and dimming instead: structure recedes
        # to `muted`, ordinary code sits at `text`, and keywords step forward in
        # the accent.
        #
        # Strings and numbers are the deliberate exception — they are the two
        # classes where losing hue genuinely costs reading speed, since both are
        # about spotting a literal in a line of identifiers. Delete those two
        # rules for a strictly monochrome theme.
        "editor.tokenColorCustomizations" = {
          textMateRules = [
            {
              scope = [ "comment" "punctuation.definition.comment" ];
              settings = {
                foreground = dim.onEditor;
                fontStyle = "italic";
              };
            }
            {
              scope = [ "punctuation" "meta.brace" "keyword.operator" ];
              settings.foreground = dim.onEditor;
            }
            {
              scope = [ "variable" "meta.definition.variable.name" "support.variable" ];
              settings.foreground = p.text;
            }
            {
              scope = [ "keyword" "storage" "storage.type" "keyword.control" "variable.language" ];
              settings = {
                foreground = p.accent;
                fontStyle = "bold";
              };
            }
            {
              scope = [ "entity.name.function" "support.function" "meta.function-call" ];
              settings.foreground = p.text;
            }
            {
              scope = [ "entity.name.type" "entity.name.class" "support.type" "support.class" ];
              settings = {
                foreground = p.text;
                fontStyle = "italic";
              };
            }
            {
              scope = [ "string" "string.quoted" "punctuation.definition.string" ];
              settings.foreground = c.green;
            }
            {
              scope = [ "constant.numeric" "constant.language" "constant.character" ];
              settings.foreground = c.yellow;
            }
            {
              scope = [ "invalid" "invalid.illegal" ];
              settings.foreground = c.brightRed;
            }
          ];
        };

        # Semantic tokens ship real type information, which is strictly better
        # than TextMate's regex guesses — but they would repaint everything the
        # base theme's way. Keeping them on with the rules above unset means the
        # emphasis model holds while modifiers like `readonly` still register.
        "editor.semanticHighlighting.enabled" = true;
      };
    };
  };
}
