# LazyVim, with every plugin coming from nixpkgs instead of being cloned at
# runtime.
#
# lazy.nvim still runs and still resolves LazyVim's plugin specs, but its `dev`
# path points at a linkFarm of `pkgs.vimPlugins.*` below. `dev.patterns = { "" }`
# makes every plugin match the dev rule, so lazy looks each one up in the store
# instead of on GitHub, and `dev.fallback = false` turns a plugin we forgot to
# list into a visible "not installed" entry in `:Lazy` rather than a silent
# background clone. Pattern is from LazyVim discussion #1972.
#
# The trade-off, stated plainly: `:Lazy update` and `:LazyExtras` no longer
# change anything. Plugins move when nixpkgs moves, and enabling an extra means
# editing the `spec` and `plugins` lists in this file.
{
  pkgs,
  lib,
  config,
  profile,
  isNixOS,
  ...
}:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };

  # Rendered into the Lua below. Same flags VSCodium passes — see
  # ./toolchain.nix for what --query-driver buys and ./clangd.nix for the
  # editor-independent half.
  clangdArgs = lib.generators.toLua { } (toolchain.clangdArgs config.home.homeDirectory);

  # Not in nixpkgs, so it is pinned by hand. This is the only plugin here not
  # coming from the flake's nixpkgs.
  nvim-platformio = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-platformio.lua";
    version = "0-unstable-2026-05-12";
    src = pkgs.fetchFromGitHub {
      owner = "anurag3301";
      repo = "nvim-platformio.lua";
      rev = "e65fd65565da5c1d98c568bd0cdcad16627cdb14";
      hash = "sha256-vIO+Un5BAzVU6JmHueSSRGujaTZcjfVBvh+sq/7CLgk=";
    };
    # nixpkgs' require-check hook loads every lua module with only these on the
    # path, so the plugin's own runtime deps have to be named.
    dependencies = with pkgs.vimPlugins; [
      toggleterm-nvim
      plenary-nvim
      which-key-nvim
    ];
    # plugin/platformio.lua bails out with "Platformio not found in the path"
    # when `pio` is absent, and the check sources it before every require, so
    # without this every module in the plugin fails. It probes with
    # `io.popen("which pio")`, so the `which` binary has to be there too — a
    # shell builtin will not do. Both are in extraPackages below for runtime.
    nativeBuildInputs = [
      pkgs.platformio-core
      pkgs.which
    ];
    nvimSkipModules = [
      # One of two picker backends; the other is vim.ui.select, which snacks
      # provides. Telescope is not installed, so skip the module rather than
      # pull in a picker we do not use.
      "platformio.pickers.telescope"
      # A bug-report reproduction script at the repo root, not plugin code. It
      # calls lazy.setup itself, which the check has no business running.
      "minimal_config"
    ];
  };

  # Everything lazy.nvim is allowed to load. Derived by grepping the plugin
  # specs in pkgs.vimPlugins.LazyVim for "owner/repo" strings, so it tracks
  # what LazyVim 15.15 actually references rather than what a blog post said.
  plugins = with pkgs.vimPlugins; [
    # ── LazyVim core ─────────────────────────────────────────────────────
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

    # ── Defaults picked by vim.g.lazyvim_{picker,cmp,explorer} below ─────
    blink-cmp
    blink-compat
    friendly-snippets
    nvim-cmp # blink.compat shim + the cmp-git source want it on disk

    # ── Language extras ──────────────────────────────────────────────────
    SchemaStore-nvim # json, yaml
    clangd_extensions-nvim # clangd
    cmp-git # git
    crates-nvim # rust
    markdown-preview-nvim # markdown
    render-markdown-nvim # markdown
    rustaceanvim # rust
    venv-selector-nvim # python

    # Pulled in by the extras as `optional = true`, so they sit unused until
    # dap.core / test.core are enabled. Listing them now means turning those
    # on later is a one-line change instead of a debugging session.
    neotest
    neotest-golang
    neotest-python
    nvim-dap
    nvim-dap-go
    nvim-dap-python
    nvim-nio

    # ── Notebooks (see lua/plugins/jupyter.lua below) ─────────────────────
    image-nvim
    jupytext-nvim
    molten-nvim
    otter-nvim

    # ── PlatformIO ───────────────────────────────────────────────────────
    nvim-platformio
    toggleterm-nvim

    # lazy.nvim derives a plugin's name from the last path segment of its
    # repo, and matches that against the linkFarm entry names. `lib.getName`
    # returns nixpkgs' `pname`, which already equals that segment for every
    # plugin above ("snacks.nvim", "blink.cmp", "mini.ai", ...).
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

  # nvim-treesitter's `main` branch — which LazyVim 15 requires and nixpkgs now
  # ships — does not bundle grammars. nixpkgs exposes them as one plugin per
  # language under `grammarPlugins`, each containing only `parser/<lang>.so`,
  # while the queries stay in the main plugin under `runtime/queries`.
  #
  # Neither `withAllGrammars` nor `withPlugins` does anything anymore: both
  # return the base plugin unchanged. And putting the grammars on the
  # runtimepath is not enough either, because LazyVim gates highlighting on
  # `nvim-treesitter.get_installed("parsers")`, which reads `install_dir/parser`
  # and ignores the runtimepath entirely. So: build the directory it wants.
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
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Molten's remote plugin requires these imports when registering and running.
    withPython3 = true;
    extraPython3Packages =
      ps: with ps; [
        pynvim
        jupyter-client
        ipykernel
        jupytext
        nbformat
        cairosvg
        pnglatex
        plotly
        pillow
        requests
        websocket-client
      ];

    # image.nvim binds to ImageMagick through this rock. Supplying it here is
    # what lets lazy's rockspec build be turned off entirely.
    extraLuaPackages = ps: [ ps.magick ];

    # Only the loader goes on the runtimepath. Everything else is reached
    # through lazyPath, so lazy.nvim stays in charge of load order and
    # lazy-loading rather than having 60 plugins sourced at startup.
    plugins = [ pkgs.vimPlugins.lazy-nvim ];

    # Mason is disabled in the spec below, so every binary LazyVim would have
    # asked Mason for is listed here instead. The servers, formatters and
    # linters are the shared set from ./toolchain.nix — which language gets
    # which tool, and why, is documented there. Only the entries LazyVim needs
    # and the other editors do not are listed below.
    extraPackages =
      toolchain.languageServers
      ++ (with pkgs; [
        # Molten uses the Python provider; jupytext.nvim shells out for conversion.
        python3Packages.jupytext
        # The quarto CLI was here for .qmd rendering and pulled in R,
        # gfortran, BLAS/LAPACK and a JVM for a 2.76 GiB closure — put it back
        # only if you actually start writing Quarto documents.

        # Embedded. nvim-platformio probes for the toolchain with
        # `io.popen("which pio")`, so `which` has to be a real binary on the
        # wrapper's PATH — NixOS does not install one by default and the zsh
        # builtin is not visible to io.popen's /bin/sh.
        platformio-core
        which
        # Used by plugins rather than by a language: tree-sitter for :checkhealth,
        # make/wget for build steps that survive in a few specs.
        tree-sitter
        gnumake
        wget
      ]);

    initLua = ''
      -- Must be set before lazy.setup, or LazyVim's <leader> maps land on the
      -- wrong key.
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      -- LazyVim writes this file when it migrates or when :LazyExtras toggles
      -- something. ~/.config/nvim/lua is a read-only store symlink, so point it
      -- at the data dir, which is writable. The write is wrapped in a guarded
      -- io.open upstream, so leaving it would fail silently instead of loudly —
      -- worse.
      vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

      -- LazyVim picks these three by probing for a lazyvim.json on first run.
      -- Pinning them makes the resolved plugin set a property of this file
      -- rather than of whatever state the data dir happens to be in.
      vim.g.lazyvim_picker = "snacks"
      vim.g.lazyvim_cmp = "blink.cmp"
      vim.g.lazyvim_explorer = "snacks"

      -- The python extra defaults to pyright. basedpyright is the maintained
      -- fork, is what extraPackages installs, and is a drop-in replacement.
      vim.g.lazyvim_python_lsp = "basedpyright"

      require("lazy").setup({
        defaults = { lazy = true },

        dev = {
          path = "${lazyPath}",
          patterns = { "" }, -- match every plugin, not a subset
          fallback = false,  -- never clone; surface the gap instead
        },

        -- The store is the source of truth: nothing to install, nothing to
        -- check for updates, nothing to watch for changes.
        install = { missing = false },
        checker = { enabled = false },
        change_detection = { enabled = false },

        -- image.nvim declares `build = "rockspec"` because it needs the magick
        -- luarock. lazy's answer to that is to download and compile hererocks
        -- on first start; ours is extraLuaPackages below, which puts the same
        -- rock on the lua path from nixpkgs. `hererocks = false` is the part
        -- that matters — lazy injects the hererocks plugin off that flag alone
        -- and does not consult `enabled` first.
        rocks = { enabled = false, hererocks = false },

        -- performance.rtp.reset is left at its default of true, and it has to
        -- be. home-manager delivers lazy.nvim through packpath rather than the
        -- runtimepath, so lazy's directory is only reachable via packpath
        -- expansion. Its own module loader indexes the runtimepath string, and
        -- with reset disabled it cannot find lazy.pkg.* and startup dies. The
        -- reset puts lazy's own path on the rtp explicitly, which fixes it.

        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },

          -- :LazyExtras cannot persist a choice against a read-only config, so
          -- extras are imported here instead. Adding one means adding its
          -- plugins to `plugins` and its binaries to `extraPackages` too.
          { import = "lazyvim.plugins.extras.lang.nix" },
          { import = "lazyvim.plugins.extras.lang.clangd" },
          { import = "lazyvim.plugins.extras.lang.go" },
          { import = "lazyvim.plugins.extras.lang.rust" },
          { import = "lazyvim.plugins.extras.lang.typescript" },
          { import = "lazyvim.plugins.extras.lang.python" },
          { import = "lazyvim.plugins.extras.lang.markdown" },
          { import = "lazyvim.plugins.extras.lang.json" },
          { import = "lazyvim.plugins.extras.lang.yaml" },
          { import = "lazyvim.plugins.extras.lang.toml" },
          { import = "lazyvim.plugins.extras.lang.docker" },
          { import = "lazyvim.plugins.extras.lang.git" },
          { import = "lazyvim.plugins.extras.formatting.prettier" },

          { import = "plugins" },

          -- Nix owns the toolchain; Mason would download dynamically linked
          -- binaries that do not run here.
          { "mason-org/mason.nvim", enabled = false },
          { "mason-org/mason-lspconfig.nvim", enabled = false },

          -- Last on purpose. `ensure_installed` is declared in opts_extend, so
          -- every extra appends to it and a plain `ensure_installed = {}` would
          -- be appended to rather than replace. A function opts gets the merged
          -- table and its return value wins, which is the only reliable way to
          -- clear it. `build = false` stops LazyVim calling :TSUpdate against
          -- the read-only store path.
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

  # ~/.config/nvim itself stays a real directory — home-manager only symlinks
  # the leaves — so lazy.nvim's state under ~/.local/share/nvim and the
  # redirected lazyvim.json both remain writable.
  xdg.configFile."nvim/lua/config/options.lua".text = ''
    -- Loaded after lazyvim.config.options, so this only needs the deltas.
    local opt = vim.opt

    opt.scrolloff = 8

    -- Nix builds fail on trailing whitespace often enough to want it visible.
    opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
  '';

  xdg.configFile."nvim/lua/config/keymaps.lua".text = ''
    -- Keep LazyVim's defaults, including lazygit on <leader>gg and <leader>gG.
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
      { "folke/tokyonight.nvim", enabled = false },
      { "catppuccin/nvim", name = "catppuccin", enabled = false },
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
        opts = {
          setup = {
            -- LazyVim's go extra installs a workaround for gopls not
            -- advertising semanticTokensProvider (golang/go#54531, fixed years
            -- ago). On Neovim 0.12 it throws, because
            -- client.config.capabilities.textDocument is nil now — every Go
            -- buffer opens with an error popup. Replacing it with a no-op costs
            -- nothing: modern gopls advertises the capability itself.
            gopls = function() end,
          },
          servers = {
            bashls = {},
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
          },
        },
      },
      {
        "saghen/blink.cmp",
        opts = { fuzzy = { prebuilt_binaries = { download = false } } },
      },
      {
        "iamcco/markdown-preview.nvim",
        build = false,
      },
      {
        -- rustup puts a `rust-analyzer` shim in ~/.nix-profile/bin, and the
        -- neovim wrapper appends its own PATH entries rather than prepending,
        -- so that shim wins over the nix package. When the active toolchain has
        -- no rust-analyzer component the shim "falls back" to the next one on
        -- PATH — itself — and rust-analyzer dies with "infinite recursion
        -- detected" on every Rust buffer. Naming the store path sidesteps the
        -- shim entirely, and works whether or not rustup has the component.
        "mrcjkb/rustaceanvim",
        opts = {
          server = {
            cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" },
          },
        },
      },
    }
  '';

  xdg.configFile."nvim/lua/plugins/jupyter.lua".text = ''
    -- Notebooks. molten runs the kernel and renders output, quarto/otter give
    -- LSP and completion inside code cells, jupytext converts .ipynb on open so
    -- the buffer is plain text.
    --
    -- HM 26.05 clears the wrapper's build-time plugin packpath, so merely
    -- adding Molten to programs.neovim.plugins does not register it reliably.
    -- After rebuilding (also after Molten updates), open a Python/Markdown
    -- buffer, run :Lazy load molten-nvim then :UpdateRemotePlugins and restart.
    -- The manifest lives in the writable data directory, not the Nix store.
    --
    -- Inline images work because kitty speaks the graphics protocol; imagemagick
    -- comes from ../desktop.nix.
    return {
      {
        "benlubas/molten-nvim",
        version = false,
        ft = { "quarto", "markdown", "python" },
        dependencies = { "3rd/image.nvim" },
        init = function()
          vim.g.molten_image_provider = "image.nvim"
          vim.g.molten_output_win_max_height = 20
          vim.g.molten_auto_open_output = false
          vim.g.molten_wrap_output = true
          vim.g.molten_virt_text_output = true
          vim.g.molten_virt_lines_off_by_1 = true
        end,
        keys = {
          { "<leader>mi", "<cmd>MoltenInit<cr>", desc = "Molten: init kernel" },
          { "<leader>me", "<cmd>MoltenEvaluateOperator<cr>", desc = "Molten: evaluate operator" },
          { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Molten: evaluate line" },
          { "<leader>mr", "<cmd>MoltenReevaluateCell<cr>", desc = "Molten: re-evaluate cell" },
          { "<leader>mo", "<cmd>MoltenShowOutput<cr>", desc = "Molten: show output" },
          { "<leader>mv", ":<C-u>MoltenEvaluateVisual<cr>gv", mode = "v", desc = "Molten: evaluate selection" },
        },
      },
      {
        "3rd/image.nvim",
        version = false,
        -- The magick rock comes from programs.neovim.extraLuaPackages, so
        -- there is nothing to build — and the plugin dir is read-only anyway.
        build = false,
        opts = {
          backend = "kitty",
          max_width = 100,
          max_height = 12,
          max_height_window_percentage = math.huge,
          max_width_window_percentage = math.huge,
          window_overlap_clear_enabled = true,
        },
      },
      {
        -- Gives you real LSP inside the code cells of a converted notebook —
        -- completion, hover and diagnostics from basedpyright on the python
        -- chunks rather than plain markdown. quarto-nvim used to activate this;
        -- with quarto gone it is driven off a FileType autocmd instead.
        "jmbuhr/otter.nvim",
        ft = { "markdown" },
        config = function()
          vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("oad_otter", { clear = true }),
            pattern = "markdown",
            callback = function()
              pcall(require("otter").activate, { "python", "bash", "lua" })
            end,
          })
        end,
      },
      {
        "GCBallesteros/jupytext.nvim",
        lazy = false,
        opts = {
          style = "markdown",
          output_extension = "md",
          force_ft = "markdown",
        },
      },
    }
  '';

  xdg.configFile."nvim/lua/plugins/platformio.lua".text = ''
    -- Embedded work. clangd needs a compile_commands.json before it can
    -- resolve <Arduino.h>; `:PioLSP` writes one, and the opts below decide how.
    -- This adds the build/upload/monitor side, driven through toggleterm.
    --
    -- The pio CLI comes from programs.neovim.extraPackages (platformio-core);
    -- udev rules for flashing are system-wide, already set in
    -- ../../configuration.nix.
    return {
      {
        "anurag3301/nvim-platformio.lua",
        -- Every command the plugin defines in plugin/platformio.lua. lazy only
        -- loads it when one of these is typed, and the plugin's commands do not
        -- exist until it loads — so a name missing here is a "Not an editor
        -- command" error until some other Pio* command has been run first.
        -- Note it is Piocmdh/Piocmdf (horizontal/float), not Piocmd.
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
        -- The plugin defaults to lsp = "ccls", and on that path :PioLSP writes
        -- a .ccls file and nothing else. clangd cannot read .ccls, so it finds
        -- no compilation database, falls back to a bare host `clang` with none
        -- of the framework's include paths, and every <Arduino.h> comes back
        -- "file not found".
        --
        -- clangd_source = "compiledb" runs `pio run -t compiledb`, which emits
        -- the real build command line for every translation unit — the
        -- framework's sources included, so `gd` reaches them. It is also the
        -- file VSCodium's clangd reads, so the two editors cannot disagree.
        -- The plugin's own :help warns this combination breaks on Espressif
        -- boards: the xtensa build line carries GCC-only flags that clang
        -- rejects outright. That is what ../clangd.nix removes.
        opts = {
          lsp = "clangd",
          clangd_source = "compiledb",
        },
      },
      { "akinsho/toggleterm.nvim", opts = {} },
      {
        -- clangd resolves <Arduino.h> from the database above, then dies on
        -- <stdio.h> unless it can ask the cross-compiler where newlib is.
        -- LazyVim's clangd extra owns `cmd`, so append rather than replace.
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
          local clangd = opts.servers and opts.servers.clangd
          if not clangd then
            return
          end
          clangd.cmd = vim.list_extend(vim.deepcopy(clangd.cmd or { "clangd" }), ${clangdArgs})
        end,
      },
    }
  '';
}
