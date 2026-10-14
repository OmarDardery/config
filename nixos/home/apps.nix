{
  pkgs,
  inputs,
  config,
  isLaptop,
  ...
}:
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
  # Install only the tools used by this desktop, not GNOME's full app bundle.
  desktopApps = with pkgs; [
    thunar # file browsing; default handler and Mod+E
    (papers.override { supportNautilus = false; }) # PDF viewer without Nautilus integration
    gnome-calculator # desktop calculator
    gnome-disk-utility # disk/device management
    gnome-control-center # settings for the GNOME fallback
    seahorse # credential manager and SSH askpass
  ];
  # D-Bus activation supports mounts/trash, thumbnails and Thunar preferences.
  desktopServices =
    desktopApps
    ++ (with pkgs; [
      gvfs
      tumbler
      xfconf
    ]);

in
{
  # Keep desktop search, but avoid generated dependency/build trees.
  # Preserve the pinned indexer's standard exclusions and repository markers.
  dconf.settings."org/freedesktop/tracker/miner/files".ignored-directories = [
    "po"
    "CVS"
    "core-dumps"
    "lost+found"
    "node_modules"
    "target"
    "build"
    "dist"
  ];

  dbus.packages = desktopServices;
  systemd.user.packages = desktopServices;
  home.sessionSearchVariables.GIO_EXTRA_MODULES = [ "${pkgs.gvfs}/lib/gio/modules" ];
  # Native GNOME consumers also need the schemas, not just wrapped app binaries.
  home.sessionSearchVariables.XDG_DATA_DIRS = [
    "${config.home.profileDirectory}/share"
  ]
  ++ map (p: "${p}/share/gsettings-schemas/${p.name}") desktopApps;
  # Preserve the askpass choice previously supplied by programs.seahorse.
  home.sessionVariables.SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "text/html" = [ "zen.desktop" ];
      "application/xhtml+xml" = [ "zen.desktop" ];
      "x-scheme-handler/http" = [ "zen.desktop" ];
      "x-scheme-handler/https" = [ "zen.desktop" ];
    };
  };
  programs.bash.enableVteIntegration = true;
  programs.zsh.enableVteIntegration = true;

  home.packages =
    with pkgs;
    [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.webos-dev-manager.packages.${pkgs.stdenv.hostPlatform.system}.webos-dev-manager
      kitty
      (if isLaptop then blenderNvidia else pkgs.blender)
      freecad
      # The gtk3-default build, not libreoffice-qt — see SAL_USE_VCLPLUGIN below
      # for why the VCL backend decides whether Impress can present onto HDMI.
      libreoffice
      hunspell
      hunspellDicts.en_US # hunspell ships no dictionaries of its own
      rnote
      proton-vpn
      protonup-ng
      fastfetch
      unzip
      lshw
      zenity
      # Media and viewers. There was previously no video player, image viewer or
      # PDF viewer installed at all.
      mpv
      imv
      wireshark # capture privileges remain the native host's responsibility
      gpu-screen-recorder # NixOS provides the restricted KMS helper wrapper

      # Session controls, for the noctalia bar and the media keys.
      pavucontrol
      brightnessctl
      playerctl
      opencode

      # ── Chat ───────────────────────────────────────────────────────────
      # Official: the derivation fetches from stable.dl2.discordapp.net, which is
      # Discord's own CDN, not a repackage.
      discord
      # Windows apps in a container. Needs Docker socket (virtualisation.docker).
      # KVM needs nothing: /dev/kvm and /dev/net/tun are already world-accessible here.
      #
      # The Windows guest wants 4 GB minimum and this machine has 14 GiB, so
      # expect to be swapping into zram with a browser and an IDE already open.
      winboat
      logisim-evolution
      (callPackage ../pkgs/antigravity-cli.nix { })
    ]
    ++ desktopServices;
  home.sessionVariables = {
    BROWSER = "zen";
    # Impress's GTK3 backend passes the selected Wayland output when presenting;
    # its Qt backend fullscreened slides on the primary display instead.
    # A fresh login is required for this session variable.
    SAL_USE_VCLPLUGIN = "gtk3";
  };
}
