{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Google Antigravity CLI, built from ../pkgs/antigravity-cli.nix via the
    # overlay in configuration.nix. Installs the binary as `agy`.
    antigravity-cli
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    kitty
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
    papers
    nautilus # also makes the nautilus window-rule in dotfiles/niri/cfg/rules.kdl live

    # Session controls, for the noctalia bar and the media keys.
    pavucontrol
    brightnessctl
    playerctl

    # ── Chat ───────────────────────────────────────────────────────────
    # Official: the derivation fetches from stable.dl2.discordapp.net, which is
    # Discord's own CDN, not a repackage.
    discord
    # WhatsApp has NO official Linux desktop client — the only official surfaces
    # are the phone apps, web.whatsapp.com, and the Windows/macOS builds. ZapZap
    # is a third-party Qt shell around the official WhatsApp Web, built from its
    # real upstream (github.com/rafatosta/zapzap, rtosta.com/zapzap). It buys
    # native notifications and a tray icon over a browser tab; it does not make
    # anything more official than the web app it wraps.
    #zapzap
    # Windows apps in a container. Needs Docker socket (virtualisation.docker).
    # KVM needs nothing: /dev/kvm and /dev/net/tun are already world-accessible here.
    #
    # The Windows guest wants 4 GB minimum and this machine has 14 GiB, so
    # expect to be swapping into zram with a browser and an IDE already open.
    winboat
  ];

  home.sessionVariables = {
    # ── Why "click Present" lands on the projector ─────────────────────────
    # Under Wayland a client cannot position its own windows. The one exception
    # is xdg_toplevel.set_fullscreen, which takes an optional wl_output argument
    # meaning "fullscreen me on THAT monitor". GTK3 exposes it as
    # gtk_window_fullscreen_on_monitor(), and LibreOffice's gtk3 VCL backend
    # calls it when Impress starts a presentation. Qt has no equivalent path on
    # Wayland — showFullScreen only ever takes effect on the main screen,
    # because Qt never passes an output to the compositor. So under the Qt
    # backend the slides fullscreen on the laptop panel no matter what the
    # "Presentation display" dropdown says, which is why this previously needed
    # wl-mirror to work around.
    #
    # This was never a niri problem: Fedora presented correctly under the same
    # compositor because its LibreOffice defaults to gtk3. The build installed
    # here ships all four backends (gtk3, qt6, kf6, gen) and picks one at
    # runtime by autodetecting the desktop — and niri is not a desktop it
    # recognises. Naming the backend removes the guess.
    #
    # Session variable: needs a fresh LOGIN, not just a rebuild.
    SAL_USE_VCLPLUGIN = "gtk3";

    # Where protonup-ng installs Proton-GE builds for Steam to pick up.
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };
}
