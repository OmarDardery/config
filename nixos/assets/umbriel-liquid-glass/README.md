# Umbriel Liquid Glass shaders

Four self-contained GLSL ES 1.00 shaders for the Umbriel revision pinned in `nixos/flake.nix`.

- `border.glsl`: static silver/Noctalia-accent reflective rim on the focused window.
- `window.glsl`: subtle lens distortion and a fade for opening and closing windows.
- `workspace.glsl`: refracted workspace reveal with exact transition endpoints.
- `cursor.glsl`: optional, palette-tinted cursor halo (off by default).

`effects.toml` registers the presets, and `nixos/home/umbriel.nix` activates the first three.
The shaders use supported Umbriel uniforms and return premultiplied RGBA.
No temporal feedback buffers, full-screen shaders, drag physics or unbounded loops.

## Activating

On the NixOS host, pull the branch or merge the PR and run:

```sh
sudo nixos-rebuild switch --flake ~/config/nixos#nixos
umbriel config validate -c ~/.config/umbriel/config.toml
umbriel effects
```

Noctalia remains the source of wallpaper-dependent accent colors. It already manages
the shell's glass panel mode and the dynamic Umbriel palette template. For a stronger
frosted look, use translucent application backgrounds (Kitty already has one);
a shader cannot recover background pixels hidden by an opaque application.

To try the optional cursor halo:

```sh
umbriel msg effect-cursor-set liquid-glass-cursor
umbriel msg effect-cursor-reset
```

Cursor effects disable direct scanout on their output. The normal configuration
does not activate any whole-screen or persistent per-window shaders, retaining
fullscreen gaming performance. To disable the border temporarily:

```sh
umbriel msg effect-border-toggle
umbriel msg effect-border-reset
```

These are compositor-side effects, not a replacement for native blur. Actual
appearance and shader compilation must be verified in an Umbriel session.
