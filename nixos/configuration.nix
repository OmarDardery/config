# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./display-manager.nix
      ./noctalia.nix
      ./zsh.nix
      ./gaming.nix
      ./productivity.nix
    ];
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  programs.localsend.enable = true;
  #tailscale
  services.tailscale.enable = true;
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  systemd.services.tailscaled.serviceConfig.Environment = [ 
    "TS_DEBUG_FIREWALL_MODE=nftables" 
  ];

  # 3. Optimization: Prevent systemd from waiting for network online 
  # (Optional but recommended for faster boot with VPNs)
  systemd.network.wait-online.enable = false; 
  boot.initrd.systemd.network.wait-online.enable = false;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; }; #If you want acc>
    backupFileExtension = "bak"; 
    users.oad = ./home.nix; # replace <USERNAME> with your a>
  };
  
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "uinput"];
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.flatpak.enable = true;
  # Rootless containers; dockerCompat adds a `docker` alias for muscle memory,
  # dns_enabled lets containers on the same network resolve each other by name.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # Enable OpenGL
  hardware = {
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
      # Same derivation as .stable on this nixpkgs (both 595.71.05), so this
      # line is currently a no-op. Harmless as documentation of intent.
      package = config.boot.kernelPackages.nvidiaPackages.latest;

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
  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/71d4d606-a6ef-42bb-b63c-8f5a8fee4b24";
    fsType = "xfs";
    options = [ # If you don't have this options attribute, it'll default to "defaults" 
     # boot options for fstab. Search up fstab mount options you can use
     #"users"  Allows any user to mount and unmount
     "nofail" # Prevent system from failing if this drive doesn't mount
     
   ];
  };
  # Order matters for PRIME offload: the iGPU driver must come FIRST, otherwise
  # the X server runs permanently on the dGPU and it never sleeps (visible as
  # a non-idle GPU in `nvidia-smi`).
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  # Enable networking
  networking.networkmanager.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.niri.enable = true;
  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service
  security.pam.services.swaylock = {};
  # Set your time zone.
  time.timeZone = "Africa/Cairo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ar_EG.UTF-8";
    LC_IDENTIFICATION = "ar_EG.UTF-8";
    LC_MEASUREMENT = "ar_EG.UTF-8";
    LC_MONETARY = "ar_EG.UTF-8";
    LC_NAME = "ar_EG.UTF-8";
    LC_NUMERIC = "ar_EG.UTF-8";
    LC_PAPER = "ar_EG.UTF-8";
    LC_TELEPHONE = "ar_EG.UTF-8";
    LC_TIME = "ar_EG.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  
  #yazii
  programs.yazi.enable = true;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."oad" = {
    isNormalUser = true;
    description = "Omar Dardery";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };
  programs.nix-ld.enable = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  services.udev.packages = [ pkgs.platformio-core.udev ];
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    kitty
    git
    unzip
    starship
    zed-editor
    rustup
    gcc
    zsh
    platformio-core
    clang-tools
    go
    bun
    uv
    lshw
    arduino-cli
    fastfetch
    xwayland-satellite
    protonup-ng
    bibata-cursors
    jetbrains-toolbox
    nerd-fonts.jetbrains-mono
    proton-vpn
    #flakes
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    # Foreign binaries (Zed, etc.) hardcode /usr/share/X11/xkb for keyboard layout
    # data, which doesn't exist on NixOS (no /usr). This is libxkbcommon's own
    # documented override for that lookup, pointed at the real Nix store path.
    XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
    BUN_INSTALL = "$HOME/.bun";
    PATH = "$HOME/.local/bin:$PATH";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
