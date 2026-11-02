# A small LazyVim starter. Plugins live in user data, not a system toolchain.
{
  pkgs,
  lib,
  ...
}:
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

  };
in
{
  # Nix supplies the program and Nix tools; Lazy owns every plugin in user data.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
    withNodeJs = false;
    withPerl = false;
    initLua = lib.mkForce "";
    extraPackages = [
      pkgs.git
      pkgs.ripgrep
      pkgs.fd
    ];
  };
  home.packages = [
    pkgs.nixd
    pkgs.nixfmt
  ];
  xdg.configFile = lib.mapAttrs' (
    name: text: lib.nameValuePair "nvim/${name}" { inherit text; }
  ) files;
}
