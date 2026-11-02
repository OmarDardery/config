# Scope graphics-library injection to Nix GUI applications.
{
  inputs,
  pkgs,
  profile,
  isNixOS,
  lib,
  ...
}:
let
  gpu = profile.gpu;
  wrappers = import inputs.nixgl {
    inherit pkgs;
    enable32bits = false;
    enableIntelX86Extensions = false;
  };
  # Upstream nixGL passes a removed kernel argument; use the current libsOnly API.
  nvidia =
    (pkgs.linuxPackages.nvidiaPackages.mkDriver {
      version = gpu.nvidiaVersion;
      sha256_64bit = gpu.nvidiaHash;
      useSettings = false;
      usePersistenced = false;
    }).override
      {
        libsOnly = true;
        acceptLicense = gpu.nvidiaAcceptLicense;
        disable32Bit = true;
      };
  nvidiaWrapper = pkgs.writeShellScriptBin "nixGLNvidia" ''
    egl_files=( ${nvidia}/share/glvnd/egl_vendor.d/*nvidia.json )
    export __EGL_VENDOR_LIBRARY_FILENAMES="''${egl_files[*]}"
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export GBM_BACKENDS_PATH=${nvidia}/lib/gbm
    export LD_LIBRARY_PATH=${
      lib.makeLibraryPath [
        pkgs.libglvnd
        nvidia
      ]
    }"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec "$@"
  '';
in
lib.mkIf (!isNixOS) {
  assertions = [
    {
      assertion = builtins.elem gpu.backend [
        "mesa"
        "nvidia"
      ];
      message = "GPU backend must be mesa or nvidia in nixos/local-gpu.nix.";
    }
    {
      assertion = gpu.backend != "nvidia" || (gpu.nvidiaVersion != null && gpu.nvidiaHash != null);
      message = "NVIDIA requires matching host version and hash in nixos/local-gpu.nix.";
    }
    {
      assertion = gpu.backend != "nvidia" || gpu.nvidiaAcceptLicense;
      message = "Review NVIDIA's driver license and set nvidiaAcceptLicense in nixos/local-gpu.nix.";
    }
  ];
  targets.genericLinux = {
    gpu.enable = false;
    nixGL = {
      packages = wrappers // {
        nixGLIntel = wrappers.nixGLMesa;
        nixGLNvidia = nvidiaWrapper;
      };
      defaultWrapper = gpu.backend;
      installScripts = [ gpu.backend ];
      vulkan.enable = false;
    };
  };
}
