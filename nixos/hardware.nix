# Everything bound to this specific laptop: GPUs, peripherals, extra disks.
{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    config.hardware.nvidia.package.settings
    (import ./pkgs/nvidia-offload.nix { inherit pkgs; })
  ];
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

    # Native driver and daemon; the tablet preference seed is in home/hardware-user.nix.
    uinput.enable = true;

    # NVIDIA driver and PRIME offload policy.
    nvidia = {
      # Official Nixpkgs new-feature driver; includes Linux 7.3 API support.
      # Hashes: NixOS/nixpkgs@a73abadb83fd64aee8abce72cc56811a178c1905
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "615.78.08";
        sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
        sha256_aarch64 = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
        openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
        settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
        persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
      };
      # Enable modesetting for Wayland and PRIME offload.
      modesetting.enable = true;

      # Use open kernel modules for this Ada GPU.
      open = true;

      nvidiaSettings = false; # matching settings GUI is installed above

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

  hardware.opentabletdriver.enable = true;

  # Keep the iGPU first in the PRIME driver list.
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  # Fixes this laptop's stripe corruption. Changes require a fresh login.
  # Historical graphics findings remain in the README.
  # Keep this global for the AMD-rendered desktop and login greeter.
  environment.sessionVariables.AMD_DEBUG = "nodcc";

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
