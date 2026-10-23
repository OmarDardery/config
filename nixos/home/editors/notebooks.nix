{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}:
let
  pythonPackages =
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
  python = pkgs.python3.withPackages pythonPackages;
  # Register the pinned plugin during the build, without a first-run setup step.
  manifest = pkgs.runCommand "molten-rplugin.vim" { } ''
    export HOME="$TMPDIR/home"
    export NVIM_RPLUGIN_MANIFEST="$out"
    mkdir -p "$HOME"
    ${pkgs.neovim-unwrapped}/bin/nvim --headless -u NONE \
      --cmd "let g:python3_host_prog = '${python}/bin/python3'" \
      --cmd "set runtimepath+=${pkgs.vimPlugins.molten-nvim}" \
      -c 'runtime plugin/rplugin.vim' -c UpdateRemotePlugins -c quit
    grep -q MoltenInit "$out"
  '';
in
{
  programs.neovim = lib.mkIf isNixOS {
    withPython3 = true;
    extraPython3Packages = pythonPackages;
    extraLuaPackages = ps: [ ps.magick ];
    extraPackages = [
      pkgs.python3Packages.jupytext
      pkgs.imagemagick
    ];
  };

  xdg.configFile."nvim/plugin/molten.vim" = {
    enable = isNixOS;
    source = manifest;
  };

  xdg.configFile."nvim/lua/plugins/jupyter.lua".text = ''
    local function kitty_images()
      return #vim.api.nvim_list_uis() > 0
        and (vim.env.KITTY_WINDOW_ID ~= nil or vim.env.TERM == "xterm-kitty")
    end

    return {
      {
        "benlubas/molten-nvim",
        ft = { "quarto", "markdown", "python" },
        build = ${if isNixOS then "false" else builtins.toJSON ":UpdateRemotePlugins"},
        dependencies = { "3rd/image.nvim" },
        init = function()
          vim.g.molten_image_provider = kitty_images() and "image.nvim" or "none"
          -- Molten writes connection files under Jupyter's data directory.
          local data = vim.env.JUPYTER_DATA_DIR
            or ((vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")) .. "/jupyter")
          vim.fn.mkdir(data .. "/runtime", "p")
          vim.g.molten_output_win_max_height = 20
          vim.g.molten_auto_open_output = false
          vim.g.molten_wrap_output = true
          vim.g.molten_virt_text_output = true
          vim.g.molten_virt_lines_off_by_1 = true

          local group = vim.api.nvim_create_augroup("nix_notebook_outputs", { clear = true })
          vim.api.nvim_create_autocmd("User", {
            group = group,
            pattern = "MoltenInitPost",
            callback = function()
              local buf = vim.api.nvim_get_current_buf()
              if vim.api.nvim_buf_get_name(buf):match("%.ipynb$") then
                -- Leave the synchronous Python callback before requesting another command.
                vim.schedule(function()
                  if vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_call(buf, function() vim.cmd.MoltenImportOutput() end)
                  end
                end)
              end
            end,
          })
          vim.api.nvim_create_autocmd("BufWritePost", {
            group = group,
            pattern = "*.ipynb",
            callback = function()
              if #vim.fn.MoltenRunningKernels(true) > 0 then
                vim.cmd.MoltenExportOutput({ bang = true })
              end
            end,
          })
        end,
        keys = {
          { "<leader>mi", "<cmd>MoltenInit ${
            if isNixOS then "nix-python" else "editor-python"
          }<cr>", desc = "Notebook: start default Python kernel" },
          { "<leader>mI", "<cmd>MoltenInit<cr>", desc = "Notebook: choose kernel" },
          { "<leader>mp", function()
            local buf = vim.api.nvim_get_current_buf()
            vim.system({ "${
              if isNixOS then
                "${(import ../../pkgs/editor-tools.nix { inherit pkgs; }).notebookKernel}/bin/notebook-kernel"
              else
                "notebook-kernel"
            }", LazyVim.root() }, { text = true }, function(result)
              vim.schedule(function()
                if result.code ~= 0 then
                  vim.notify(result.stderr, vim.log.levels.ERROR, { title = "Project notebook kernel" })
                  return
                end
                local name = vim.trim(result.stdout)
                if vim.api.nvim_buf_is_valid(buf) then
                  vim.api.nvim_buf_call(buf, function() vim.cmd.MoltenInit(name) end)
                end
              end)
            end)
          end, desc = "Notebook: register/start project .venv" },
          { "<leader>me", "<cmd>MoltenEvaluateOperator<cr>", desc = "Notebook: evaluate operator" },
          { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Notebook: evaluate line" },
          { "<leader>mr", "<cmd>MoltenReevaluateCell<cr>", desc = "Notebook: re-evaluate cell" },
          { "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Notebook: enter output" },
          { "<leader>mh", "<cmd>MoltenHideOutput<cr>", desc = "Notebook: hide output" },
          { "<leader>md", "<cmd>MoltenDelete<cr>", desc = "Notebook: delete cell output" },
          { "<leader>mx", "<cmd>MoltenInterrupt<cr>", desc = "Notebook: interrupt kernel" },
          { "<leader>mq", "<cmd>MoltenDeinit<cr>", desc = "Notebook: stop kernel" },
          { "<leader>mv", ":<C-u>MoltenEvaluateVisual<cr>gv", mode = "x", desc = "Notebook: evaluate selection" },
        },
      },
      {
        "3rd/image.nvim",
        cond = kitty_images,
        build = false,
        opts = {
          backend = "kitty",
          processor = "${if isNixOS then "magick_rock" else "magick_cli"}",
          max_width = 100,
          max_height = 12,
          max_height_window_percentage = math.huge,
          max_width_window_percentage = math.huge,
          window_overlap_clear_enabled = true,
        },
      },
      {
        "quarto-dev/quarto-nvim",
        ft = { "quarto", "markdown" },
        dependencies = { "jmbuhr/otter.nvim" },
        opts = {
          lspFeatures = { languages = { "python" }, chunks = "all" },
          codeRunner = { enabled = true, default_method = "molten" },
        },
        config = function(_, opts)
          require("quarto").setup(opts)
          require("quarto").activate()
          vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("nix_notebook_cells", { clear = true }),
            pattern = { "markdown", "quarto" },
            callback = function() require("quarto").activate() end,
          })
        end,
        keys = {
          { "<leader>mc", function() require("quarto.runner").run_cell() end, desc = "Notebook: run cell" },
          { "<leader>ma", function() require("quarto.runner").run_above() end, desc = "Notebook: run through cell" },
          { "<leader>mb", function() require("quarto.runner").run_below() end, desc = "Notebook: run cell and below" },
          { "<leader>mA", function() require("quarto.runner").run_all() end, desc = "Notebook: run all cells" },
        },
      },
      {
        "GCBallesteros/jupytext.nvim",
        lazy = false,
        opts = { style = "markdown", output_extension = "md", force_ft = "markdown" },
      },
    }
  '';
}
