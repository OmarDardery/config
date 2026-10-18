-- Exercise generated editor configuration and a disposable local notebook kernel.
local lua_files = vim.fn.globpath(vim.fn.stdpath("config") .. "/lua", "**/*.lua", false, true)
assert(#lua_files > 0, "Generated Lua configuration was not found")
for _, path in ipairs(lua_files) do
  assert(loadfile(path), "Invalid Lua: " .. path)
end
assert(vim.g.colors_name == "habamax", "Built-in fallback theme did not load without a palette")
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
  python_adapter(function(adapter)
    python_adapter = adapter
  end, { request = "launch" })
end
assert(vim.fn.executable(python_adapter.command) == 1, "Python debug adapter is not executable")
assert(vim.fn.executable(dap.adapters.codelldb.executable.command) == 1, "CodeLLDB is not executable")
assert(vim.g.rustaceanvim.dap.adapter, "Rust debugger was not configured")

local lsp = LazyVim.opts("nvim-lspconfig")
assert(lsp.servers.basedpyright.enabled)
assert(not lsp.servers.pyright.enabled)
assert(lsp.servers.basedpyright.settings.basedpyright.analysis.typeCheckingMode == "standard")
assert(lsp.servers.basedpyright.settings.basedpyright.disableOrganizeImports)
assert(lsp.servers.ruff.cmd_env.RUFF_TRACE == "off")
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
lazy.load({ plugins = { "opencode.nvim", "diffview.nvim", "mini.surround", "yanky.nvim" }, wait = true })
assert(vim.fn.exists(":OpenCode") == 2, "OpenCode command missing")
assert(type(require("opencode.config").opts.server.start) == "function")
for _, command in ipairs({ "opencode", "curl", "lsof", "pgrep", "fd", "rg", "git" }) do
  assert(vim.fn.executable(command) == 1, "Editor runtime tool missing: " .. command)
end
assert(vim.fn.exists(":DiffviewOpen") == 2, "Diff review command missing")
assert(vim.fn.exists(":MoltenInit") == 2, "Declarative remote-plugin manifest missing")

-- Run a real kernel and round-trip notebook source and outputs through Jupytext.
-- Image transport needs Kitty; the kernel/text path is also usable headlessly.
assert(vim.g.molten_image_provider == "none", "Headless notebook should use text output")
local notebook = vim.fn.getcwd() .. "/notebook.ipynb"
vim.fn.writefile({
  vim.json.encode({
    nbformat = 4,
    nbformat_minor = 5,
    metadata = {
      kernelspec = { name = "nix-python", display_name = "Python (Nix notebooks)", language = "python" },
      language_info = { name = "python", file_extension = ".py" },
    },
    cells = {
      {
        id = "stored",
        cell_type = "code",
        metadata = vim.empty_dict(),
        execution_count = 1,
        source = { 'print("stored output")' },
        outputs = { { output_type = "stream", name = "stdout", text = { "stored output\n" } } },
      },
      {
        id = "calculate",
        cell_type = "code",
        metadata = vim.empty_dict(),
        execution_count = vim.NIL,
        source = { "answer = 6 * 7\n", "print(answer)" },
        outputs = {},
      },
    },
  }),
}, notebook)
vim.cmd.edit(notebook)
assert(vim.bo.filetype == "markdown", "Notebook was not converted to editable Markdown")
assert(vim.tbl_contains(vim.fn.MoltenAvailableKernels(), "nix-python"), "Declared kernel not found")
assert(#vim.fn.MoltenRunningKernels(true) == 0, "Opening a notebook started a kernel")
local execute_notebook = vim.env.NOTEBOOK_EXECUTION_TEST == "1"
if execute_notebook then
  vim.cmd.MoltenInit("nix-python")
  assert(
    vim.wait(10000, function()
      return #vim.fn.MoltenRunningKernels(true) == 1
    end),
    "Kernel failed to start"
  )
  -- Process the scheduled import before editing or executing cells.
  vim.wait(200, function()
    return false
  end)
end
local cell_line
for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
  if line == "answer = 6 * 7" then
    cell_line = i
    vim.api.nvim_buf_set_lines(0, i - 1, i, false, { "answer = 7 * 7" })
    break
  end
end
assert(cell_line, "Notebook code cell missing")
vim.cmd.write()
assert(require("otter.keeper").rafts[vim.api.nvim_get_current_buf()], "Notebook cell support was not attached")
local saved
if execute_notebook then
  vim.api.nvim_win_set_cursor(0, { cell_line, 0 })
  require("quarto.runner").run_cell()
  assert(
    vim.wait(30000, function()
      vim.cmd.MoltenExportOutput({ bang = true })
      saved = vim.json.decode(table.concat(vim.fn.readfile(notebook), "\n"))
      return vim.inspect(saved.cells[2].outputs):find("49", 1, true) ~= nil
    end, 200),
    "Code-cell execution did not produce output"
  )
end
vim.cmd.write()
saved = vim.json.decode(table.concat(vim.fn.readfile(notebook), "\n"))
assert(vim.inspect(saved.cells[1].outputs):find("stored output", 1, true), "Stored notebook output was lost")
if execute_notebook then
  assert(vim.inspect(saved.cells[2].outputs):find("49", 1, true), "Executed notebook output was not saved")
  vim.cmd.MoltenDeinit()
end
assert(vim.inspect(saved.cells[2].source):find("7 * 7", 1, true), "Edited cell source was not saved")
print(
  "PASS: Nix plugins, debuggers, tests, LSPs, OpenCode and notebook round-trip"
    .. (execute_notebook and " with execution" or "")
)
assert(vim.fn.writefile({ "passed" }, assert(vim.env.EDITOR_CHECK_DONE)) == 0)
vim.cmd("qa!")
