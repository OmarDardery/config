return {
  -- Language servers and compilers belong in your projects or distro packages.
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "nvim-treesitter/nvim-treesitter", enabled = false },
  { "nvim-treesitter/nvim-treesitter-textobjects", enabled = false },
  { "windwp/nvim-ts-autotag", enabled = false },
  { "saghen/blink.cmp", opts = { fuzzy = { implementation = "lua" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { lua_ls = { enabled = false } } } },
}
