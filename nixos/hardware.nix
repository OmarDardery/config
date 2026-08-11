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
  # CONFIRMED to fix the STRIPES, and only the stripes. The separate flicker
  # bug predates this line and is unaffected by it — do not read this comment
  # as evidence about the flicker in either direction.
  #
  # Do not remove without retesting — the stripes take a fresh login to
  # reappear, not just a rebuild.
  #
  # sessionVariables, not variables: niri is launched by the display manager,
  # so this needs a fresh LOGIN to take effect, not just a rebuild.
  environment.sessionVariables.AMD_DEBUG = "nodcc";

  # ── Window content flickering out: what has been ruled out ────────────
  # Symptom: window CONTENT vanishes in moving rectangular patches, showing
  # sharp wallpaper behind it, while borders and tab indicators keep drawing
  # perfectly. Worse on battery. Appeared around 2026-08-06.
  #
  # Tested and NOT the cause — do not retry these:
  #   * niri's blur, shadows, rounded corners and opacity. The untouched
  #     config at codeberg.org/oadardery/dotfiles has all of them on and does
  #     not flicker; disabling them here changed nothing.
  #   * The kernel. The config was reset to the 2026-08-04 tree (which pins
  #     pkgs.linuxPackages, 6.18) and the artifacts persisted, which is why
  #     commit 1618a04 bumped to linuxPackages_latest as an attempted fix.
  #   * AMD_DEBUG=nodcc above. It postdates the flicker and fixes only the
  #     stripes.
  #   * PSR, PSR-SU, Replay and IPS. amdgpu.dcdebugmask=0xE10 was applied and
  #     verified in /proc/cmdline over a full reboot; no change.
  #   * VRR (off), cross-GPU scanout (panel renders and scans out on the same
  #     GPU), adaptive backlight (panel_power_savings is 0), and display
  #     underflow (zero occurrences in dmesg).
  #
  # A full revert of the nix config AND flake.lock to a known-good tree did
  # not clear it, so it is not the nix-managed software.
  #
  # ── What it actually looks like ───────────────────────────────────────
  # On battery, power-profiles-daemon switches to power-saver on its own
  # (`powerprofilesctl query-battery-aware` is True), which sets the ACPI
  # platform profile to "quiet" and drops the APU's power budget. The iGPU then
  # sits on DPM level 0 and never leaves it: 800 MHz core and 400 MHz memory,
  # out of 2700/937, measured continuously with gpu_busy_percent at 16-22%.
  #
  # Low utilisation with pinned clocks is the tell. This is not a GPU that is
  # too slow on average, it is a governor sitting at the floor: a burst of
  # compositing work needs bandwidth before the SMU can ramp, and at 165 Hz the
  # frame is due in 6 ms. Frames that miss leave the regions niri did not
  # redraw composited as empty, and "empty" here is the wallpaper, because
  # layout.kdl sets background-color "transparent" and rules.kdl puts the
  # wallpaper in the backdrop. That is the sharp-wallpaper symptom exactly, and
  # it is why the artifacts vanish under a game: the dGPU renders it, but the
  # iGPU still composites every frame, so its clocks stay up.
  #
  # The fix is home/refresh-rate.nix, which widens the frame budget by dropping
  # the refresh rate on the lower profiles rather than fighting the governor.
  #
  # ── Do not enable the amdgpu_dpm action ───────────────────────────────
  # `powerprofilesctl list-actions` offers amdgpu_dpm, "Adjust GPU dynamic
  # power management", and it is disabled. Leave it that way. It writes
  # power_dpm_force_performance_level, and its mapping is power-saver -> "low",
  # balanced and performance -> "auto". It never writes "high". Enabling it
  # cannot raise the clocks on any profile, and on power-saver it would hard
  # lock the iGPU at level 0 with no ramp at all, which is strictly worse than
  # the "auto" it sits at today.

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
