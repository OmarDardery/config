# Pinned Noctalia Plugins

Home Manager supplies Screen Toolkit, Nix Monitor, Phone Connect, Pomodoro,
Tailscale and Game Launcher from the community revision locked in `flake.lock`.
The implicit local directories under `$XDG_DATA_HOME/noctalia/plugins` take
precedence over downloaded sources. Git sources are disabled and automatic
plugin updates are off. Tailscale is available but not enabled; Nix Monitor is
enabled only on NixOS. Game Launcher repairs a widget that previously referenced
an unavailable plugin.

Native Noctalia's GUI state overrides declarative settings, including enabled
plugin lists. Existing state was not modified. Back it up and selectively
reconcile it as described in the root README. Source pinning does not disable
the settings GUI or make external services reproducible.

## Patches

- Screen Toolkit allocates a random mode-0700 directory per service instance.
  Capture paths, previews, palette sharing and script environments use that
  directory. Captures fail closed until allocation succeeds.
- Umbriel window annotation selects the single active identifier from
  `umbriel windows --json` and uses `grim -T` for isolated client capture, not a
  geometry crop. The passed preview target and existing editor/Satty handoff are
  preserved, as are the cursor environment flags. Generic Niri/Hyprland adapters
  remain available; Umbriel does not depend on them.
- OCR, Umbriel/Niri staging, GIF conversion and Lens upload scratch space use private
  `mktemp` directories and exit/signal cleanup traps. Missing temporary-directory
  configuration is rejected rather than reverting to predictable global paths.
- Nix Monitor no longer reads PID files to issue shell-interpolated kill commands.
  Captured processes, callbacks and host-owned process-group timeouts control
  check completion. Branches/output paths are quoted. The update action rebuilds
  the configured checkout without implicitly changing its lockfile.
- Nix Monitor ticks every ten seconds and checks the deployed local revision
  once per minute. Expensive store scanning remains disabled. Destructive cleanup
  and duplicate store-optimization buttons are hidden in declarative settings.
- Game Launcher's C helper is compiled with the pinned Nix toolchain and shipped
  with the plugin. Its readiness check no longer attempts to remove/recompile
  that helper based on a mutable build tag. A global runtime C compiler is not
  required by this plugin.

## Limits

- Plugins are trusted unsandboxed code, not a security boundary. This is targeted
  hardening, not a comprehensive audit of all six plugins.
- Screen Toolkit instance directories remain for previews, external editors and
  detached recordings until system temporary-file cleanup. SIGKILL cannot run
  shell cleanup traps. Old predictable-path results are not migrated or deleted.
- Recording stop still uses upstream `pkill -f`, now scoped by a randomized
  capture path. It is not process-handle-based; other recording lifecycle and
  concurrency limitations remain.
- The locked Noctalia host exposes no cancellation handle and caps captured
  subprocess timeouts at 60 seconds. Manual Nix Monitor cancellation is disabled;
  longer checks can time out. Screen Toolkit conversions have the same host limit.
- External commands and services remain dependencies. Shared Home Manager
  supplies capture tools, KDE Connect, SSHFS and audio helpers; native Bluetooth,
  audio, permissions and remote-device services still need host support.
- Google Lens/share actions upload data externally. Do not use them for sensitive
  captures just because local scratch storage has been hardened.

## Verification

The derivation applies the patches, compiles the Game Launcher helper, checks
Screen Toolkit shell syntax, compiles Screen Toolkit/Nix Monitor/Game Launcher
Luau and runs sandboxed mocked tests for missing-directory rejection, Umbriel
identifier selection, cursor flags, private staging permissions, passed preview
handoff and cleanup on IPC/JSON/capture/publication errors, plus Niri preview
handoff and OCR/Lens/GIF scratch cleanup. Tests use real jq and mocked compositor
and capture commands. Sources are resolved from the current `path:` flake input,
pinned at `aa42b35d2e89550bd2d516718f2c29bccddbe0dc`. No real capture/upload, phone connection, recording
or graphical plugin operation was tested.
