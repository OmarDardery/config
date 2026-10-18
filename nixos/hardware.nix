# Everything bound to this specific laptop: GPUs, peripherals, extra disks.
{
  config,
  pkgs,
  ...
}:
{
  boot.kernelModules = [ "uinput" ];

  hardware = {
    bluetooth = {
      enable = true;

      # Enable battery reporting for Bluetooth peripherals.
      settings.General.Experimental = true;
    };

    # Xbox Bluetooth controller support; USB uses the kernel xpad driver.
    xpadneo.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Device access only; the GUI and user daemon are in home/hardware-user.nix.
    uinput.enable = true;

    # NVIDIA driver and PRIME offload policy.
    nvidia = {
      # Pinned for compatibility with the configured kernel; build and test updates before switching.
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "610.57.04";
        sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
        sha256_aarch64 = "sha256-QCefrMBCmpOwuOyXv1k5Gj0iB2CYlPgnG3JToUw/j54=";
        openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
        settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
        persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
      };
      # Enable modesetting for Wayland and PRIME offload.
      modesetting.enable = true;

      # Use open kernel modules for this Ada GPU.
      open = true;

      nvidiaSettings = false; # matching driver settings GUI is home-owned

      # Saves all of VRAM on suspend instead of the bare essentials. Fixes
      # corruption/crashes after resume on some machines, but is itself known
      # to cause suspend failures. Leave off unless resume actually misbehaves.
      powerManagement.enable = false;

      # Runtime suspend was already working with this disabled. Changing it
      # requires separate suspend testing; do not assume an extra battery win.
      powerManagement.finegrained = false;

      # The AMD iGPU drives the desktop; NVIDIA is used through nvidia-offload.
      # Bus IDs use decimal PCI addresses.
      prime = {
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:102:0:0";

        offload = {
          enable = true;
          enableOffloadCmd = false; # home-owned `nvidia-offload` wrapper
        };
      };
    };
  };

  # Preserve the OpenTabletDriver module's host-only device access policy.
  services.udev.packages = [ pkgs.opentabletdriver ];
  boot.blacklistedKernelModules = [
    "hid-uclogic"
    "wacom"
  ];

  # Keep the iGPU first in the PRIME driver list.
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  # Fixes this laptop's stripe corruption. Changes require a fresh login.
  # Historical graphics findings remain in the README.
  # Keep this global: SDDM also renders on AMD; greeter dependence is untested.
  environment.sessionVariables.AMD_DEBUG = "nodcc";

  # Prefer compressed RAM swap; the disk swap in hardware-configuration.nix
  # remains available when RAM is exhausted.
  zramSwap.enable = true;

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/71d4d606-a6ef-42bb-b63c-8f5a8fee4b24";
    fsType = "xfs";
    options = [
      "nofail" # Prevent system from failing if this drive doesn't mount
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
    ];
  };
}
