{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Google Antigravity CLI, built from ../pkgs/antigravity-cli.nix via the
    # overlay in configuration.nix. Installs the binary as `agy`.
    antigravity-cli
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    kitty
    libreoffice-qt
    hunspell
    hunspellDicts.en_US # hunspell ships no dictionaries of its own
    rnote
    proton-vpn
    protonup-ng
    fastfetch
    unzip
    lshw

    # Media and viewers. There was previously no video player, image viewer or
    # PDF viewer installed at all.
    mpv
    imv
    papers
    nautilus # also makes the nautilus window-rule in dotfiles/niri/cfg/rules.kdl live

    # Session controls, for the noctalia bar and the media keys.
    pavucontrol
    brightnessctl
    playerctl
    # Windows apps in a container. Needs a container socket — see the podman
    # block in configuration.nix. KVM needs nothing: /dev/kvm and /dev/net/tun
    # are already world-accessible here.
    #
    # The Windows guest wants 4 GB minimum and this machine has 14 GiB, so
    # expect to be swapping into zram with a browser and an IDE already open.
    winboat
  ];

  home.sessionVariables = {
    # Where protonup-ng installs Proton-GE builds for Steam to pick up.
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";

    # Point container tooling — WinBoat, podman-compose, the docker CLI shim —
    # at the rootless podman socket. Without this they look for
    # /run/docker.sock, which is the rootful socket and not ours to use.
    # Written via XDG_RUNTIME_DIR rather than a literal uid so it stays portable.
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
  };
}
