# Everything bound to this specific laptop: GPUs, peripherals, extra disks.
{ config, pkgs, ... }:
{
  boot.kernelModules = [ "uinput" ];

  hardware = {
    bluetooth = {
      enable = true;

      # Battery percentage for Bluetooth peripherals — the Sony headphones and
      # the Xbox pads. BlueZ implements this through its Battery Provider API,
      # which is gated behind the experimental flag; without it upower has
      # nothing to report and the bar shows no level at all. "Experimental"
      # names the D-Bus interface's stability, not the feature's reliability.
      settings.General.Experimental = true;
    };

    # Xbox controllers over Bluetooth. USB is fine on the in-kernel xpad
    # driver, but over BT that driver mis-maps the buttons, exposes no rumble
    # and reports no battery. xpadneo fixes all three and leaves USB alone.
    # hardware.xone is deliberately NOT enabled — that is for the proprietary
    # 2.4GHz Xbox Wireless dongle, which is a different device.
    xpadneo.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # The XP-Pen tablet. The kernel's HID driver gives cursor movement and
    # nothing else — no pressure curve, no button mapping, no area cropping.
    # OpenTabletDriver is what makes it a graphics tablet rather than a mouse.
    # The app and graphical user daemon live in home/hardware-user.nix.
    uinput.enable = true;

    # NVIDIA. On NixOS the kernel module is rebuilt against whatever
    # boot.kernelPackages you pick, automatically, on every switch — that is
    # the akmods equivalent and there is nothing to run by hand.
    nvidia = {
      # The locked bleeding_edge alias is 595.71.05 and cannot build on Linux
      # 7.2.8. Pin the newer release explicitly, including every source hash.
      # Build kernel/driver updates before switching and test suspend/offload.
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "610.57.04";
        sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
        sha256_aarch64 = "sha256-QCefrMBCmpOwuOyXv1k5Gj0iB2CYlPgnG3JToUw/j54=";
        openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
        settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
        persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
      };
      # Required for Wayland, and required for offload below — without it the
      # dGPU is held awake permanently.
      modesetting.enable = true;

      # Your dGPU is 0x10de:0x28e0 — Ada Lovelace (AD107M, RTX 4060 Laptop).
      # The wiki: "If you have a GPU with Turing architecture (RTX 20-Series)
      # or newer set hardware.nvidia.open to true."
      open = true;

      nvidiaSettings = false; # matching driver settings GUI is home-owned

      # Saves all of VRAM on suspend instead of the bare essentials. Fixes
      # corruption/crashes after resume on some machines, but is itself known
      # to cause suspend failures. Leave off unless resume actually misbehaves.
      powerManagement.enable = false;

      # Runtime suspend was already working with this disabled. Changing it
      # requires separate suspend testing; do not assume an extra battery win.
      powerManagement.finegrained = false;

      # ── Optimus PRIME: offload mode ──────────────────────────────────────
      # The AMD iGPU renders everything and the dGPU sleeps until you launch
      # something with `nvidia-offload <cmd>`.
      #
      # Bus IDs are DECIMAL conversions of the hex addresses in /sys — this is
      # the step everyone gets wrong:
      #   NVIDIA  0000:01:00.0 -> 0x01 =   1 -> "PCI:1:0:0"
      #   AMD     0000:66:00.0 -> 0x66 = 102 -> "PCI:102:0:0"
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

  # Order matters for PRIME offload: the iGPU driver must come FIRST, otherwise
  # the X server runs permanently on the dGPU and it never sleeps (visible as
  # a non-idle GPU in `nvidia-smi`).
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  # Fixes this laptop's stripe corruption, not its independent Niri flicker.
  # Changes require a fresh login. Keep the fixed refresh configuration and
  # disabled amdgpu_dpm action; historical Niri findings remain in GRAPHICS.md.
  # Keep this global: SDDM also renders on AMD; greeter dependence is untested.
  environment.sessionVariables.AMD_DEBUG = "nodcc";

  # No swap device on this machine. Compressed RAM swap gives the Rust/Go/Nix
  # builds headroom on 14 GiB instead of hitting the OOM killer.
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
