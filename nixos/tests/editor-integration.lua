-- Exercise the generated Nix configuration without opening projects or services.
local lua_files = vim.fn.globpath(vim.fn.stdpath("config") .. "/lua", "**/*.lua", false, true)
assert(#lua_files > 0, "Generated Lua configuration was not found")
for _, path in ipairs(lua_files) do
  assert(loadfile(path), "Invalid Lua: " .. path)
end
local lazy = require("lazy")
local config = require("lazy.core.config")
for name, plugin in pairs(config.plugins) do
  assert(vim.fn.isdirectory(plugin.dir) == 1, "Plugin missing from Nix: " .. name .. " (" .. plugin.dir .. ")")
end

lazy.load({ plugins = { "nvim-dap", "neotest", "nvim-dap-python", "nvim-dap-go", "rustaceanvim" }, wait = true })
local dap = require("dap")
local vscode = require("dap.ext.vscode")
assert(vscode.type_to_filetypes.debugpy[1] == "python")
assert(vscode.type_to_filetypes.lldb[1] == "c")
assert(dap.adapters.python, "Python debugger was not configured")
assert(dap.adapters.debugpy == dap.adapters.python, "VS Code Python adapter alias missing")
assert(dap.adapters.lldb == dap.adapters.codelldb, "VS Code LLDB adapter alias missing")
assert(dap.adapters.go, "Go debugger was not configured")
assert(dap.adapters.codelldb, "C/C++ debugger was not configured")
local python_adapter = dap.adapters.python
if type(python_adapter) == "function" then
  python_adapter(function(adapter) python_adapter = adapter end, { request = "launch" })
end
assert(vim.fn.executable(python_adapter.command) == 1, "Python debug adapter is not executable")
assert(vim.fn.executable(dap.adapters.codelldb.executable.command) == 1, "CodeLLDB is not executable")
assert(vim.g.rustaceanvim.dap.adapter, "Rust debugger was not configured")

local lsp = LazyVim.opts("nvim-lspconfig")
assert(lsp.servers.basedpyright.enabled)
assert(not lsp.servers.pyright.enabled)
assert(lsp.servers.basedpyright.settings.basedpyright.analysis.typeCheckingMode == "standard")
assert(not lsp.servers.rust_analyzer.enabled, "Rust has two language servers")
assert(lsp.servers.eslint, "ESLint was not configured")
local test = LazyVim.opts("neotest")
local adapter_names = {}
for _, adapter in ipairs(test.adapters) do
  adapter_names[adapter.name] = true
end
assert(adapter_names[require("neotest-python").name])
assert(adapter_names[require("neotest-golang").name])
assert(adapter_names[require("rustaceanvim.neotest").name])
assert(vim.wait(1000, function() return vim.fn.exists(":OpenCode") == 2 end), "OpenCode command missing")
print("PASS: Nix plugin resolution, debuggers, test adapters, LSP ownership and project commands")
vim.cmd("qa!")
