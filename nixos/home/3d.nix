{ pkgs, ... }:
let
  # This laptop uses PRIME offload, so make Blender consistently use the RTX
  # GPU whether it is started from a terminal or a desktop launcher.
  blenderNvidia = pkgs.symlinkJoin {
    name = "blender-nvidia-${pkgs.blender.version}";
    paths = [ pkgs.blender ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/blender" \
        --set __NV_PRIME_RENDER_OFFLOAD 1 \
        --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
        --set __GLX_VENDOR_LIBRARY_NAME nvidia \
        --set __VK_LAYER_NV_optimus NVIDIA_only
    '';
  };
in
{
  home.packages = [
    blenderNvidia
    pkgs.orca-slicer
  ];
}
