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
  boot.kernelPackages = pkgs.linuxPackages;
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
    nvidia = {

      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspe>
      # Enable this if you have graphical corruption issues or applicati>
      # up from sleep. This fixes it by saving the entire VRAM memory to>
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or new>
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused wit>
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full l>
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpu>
      # Only available from driver 515.43.04+
      open = false;

      # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver versio>
        
    };
  };
  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/6f5c1aad-2941-47f2-814b-b54123367d7b";  # Replace with your actual device identifier
    fsType = "ext4";       # Replace with the appropriate filesystem type
    options = [ # If you don't have this options attribute, it'll default to "defaults" 
     # boot options for fstab. Search up fstab mount options you can use
     #"users"  Allows any user to mount and unmount
     "nofail" # Prevent system from failing if this drive doesn't mount
     
   ];
  };
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia" "amdgpu"];

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
    arduino-cli
    fastfetch
    xwayland-satellite
    protonup-ng
    bibata-cursors
    jetbrains.rust-rover
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
