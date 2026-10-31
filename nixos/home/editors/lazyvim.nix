# A small LazyVim starter. Plugins live in user data, not a system toolchain.
{ pkgs, lib, config, isNixOS, desktopEnabled ? false, ... }:
let
  init = ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = "\\"
    -- Keep optional extras separate from the previous all-languages setup.
    vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim-minimal.json"
    vim.g.loaded_python3_provider = 0
    vim.g.loaded_ruby_provider = 0
    vim.g.loaded_perl_provider = 0
    vim.g.loaded_node_provider = 0

    local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.uv.fs_stat(path .. "/lua/lazy/init.lua") then
      vim.api.nvim_echo({ { "Installing LazyVim's plugin manager (30 second timeout)…", "MoreMsg" } }, true, {})
      vim.cmd.redraw()
      -- Retain an interrupted clone for recovery, then retry into a fresh path.
      if vim.uv.fs_stat(path) then
        vim.uv.fs_rename(path, path .. ".incomplete-" .. vim.fn.getpid())
      end
      local temporary = path .. ".bootstrap-" .. vim.fn.getpid()
      local ok, result = pcall(function()
        return vim.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
          "https://github.com/folke/lazy.nvim.git", temporary }, { text = true }):wait(30000)
      end)
      if ok and result.code == 0 then
        ok = vim.uv.fs_rename(temporary, path) ~= nil
          or vim.uv.fs_stat(path .. "/lua/lazy/init.lua") ~= nil
      else
        ok = false
      end
      vim.fn.delete(temporary, "rf")
      if not ok then
        vim.schedule(function()
          vim.notify("Could not install lazy.nvim. Using plain Neovim; check your connection and restart.\n"
            .. tostring(type(result) == "table" and result.stderr or result), vim.log.levels.WARN)
        end)
        return
      end
    end
    vim.opt.rtp:prepend(path)
    require("lazy").setup({
      lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
      spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "habamax" } },
        { import = "plugins" },
      },
      checker = { enabled = false },
      rocks = { enabled = false },
      git = { timeout = 30 },
    })
  '';
  files = {
    "init.lua" = init;
    "lua/config/options.lua" = ''
      vim.opt.scrolloff = 8
      vim.opt.inccommand = "split"
    '';
    "lua/plugins/tools.lua" = ''
      return {
        -- Add language tools per project; do not install a full tool suite at login.
        { "mason-org/mason.nvim", enabled = false },
        -- Use built-in syntax highlighting; no parser compilation/toolchain.
        { "nvim-treesitter/nvim-treesitter", enabled = false },
        { "nvim-treesitter/nvim-treesitter-textobjects", enabled = false },
        { "windwp/nvim-ts-autotag", enabled = false },
        { "mason-org/mason-lspconfig.nvim", enabled = false },
        { "jay-babu/mason-nvim-dap.nvim", enabled = false },
        -- No downloaded Rust library or compiler needed for completion on NixOS.
        { "saghen/blink.cmp", opts = { fuzzy = { implementation = "lua" } } },
        { "neovim/nvim-lspconfig", opts = { servers = {
          lua_ls = { enabled = false },
          nixd = { cmd = { "nixd" } },
        } } },
        { "stevearc/conform.nvim", opts = {
          formatters_by_ft = { nix = { "nixfmt" } },
          formatters = { nixfmt = { command = "nixfmt" } },
        } },
      }
    '';
  } // lib.optionalAttrs desktopEnabled {
    "lua/plugins/noctalia.lua" = ''
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
  };
  defaults = pkgs.linkFarm "lazyvim-starter" (lib.mapAttrsToList (name: text: {
    inherit name;
    path = pkgs.writeText (builtins.baseNameOf name) text;
  }) files);
  manifest = pkgs.writeText "lazyvim-starter.json" (builtins.toJSON {
    directories."${config.xdg.configHome}/nvim" = "${defaults}";
    # Repair only our exact previous starter; edited or deleted files stay yours.
    repairs = {
      "${config.xdg.configHome}/nvim/init.lua" = {
        sha256 = "5c4a0c19dc24aa834cfa37e875723d08916411206e9238802261a74eb85e64b8";
        source = "${defaults}/init.lua";
      };
      "${config.xdg.configHome}/nvim/lua/plugins/tools.lua" = {
        sha256 = "6e4844d9330cae59f39a1cfb1e5746b7bb23f83088f7247932140aeeac8e680d";
        source = "${defaults}/lua/plugins/tools.lua";
      };
    };
  });
in
{
  # Nix supplies the program and Nix tools; Lazy owns every plugin in user data.
  programs.neovim = lib.mkIf isNixOS {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
    withNodeJs = false;
    withPerl = false;
    initLua = lib.mkForce "";
  };
  home.packages = lib.optionals isNixOS [ pkgs.nixd pkgs.nixfmt ];
  home.activation.mutableLazyVim = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${../../pkgs}/migrate-desktop.py editor-defaults \
      ${manifest} ${lib.escapeShellArg "${config.xdg.stateHome}/editor-defaults/lazyvim"}
  '';
}
