{
  pkgs,
  millenniumInput,
  colorsFile ? null,
}:
assert pkgs.stdenv.hostPlatform.system == "x86_64-linux";
let
  sources = import ./steam-sources.nix;
  millennium = millenniumInput.packages.x86_64-linux.millennium;
  # Keep Steam's FHS glibc and Millennium's compiled libraries on the same pin.
  runtimePkgs = import millenniumInput.inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  material =
    pkgs.runCommand "noctalia-steam-material-1.5.16"
      {
        src = pkgs.fetchFromGitHub sources.material;
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        cp -r "$src" "$out"
        chmod -R u+w "$out"
        # Keep the upstream directory name: matugen.js hardcodes Material-Theme.
        # Nix owns updates; do not advertise this deployment to the theme updater.
        jq 'del(.github) | .Conditions.Color.default = "Matugen"' "$src/skin.json" > "$out/skin.json"
        rm "$out/css/main/colors/matugen.css"
        ln -s ${pkgs.lib.escapeShellArg colorsFile} "$out/css/main/colors/matugen.css"
      '';
in
{
  inherit millennium;
  # Same environment/libraries as upstream packages/nix/steam.nix, without
  # its unconditional ln -sf in extraProfile. Bootstrap setup is opt-in below.
  steam = runtimePkgs.steam.override {
    extraLibraries = _: [
      millennium
      runtimePkgs.openssl
      runtimePkgs.pkgsi686Linux.openssl
    ];
    extraEnv.MILLENNIUM_RUNTIME_PATH = "${millennium}/lib/libmillennium_x86.so";
  };

  setup =
    assert colorsFile != null && pkgs.lib.hasPrefix "/" colorsFile;
    pkgs.writeShellApplication {
      name = "noctalia-steam-setup";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.procps
      ];
      text = ''
        if [[ $# -gt 1 || ( $# -eq 1 && "$1" != --apply ) ]]; then
          printf 'Usage: noctalia-steam-setup [--apply]\n' >&2
          exit 2
        fi
        apply=false
        if [[ $# -eq 1 ]]; then apply=true; fi
        if pgrep -u "$(id -u)" -x 'steam|steamwebhelper' >/dev/null; then
          printf 'Exit Steam completely before setup.\n' >&2
          exit 1
        fi
        root="$HOME/.steam/steam"
        if [[ ! -f "$root/ubuntu12_32/steam" || ! -d "$root/ubuntu12_64" ]]; then
          printf 'Initialize Steam normally first; expected client at %s.\n' "$root" >&2
          exit 1
        fi
        if [[ ! -s ${pkgs.lib.escapeShellArg colorsFile} ]]; then
          printf 'Render Noctalia steam.css before setup: %s\n' ${pkgs.lib.escapeShellArg colorsFile} >&2
          exit 1
        fi
        destinations=(
          "$root/ubuntu12_32/libXtst.so.6"
          "$root/ubuntu12_64/libXtst.so.6"
          "$root/millennium/themes/Material-Theme"
        )
        targets=(
          "${millennium}/lib/libmillennium_bootstrap_x86.so"
          "${millennium}/lib/libmillennium_bootstrap_hhx64.so"
          "${material}"
        )
        # Validate every destination before making any changes. Never replace
        # an existing user theme, library, or non-managed symlink.
        for i in "''${!destinations[@]}"; do
          dest="''${destinations[$i]}"
          if [[ -e "$dest" || -L "$dest" ]]; then
            old=$(readlink "$dest" || true)
            case "$i:$old" in
              0:/nix/store/*-millennium-*/lib/libmillennium_bootstrap_x86.so) ;;
              1:/nix/store/*-millennium-*/lib/libmillennium_bootstrap_hhx64.so) ;;
              2:/nix/store/*-noctalia-steam-material-*) ;;
              *) printf 'Refusing to replace unmanaged path: %s\n' "$dest" >&2; exit 1 ;;
            esac
          fi
          printf '%s -> %s\n' "$dest" "''${targets[$i]}"
        done
        if ! "$apply"; then
          printf 'Preview only. Run with --apply to create these links.\n'
          exit 0
        fi
        mkdir -p "$root/millennium/themes"
        for i in "''${!destinations[@]}"; do
          ln -sfnT "''${targets[$i]}" "''${destinations[$i]}"
        done
        printf 'Select Material in Millennium, then Color = Matugen. No settings were changed.\n'
      '';
    };
}
