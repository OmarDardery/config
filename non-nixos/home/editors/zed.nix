# Zed: native Wayland editor with Nix support and vim mode.
{
  pkgs,
  config,
  profile,
  isLaptop ? false,
  ...
}:
let
  # Expose only the AMD Vulkan driver so Zed never wakes the NVIDIA dGPU.
  amdOnly = pkgs.symlinkJoin {
    name = "zed-editor-amd";
    paths = [ pkgs.zed-editor ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --set VK_DRIVER_FILES /run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json
    '';
    inherit (pkgs.zed-editor) meta;
  };
in
{
  programs.zed-editor = {
    enable = true;
    package = if isLaptop then amdOnly else pkgs.zed-editor;
    extensions = [ "nix" ];
    userSettings = {
      vim_mode = true;
      relative_line_numbers = true;
      vertical_scroll_margin = 8;
      format_on_save = "on";
      remove_trailing_whitespace_on_save = true;
      ensure_final_newline_on_save = true;
      buffer_font_family = "JetBrainsMono Nerd Font";
      buffer_font_size = 14;
      ui_font_family = "Inter";
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      auto_update = false;
      terminal = {
        shell.with_arguments = {
          program = "${pkgs.zsh}/bin/zsh";
          args = [ "-l" ];
        };
        env.ZDOTDIR = profile.zshHome or config.home.homeDirectory;
      };
      # nixd and nixfmt come from lazyvim.nix's home.packages.
      languages.Nix = {
        language_servers = [
          "nixd"
          "!nil"
        ];
        formatter.external.command = "nixfmt";
      };
    };
  };
}
