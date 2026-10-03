# Steam / Millennium / Noctalia

## Integration

`nixos/flake.nix` already declares the pinned Millennium input. Do not make
Millennium's inputs follow the host nixpkgs. Its upstream lock pins
the build nixpkgs, source and Bun nixpkgs separately. Bun dependency hashes are
version-sensitive. The pinned upstream revision includes the fix from PR #919.

`home/steam.nix` owns Steam, steam-run, Millennium, the setup helper, and the
compatibility-tools path on both NixOS and standalone Linux. It is imported by
`home/default.nix`; Home Manager receives `inputs` and `isNixOS` from the flake.
On NixOS, the FHS runtime also receives host graphics libraries and fonts through
`osConfig`. `gaming.nix` retains only host-level GameMode, Steam controller/device
permissions, and 32-bit audio integration; hardware.nix already enables 32-bit
graphics. The NixOS Steam module stays disabled and no Steam ports are opened.
Only x86_64-linux is supported. Standalone hosts still need working native
graphics drivers, 32-bit graphics support and unprivileged user namespaces.

`pkgs/steam.nix` can also be imported directly with `pkgs`, `millenniumInput =
inputs.millennium`, and an absolute `colorsFile`. It returns `steam`,
`millennium`, and `setup` (the latter requires `colorsFile`). Steam uses
Millennium's upstream nixpkgs to keep its FHS glibc compatible with the compiled
libraries, rather than mixing the host Steam runtime with a newer Millennium.

## Initial Setup

1. Initialize Steam normally if it has never run, then exit it completely.
2. Have Noctalia render `${config.xdg.stateHome}/noctalia/theme/steam.css`.
3. Run `noctalia-steam-setup` to preview the three links.
4. Run `noctalia-steam-setup --apply` to opt in while Steam is stopped.
5. Start the configured Steam wrapper. Select **Material** in Millennium's
   theme settings and set **Color = Matugen**. Existing theme preferences may
   override the packaged Matugen default. Set Appearance to match Noctalia.

The helper refuses existing foreign libraries, themes and symlinks. If it
reports a conflict, inspect and back up that path yourself before retrying.
It only updates recognized Nix-managed links. No installer is run, no plugin
is downloaded, and no Steam/Millennium settings, accounts, games or userdata
are replaced. Neither activation nor launching the wrapper installs hooks.
Rerun the helper after updating the package or if Steam repairs/removes hooks.

The links are:

```text
~/.steam/steam/ubuntu12_32/libXtst.so.6 -> Millennium's x86 bootstrap
~/.steam/steam/ubuntu12_64/libXtst.so.6 -> Millennium's hhx64 bootstrap
~/.steam/steam/millennium/themes/Material-Theme -> pinned theme in the store
```

Within that theme, `css/main/colors/matugen.css` is a symlink to Noctalia's
mutable `steam.css`, not a copied store snapshot. Upstream `matugen.js` polls
the local Millennium theme endpoint every 1.5 seconds. Preserve its expected
directory name `Material-Theme`. The generated CSS must use Material's
`--md-sys-color-*` variables as RGB channel triples (see upstream
`matugentemplate.css`), not hex values, plus `--theme-color: "Matugen"`.
The module does not generate CSS or synchronize Appearance settings.

Nix owns theme updates: the packaged skin removes its `github` updater field.
Do not reinstall this theme through Millennium's download UI. To opt out,
exit Steam and remove only the three links above after verifying their
targets; switch back to ordinary Steam. Keep all configuration and userdata.

## Upstream

- https://github.com/SteamClientHomebrew/Millennium/discussions/832
- https://github.com/SteamClientHomebrew/Millennium/pull/919
- https://github.com/SteamClientHomebrew/Millennium/tree/63c3928f0306edd83122c0f5b085a9b1a3d60f55/packages/nix
- https://github.com/kuska1/Material-Theme/tree/f91b4e9cbc5436f149e6b293391a9a96ab47fbe9

Upstream recognizes community Nix packaging, but the core Millennium authors
do not maintain or debug NixOS support. Steam updates can still break runtime
hooks even when these pinned packages build successfully.
