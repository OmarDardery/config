# Everything bound to this specific laptop: GPUs, peripherals, extra disks.
{ config, pkgs, ... }:
{
  boot.kernelModules = [ "uinput" ];

  hardware = {
    bluetooth.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    opentabletdriver.enable = true;
    uinput.enable = true;

    # NVIDIA. On NixOS the kernel module is rebuilt against whatever
    # boot.kernelPackages you pick, automatically, on every switch — that is
    # the akmods equivalent and there is nothing to run by hand.
    nvidia = {
      # .latest and .stable are the same derivation on this nixpkgs (both
      # 595.71.05), so pinning to .stable is a no-op today. It stops a future
      # `nix flake update` pairing a too-new kernel with a driver that has no
      # matching release yet.
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Required for Wayland, and required for offload below — without it the
      # dGPU is held awake permanently.
      modesetting.enable = true;

      # Your dGPU is 0x10de:0x28e0 — Ada Lovelace (AD107M, RTX 4060 Laptop).
      # The wiki: "If you have a GPU with Turing architecture (RTX 20-Series)
      # or newer set hardware.nvidia.open to true."
      open = true;

      nvidiaSettings = true;

      # Saves all of VRAM on suspend instead of the bare essentials. Fixes
      # corruption/crashes after resume on some machines, but is itself known
      # to cause suspend failures. Leave off unless resume actually misbehaves.
      powerManagement.enable = false;

      # Powers the dGPU down entirely when unused. Requires offload (below).
      # Marked experimental upstream; flip to true if you want the battery win
      # and are willing to test suspend/resume.
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
          enableOffloadCmd = true; # provides the `nvidia-offload` wrapper
        };
      };
    };
  };

  # Order matters for PRIME offload: the iGPU driver must come FIRST, otherwise
  # the X server runs permanently on the dGPU and it never sleeps (visible as
  # a non-idle GPU in `nvidia-smi`).
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  # ── AMD iGPU stripe corruption: DCC ───────────────────────────────────
  # Pink/blue banded corruption on tiled windows, never on fullscreen games,
  # never in screenshots. Fullscreen bypasses composite via direct scanout and
  # redraws every block each frame; tiled windows repaint only damage rects
  # into a DCC-compressed framebuffer. Stale per-block compression metadata on
  # partially-damaged regions decompresses to banded colour — which matches the
  # window-shaped artifacts exactly.
  #
  # `nodcc` disables Delta Color Compression in radeonsi (niri's GL renderer).
  # Costs some iGPU memory bandwidth; no visual difference.
  #
  # CONFIRMED to fix the corruption on this panel. Do not remove without
  # retesting — the symptom takes a fresh login to reappear, not just a rebuild.
  #
  # sessionVariables, not variables: niri is launched by the display manager,
  # so this needs a fresh LOGIN to take effect, not just a rebuild.
  environment.sessionVariables.AMD_DEBUG = "nodcc";

  # ── Window content flickering out: eDP panel power saving ─────────────
  # UNDER TEST. Remove this line and reboot to go back.
  #
  # Symptom: window CONTENT vanishes in moving rectangular patches, showing
  # the wallpaper behind it, while the borders and tab indicators keep drawing
  # perfectly. Worse on battery. Ruled out first: niri's blur, shadows and
  # rounded corners (all disabled, no change), VRR (off), cross-GPU scanout
  # (the panel renders and scans out on the same GPU), adaptive backlight
  # (panel_power_savings is 0), and display underflow (zero in dmesg).
  #
  # "Patches of stale content, worse on battery" is the signature of the eDP
  # selective-update features: the panel is sent only the damaged rectangles,
  # and everything else keeps whatever it had. These are exactly the features
  # that engage harder when unplugged.
  #
  # 0xE10 turns off all four at once, so one reboot exonerates or convicts the
  # whole family. Values are from DC_DEBUG_MASK in the kernel's amd_shared.h:
  #   0x010 PSR          0x200 PSR_SU
  #   0x400 Replay       0x800 IPS (idle power states)
  # If this fixes it, bisect by trying each value alone to find the one that
  # matters, then keep only that. If it changes nothing, delete this and the
  # cause is not panel power saving.
  boot.kernelParams = [ "amdgpu.dcdebugmask=0xE10" ];

  # No swap device on this machine. Compressed RAM swap gives the Rust/Go/Nix
  # builds headroom on 14 GiB instead of hitting the OOM killer.
  zramSwap.enable = true;

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/71d4d606-a6ef-42bb-b63c-8f5a8fee4b24";
    fsType = "xfs";
    options = [
      "nofail" # Prevent system from failing if this drive doesn't mount
    ];
  };
}
