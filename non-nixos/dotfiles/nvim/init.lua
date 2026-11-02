vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- Store plugin state outside these dotfiles.
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
