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

    local available = pcall(require, "lazy")
    if not available then
      local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.uv.fs_stat(path) then
        local output = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
          "https://github.com/folke/lazy.nvim.git", path })
        if vim.v.shell_error ~= 0 then error(output) end
      end
      vim.opt.rtp:prepend(path)
    end
    require("lazy").setup({
      lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
      spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "habamax" } },
        { import = "plugins" },
      },
      checker = { enabled = false },
      rocks = { enabled = false },
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
