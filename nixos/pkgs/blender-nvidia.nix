{ pkgs }:
let
  offload = import ./nvidia-offload.nix { inherit pkgs; };
in
pkgs.symlinkJoin {
  name = "blender-nvidia-${pkgs.blender.version}";
  paths = [ pkgs.blender ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/blender" \
      --run 'exec ${offload}/bin/nvidia-offload ${pkgs.blender}/bin/blender "$@"'
  '';
}
