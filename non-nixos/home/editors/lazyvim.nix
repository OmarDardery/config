# Shared editor packages and configuration for NixOS and standalone Home Manager.
{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
    withNodeJs = false;
    withPerl = false;
    initLua = "";
  };
  home.packages = [
    pkgs.nixd
    pkgs.nixfmt
  ];
  xdg.configFile = {
    "nvim/init.lua".source = ../../dotfiles/nvim/init.lua;
    "nvim/lua/config/options.lua".source = ../../dotfiles/nvim/lua/config/options.lua;
    "nvim/lua/plugins/tools.lua".source = ../../dotfiles/nvim/lua/plugins/tools.lua;
    "nvim/lua/plugins/nix.lua".text = ''
      return {
        { "neovim/nvim-lspconfig", opts = { servers = { nixd = { cmd = { "nixd" } } } } },
        { "stevearc/conform.nvim", opts = {
          formatters_by_ft = { nix = { "nixfmt" } },
          formatters = { nixfmt = { command = "nixfmt" } },
        } },
      }
    '';
  };
}
