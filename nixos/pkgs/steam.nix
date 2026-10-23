{
  pkgs,
  millenniumInput,
  colorsFile ? null,
}:
assert pkgs.stdenv.hostPlatform.system == "x86_64-linux";
let
  millennium = millenniumInput.packages.x86_64-linux.millennium;
  # Keep Steam's FHS glibc and Millennium's compiled libraries on the same pin.
  runtimePkgs = import millenniumInput.inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  material =
    pkgs.runCommand "noctalia-steam-material-1.5.16"
      {
        src = pkgs.fetchFromGitHub {
          owner = "kuska1";
          repo = "Material-Theme";
          rev = "f91b4e9cbc5436f149e6b293391a9a96ab47fbe9";
          hash = "sha256-qPzo59NyKsmKkhupOf3n9X29p/Wbv7jaKDGaM23HTJo=";
        };
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
  inherit millennium material;
  # Same environment/libraries as upstream packages/nix/steam.nix, without
  # its unconditional ln -sf in extraProfile. Bootstrap setup is opt-in below.
  steam = runtimePkgs.steam.override {
    # steamwebhelper's container cannot resolve /run/current-system/sw paths.
    extraProfile = ''
      export XCURSOR_PATH="${pkgs.bibata-cursors}/share/icons:${pkgs.adwaita-icon-theme}/share/icons''${XCURSOR_PATH:+:$XCURSOR_PATH}"
    '';
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
        pkgs.python3
      ];
      text = ''
        if [[ $# -gt 1 || ( $# -eq 1 && "$1" != --apply ) ]]; then
          printf 'Usage: noctalia-steam-setup [--apply]\n' >&2
          exit 2
        fi
        if pgrep -u "$(id -u)" -x 'steam|steamwebhelper' >/dev/null; then
          printf 'Exit Steam completely before setup.\n' >&2
          exit 1
        fi
        exec python3 ${./steam-setup.py} \
          ${pkgs.lib.escapeShellArg colorsFile} \
          "${millennium}/lib/libmillennium_bootstrap_x86.so" \
          "${millennium}/lib/libmillennium_bootstrap_hhx64.so" \
          "${material}" "$@"
      '';
    };
}
