# Shared LazyVim preferences: pinned NixOS tools or native Lazy/Mason installation.
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
  bin = package: command: if isNixOS then "${package}/bin/${command}" else command;
  extras = [
    "dap.core"
    "test.core"
    "lang.nix"
    "lang.clangd"
    "lang.go"
    "lang.rust"
    "lang.typescript"
    "lang.python"
    "lang.markdown"
    "lang.json"
    "lang.yaml"
    "lang.toml"
    "lang.docker"
    "lang.git"
    "formatting.prettier"
    "linting.eslint"
    (if isNixOS then "ai.copilot-native" else "ai.copilot")
    "coding.mini-surround"
    "coding.yanky"
  ];
  extrasLua = lib.concatMapStringsSep "\n" (
    name: ''{ import = "lazyvim.plugins.extras.${name}" },''
  ) extras;
  # Use the pinned npm distribution of the Copilot language server.
  copilotLanguageServer = pkgs.copilot-language-server.overrideAttrs (_: {
    version = "1.495.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@github/copilot-language-server/-/copilot-language-server-1.495.0.tgz";
      hash = "sha256-qHxuXCI9eI19A3yjLz4uJkTsKi+3zA5yaSQoQ/jMAvQ=";
    };
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/copilot-language-server" "$out/bin"
      cp -r dist/. "$out/share/copilot-language-server/"
      makeWrapper ${lib.getExe pkgs.nodejs} "$out/bin/copilot-language-server" \
        --add-flags "$out/share/copilot-language-server/language-server.js"
      runHook postInstall
    '';
  });

  # Share clangd arguments with VSCodium.
  clangdArgs = lib.generators.toLua { } (toolchain.clangdArgs config.home.homeDirectory);

  # PlatformIO plugin pin; not packaged in the locked nixpkgs.
  nvim-platformio = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-platformio.lua";
    version = "0-unstable-2026-05-12";
    src = pkgs.fetchFromGitHub {
      owner = "anurag3301";
      repo = "nvim-platformio.lua";
      rev = "e65fd65565da5c1d98c568bd0cdcad16627cdb14";
      hash = "sha256-vIO+Un5BAzVU6JmHueSSRGujaTZcjfVBvh+sq/7CLgk=";
    };
    # Declare dependencies for nixpkgs plugin checks.
    dependencies = with pkgs.vimPlugins; [
      toggleterm-nvim
      plenary-nvim
      which-key-nvim
    ];
    # Plugin checks and runtime both require pio and an external which binary.
    nativeBuildInputs = [
      pkgs.platformio-core
      pkgs.which
    ];
    nvimSkipModules = [
      # Use vim.ui.select through Snacks; Telescope is not installed.
      "platformio.pickers.telescope"
      # Skip the standalone reproduction script that calls lazy.setup.
      "minimal_config"
    ];
  };

  # Plugins required by the enabled LazyVim extras.
  plugins = with pkgs.vimPlugins; [
    # LazyVim core
    LazyVim
    base16-nvim
    bufferline-nvim
    conform-nvim
    flash-nvim
    gitsigns-nvim
    grug-far-nvim
    lazydev-nvim
    lualine-nvim
    mini-ai
    mini-icons
    mini-pairs
    mini-surround
    noice-nvim
    nui-nvim
    nvim-lint
    nvim-lspconfig
    nvim-treesitter
    nvim-treesitter-textobjects
    nvim-ts-autotag
    persistence-nvim
    plenary-nvim
    snacks-nvim
    todo-comments-nvim
    trouble-nvim
    ts-comments-nvim
    which-key-nvim
    yanky-nvim
    diffview-nvim
    opencode-nvim

    # Defaults picked by vim.g.lazyvim_{picker,cmp,explorer} below
    blink-cmp
    blink-compat
    friendly-snippets
    nvim-cmp # blink.compat shim + the cmp-git source want it on disk

    # Language extras
    SchemaStore-nvim # json, yaml
    clangd_extensions-nvim # clangd
    cmp-git # git
    crates-nvim # rust
    markdown-preview-nvim # markdown
    render-markdown-nvim # markdown
    rustaceanvim # rust
    venv-selector-nvim # python

    # Debugging and tests
    nvim-dap
    nvim-dap-ui
    nvim-dap-virtual-text
    nvim-nio
    nvim-dap-python
    nvim-dap-go
    neotest
    neotest-python
    neotest-golang

    # Notebooks (see lua/plugins/jupyter.lua below)
    image-nvim
    jupytext-nvim
    molten-nvim
    otter-nvim
    quarto-nvim

    # PlatformIO
    nvim-platformio
    toggleterm-nvim

    # Plugin names match the repository names used by lazy.nvim.
  ];

  mkEntryFromDrv =
    drv:
    if lib.isDerivation drv then
      {
        name = lib.getName drv;
        path = drv;
      }
    else
      drv;

  lazyPath = pkgs.linkFarm "lazy-plugins" (map mkEntryFromDrv plugins);

  # LazyVim checks install_dir for parsers; expose the pinned grammars there.
  tsGrammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
    # LazyVim's default ensure_installed
    bash
    c
    diff
    html
    javascript
    jsdoc
    json
    lua
    luadoc
    luap
    markdown
    markdown_inline
    printf
    python
    query
    regex
    toml
    tsx
    typescript
    vim
    vimdoc
    xml
    yaml
    # the extras enabled below, collected from their own ensure_installed
    # lists. objcpp is the one they ask for that nixpkgs has no grammar for.
    cmake
    cpp
    dockerfile
    gitattributes
    git_config
    gitcommit
    gitignore
    git_rebase
    go
    gomod
    gosum
    gowork
    json5
    make
    ninja
    nix
    objc
    rst
    ron
    rust
  ];

  tsInstallDir = pkgs.runCommand "nvim-treesitter-install-dir" { } ''
    mkdir -p $out/parser $out/queries
    ${lib.concatMapStringsSep "\n" (g: "ln -s ${g}/parser/*.so $out/parser/") tsGrammars}
    ln -s ${pkgs.vimPlugins.nvim-treesitter}/runtime/queries/* $out/queries/
  '';
in
{
  imports = [ ./notebooks.nix ];

  programs.neovim = lib.mkIf isNixOS {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Load the remaining plugins on demand through lazyPath.
    plugins = [ pkgs.vimPlugins.lazy-nvim ];

    # Nix provides the shared toolchain and Neovim-specific runtime dependencies.
    extraPackages =
      toolchain.languageServers
      ++ toolchain.runtimes
      ++ [
        (import ../../pkgs/editor-tools.nix { inherit pkgs; }).notebookKernel
        toolchain.debugAdapters.python
        toolchain.debugAdapters.lldb
      ]
      ++ (with pkgs; [
        # nvim-platformio invokes which pio at runtime.
        platformio-core
        which
        # Used by plugins rather than by a language: tree-sitter for :checkhealth,
        # make/wget for build steps that survive in a few specs.
        tree-sitter
        gnumake
        wget
        # LazyVim's native Copilot extra uses Neovim 0.12 inline LSP completion.
        copilotLanguageServer
        opencode
        curl
        lsof
        procps
        fd
        ripgrep
        git
      ]);

    initLua = ''
      -- Set leaders before LazyVim creates its mappings.
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      -- Keep LazyVim metadata in writable data, outside the generated configuration.
      vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

      -- Choose defaults independently of saved LazyVim metadata.
      vim.g.lazyvim_picker = "snacks"
      vim.g.lazyvim_cmp = "blink.cmp"
      vim.g.lazyvim_explorer = "snacks"

      -- Both editors use basedpyright.
      vim.g.lazyvim_python_lsp = "basedpyright"

      require("lazy").setup({
        defaults = { lazy = true },

        dev = {
          path = "${lazyPath}",
          patterns = { "" }, -- match every plugin, not a subset
          fallback = false,  -- never clone; surface the gap instead
        },

        -- Updates and plugin installation are handled by Nix.
        install = { missing = false },
        checker = { enabled = false },
        change_detection = { enabled = false },

        -- The magick rock is provided by extraLuaPackages; disable runtime builds.
        rocks = { enabled = false, hererocks = false },

        -- Keep lazy.nvim's default rtp reset so the HM-installed loader is discoverable.

        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "habamax" } },
          { "folke/tokyonight.nvim", enabled = false },
          { "catppuccin/nvim", name = "catppuccin", enabled = false },

          -- Enable extras declaratively; add their dependencies to the package lists.
          ${extrasLua}

          { import = "plugins" },

          -- Disable runtime tool installers.
          { "mason-org/mason.nvim", enabled = false },
          { "mason-org/mason-lspconfig.nvim", enabled = false },
          { "jay-babu/mason-nvim-dap.nvim", enabled = false },

          -- Clear merged install requests after all extras; parsers are immutable.
          {
            "nvim-treesitter/nvim-treesitter",
            build = false,
            opts = function(_, opts)
              opts.ensure_installed = {}
              opts.install_dir = "${tsInstallDir}"
              return opts
            end,
          },
        },
      })
    '';
  };

  xdg.configFile."nvim/init.lua" = lib.mkIf (!isNixOS) {
    text = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"
      vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"
      vim.g.lazyvim_picker = "snacks"
      vim.g.lazyvim_cmp = "blink.cmp"
      vim.g.lazyvim_explorer = "snacks"
      vim.g.lazyvim_python_lsp = "basedpyright"
      vim.g.python3_host_prog = ${
        lib.generators.toLua { } "${config.xdg.dataHome}/editor-python/bin/python"
      }
      vim.env.PATH = vim.fn.fnamemodify(vim.g.python3_host_prog, ":h") .. ":" .. vim.env.PATH
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.uv.fs_stat(lazypath) then
        local output = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
          "https://github.com/folke/lazy.nvim.git", lazypath })
        if vim.v.shell_error ~= 0 then error(output) end
      end
      vim.opt.rtp:prepend(lazypath)
      require("lazy").setup({
        lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
        defaults = { lazy = true },
        checker = { enabled = false },
        rocks = { enabled = false },
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "habamax" } },
          ${extrasLua}
          { import = "plugins" },
        },
      })
    '';
  };

  # Home Manager links configuration files; editor data remains writable.
  xdg.configFile."nvim/lua/config/options.lua".text = ''
    -- Loaded after lazyvim.config.options, so this only needs the deltas.
    local opt = vim.opt

    opt.scrolloff = 8
    opt.inccommand = "split"

    -- Put project tools and the OpenCode terminal at the actual project root,
    -- including non-Git PlatformIO and language projects.
    vim.g.root_spec = {
      "lsp",
      { ".git", "lua", "platformio.ini", "flake.nix", "pyproject.toml", "go.mod", "Cargo.toml", "package.json" },
      "cwd",
    }

    -- Nix builds fail on trailing whitespace often enough to want it visible.
    opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
  '';

  xdg.configFile."nvim/lua/plugins/workflow.lua".text = ''
    return {
      {
        "nickjvandyke/opencode.nvim",
        cmd = "OpenCode",
        keys = {
          { "<leader>ao", function() require("opencode").toggle() end, desc = "OpenCode: toggle" },
          { "<leader>aa", function() require("opencode").ask("@this: ", { submit = true }) end,
            mode = { "n", "x" }, desc = "OpenCode: ask with context" },
          { "<leader>as", function() require("opencode").select() end,
            mode = { "n", "x" }, desc = "OpenCode: actions" },
        },
        config = function()
          vim.o.autoread = true
          local command = { "${bin pkgs.opencode "opencode"}", "--port", "0" }
          local function terminal_opts()
            return {
              cwd = LazyVim.root(),
              win = {
                position = "right",
                width = 0.45,
                on_win = function(win) require("opencode.terminal").setup(win.win) end,
              },
            }
          end
          local opts = require("opencode.config").opts
          opts.server = vim.tbl_deep_extend("force", opts.server, {
            start = function() Snacks.terminal.open(command, terminal_opts()) end,
            stop = function()
              local options = terminal_opts()
              options.create = false
              local terminal = Snacks.terminal.get(command, options)
              if terminal then terminal:close() end
            end,
            toggle = function() Snacks.terminal.toggle(command, terminal_opts()) end,
          })
          vim.api.nvim_create_user_command("OpenCode", function() require("opencode").toggle() end,
            { desc = "Toggle OpenCode at the project root" })
        end,
      },
      {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        opts = {},
        keys = {
          { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Git: review changes" },
          { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: file history" },
          { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Git: close diff review" },
        },
      },
    }
  '';

  xdg.configFile."nvim/lua/config/autocmds.lua".text = ''
    -- Loaded after lazyvim.config.autocmds.

    -- Nix files in this repo are two-space indented; the treesitter indent
    -- module gets this right but the filetype plugin can still stomp on it.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("oad_nix_indent", { clear = true }),
      pattern = "nix",
      callback = function()
        vim.bo.shiftwidth = 2
        vim.bo.expandtab = true
      end,
    })
  '';

  xdg.configFile."nvim/lua/plugins/noctalia.lua".enable = desktopEnabled;
  xdg.configFile."nvim/lua/plugins/noctalia.lua".text = ''
    local path = ${lib.generators.toLua { } "${config.xdg.stateHome}/noctalia/theme/nvim.lua"}
    local last_stamp

    local function apply(force)
      local stat = vim.uv.fs_stat(path)
      -- Nanoseconds and inode also detect rapid updates and atomic replacement.
      local stamp = stat and table.concat({ stat.mtime.sec, stat.mtime.nsec, stat.size, stat.ino }, ":") or "missing"
      if not force and stamp == last_stamp then
        return
      end
      local ok, err = pcall(function()
        if not stat then
          vim.cmd.colorscheme("habamax")
          return
        end
        local chunk = assert(loadfile(path))
        -- The pinned template returns setup(), but also registers SIGUSR1 and
        -- re-requires "matugen". Isolate its globals and suppress that handler;
        -- focus checks below own reloads without signalling other instances.
        local uv = setmetatable({ new_signal = function()
          return { start = function() end }
        end }, { __index = vim.uv })
        local env = setmetatable({
          vim = setmetatable({ uv = uv }, { __index = vim }),
          _G = {},
        }, { __index = _G })
        setfenv(chunk, env)
        chunk().setup()
      end)
      if ok then
        last_stamp = stamp
      else
        vim.notify("Noctalia theme: " .. tostring(err), vim.log.levels.WARN)
        if not last_stamp then
          vim.cmd.colorscheme("habamax")
        end
      end
    end

    return {
      { "RRethy/base16-nvim", lazy = false, priority = 1000 },
      {
        "LazyVim/LazyVim",
        opts = {
          colorscheme = function()
            apply(true)
            vim.api.nvim_create_autocmd("FocusGained", {
              group = vim.api.nvim_create_augroup("oad_noctalia_theme", { clear = true }),
              callback = function() apply(false) end,
            })
          end,
        },
      },
    }
  '';

  xdg.configFile."nvim/lua/plugins/overrides.lua".text = ''
    -- LazyVim ships no bash extra, so bashls and shfmt are wired by hand. The
    -- binaries come from programs.neovim.extraPackages.
    return {
      {
        "neovim/nvim-lspconfig",
        keys = {
          { "<leader>uv", function()
            vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
          end, desc = "Toggle inline diagnostics" },
        },
        opts = {
          -- Keep signs/underlines; show full messages with <leader>cd or <leader>xx.
          diagnostics = {
            virtual_text = false,
            virtual_lines = false,
            update_in_insert = false,
            float = { border = "rounded", source = "if_many" },
          },
          setup = {
            -- Skip the legacy semantic-token workaround; current gopls advertises support.
            gopls = function() end,
          },
          servers = {
            bashls = {},
            gopls = {
              settings = { gopls = ${lib.generators.toLua { } toolchain.goplsSettings} },
            },
            basedpyright = {
              settings = {
                basedpyright = {
                  disableOrganizeImports = true,
                  analysis = ${lib.generators.toLua { } toolchain.pythonAnalysis},
                },
              },
            },
            -- Ruff owns import actions; ordinary sessions do not need protocol tracing.
            ruff = { cmd_env = { RUFF_TRACE = "off" } },
            nil_ls = { enabled = false },
            -- nixd needs to be told where the flake is to offer completion on
            -- options rather than just on syntax.
            nixd = {
              settings = {
                nixd = ${
                  lib.generators.toLua { } (toolchain.nixdSettings { inherit profile isNixOS; })
                },
              },
            },
          },
        },
      },
      {
        "stevearc/conform.nvim",
        opts = {
          formatters_by_ft = {
            sh = { "shfmt" },
            bash = { "shfmt" },
            python = { "ruff_organize_imports", "ruff_format" },
          },
        },
      },
      {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
          -- gopls runs Staticcheck; golangci-lint stays an explicit project command.
          opts.linters_by_ft.go = {}
        end,
      },
      {
        "saghen/blink.cmp",
        opts = { fuzzy = { prebuilt_binaries = { download = false } } },
      },
      {
        "iamcco/markdown-preview.nvim",
        build = ${if isNixOS then "false" else ''function() vim.fn["mkdp#util#install"]() end''},
      },
      {
        -- Use the pinned server directly to avoid rustup shim recursion.
        "mrcjkb/rustaceanvim",
        opts = {
          server = {
            cmd = { "${bin pkgs.rust-analyzer "rust-analyzer"}" },
            default_settings = {
              ["rust-analyzer"] = ${lib.generators.toLua { } toolchain.rustAnalyzerSettings},
            },
          },
        },
      },
    }
  '';

  xdg.configFile."nvim/lua/plugins/debugging.lua".text = ''
    return {
      {
        "mfussenegger/nvim-dap",
        dependencies = { "mfussenegger/nvim-dap-python", "leoluz/nvim-dap-go" },
        opts = function()
          local dap = require("dap")
          dap.adapters.debugpy = dap.adapters.python
          dap.adapters.lldb = dap.adapters.codelldb
          local vscode = require("dap.ext.vscode")
          vscode.type_to_filetypes.debugpy = { "python" }
          vscode.type_to_filetypes.lldb = { "c", "cpp", "rust" }
        end,
      },
      {
        "mfussenegger/nvim-dap-python",
        config = function()
          require("dap-python").setup("${
            if isNixOS then
              "${toolchain.debugAdapters.python}/bin/python3"
            else
              "${config.xdg.dataHome}/editor-python/bin/python"
          }")
        end,
      },
      {
        "leoluz/nvim-dap-go",
        opts = { delve = { path = "${bin pkgs.delve "dlv"}" } },
      },
      ${lib.optionalString isNixOS ''
        {
          "mrcjkb/rustaceanvim",
          opts = function(_, opts)
            opts.dap = {
              adapter = require("rustaceanvim.config").get_codelldb_adapter(
                "${toolchain.debugAdapters.lldb}/bin/codelldb",
                "${toolchain.debugAdapters.lldb}/share/lldb/lib/liblldb.so"
              ),
            }
          end,
        },
      ''}
      {
        "nvim-neotest/neotest",
        opts = {
          discovery = { concurrent = 2 },
          output = { open_on_run = false },
        },
      },
    }
  '';

  xdg.configFile."nvim/lua/plugins/platformio.lua".text = ''
    -- PlatformIO build/upload/monitor commands use toggleterm.
    -- :PioLSP generates the shared compilation database; host rules are in system/development.nix.
    return {
      {
        "anurag3301/nvim-platformio.lua",
        -- Register every command so lazy loading works on the first invocation.
        cmd = {
          "Pioinit",
          "PioLSP",
          "Piorun",
          "Piomon",
          "Piolsserial",
          "Piolib",
          "Piocmdh",
          "Piocmdf",
          "Piodebug",
          "PioTermList",
        },
        dependencies = { "akinsho/toggleterm.nvim" },
        -- Use the real PlatformIO compilation database in both editors.
        -- GCC-only flags are removed by the shared clangd configuration.
        opts = {
          lsp = "clangd",
          clangd_source = "compiledb",
        },
      },
      { "akinsho/toggleterm.nvim", opts = {} },
      {
        -- Use shared cross-compiler arguments for framework and system headers.
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
          local clangd = opts.servers and opts.servers.clangd
          if not clangd then
            return
          end
          clangd.cmd = vim.list_extend({ "${bin pkgs.clang-tools "clangd"}" }, ${clangdArgs})
        end,
      },
    }
  '';
}
