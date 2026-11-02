# Native Linux dotfiles

This directory is independent of the NixOS flake: one small flake, its own lock,
a Git/Python installer and plain editable dotfiles. It does not use Home Manager.

```sh
nix run 'github:OmarDardery/config?dir=non-nixos'
nix run 'github:OmarDardery/config?dir=non-nixos#update'
```

Run as your normal user with Nix installed, on x86_64 or aarch64 Linux. Add
`--extra-experimental-features 'nix-command flakes'` before `run` if needed.
The default checkout is `~/config`; add `-- --repo-dir ~/dotfiles` to change it.
Use `-- OWNER/REPO` for a fork with this layout, and `--ref BRANCH` for a new
checkout at another revision. Existing origins must match an explicitly selected repo.

Install the applications through your distro. The starter follows [LazyVim’s requirements](https://www.lazyvim.org/) and expects a
Neovim/LazyVim-compatible version (Neovim 0.11.2+ built with LuaJIT), Git, ripgrep and fd;
VSCodium's native `codium` executable; Kitty; Umbriel; and **Noctalia v5**
(the Rust/TOML release, rather than the legacy Quickshell shell).
Umbriel/Noctalia config syntax is checked against the versions pinned by the
NixOS flake. Native package versions may differ; validate with your own binaries:

```sh
umbriel config validate -c ~/.config/umbriel/config.toml
noctalia config validate ~/.config/noctalia/config.toml
```

| Source under `dotfiles/` | Destination under `$XDG_CONFIG_HOME` |
| --- | --- |
| `nvim/` | `nvim/` |
| `VSCodium/User/settings.json` | `VSCodium/User/settings.json` |
| `umbriel/config.toml` | `umbriel/config.toml` |
| `noctalia/config.toml` | `noctalia/config.toml` |

`XDG_CONFIG_HOME` defaults to `~/.config`. Nothing else is configured. The
installer does not select a login session or start/restart applications. Select
your distro's Umbriel session yourself; it starts Noctalia via autostart. Configs
include English/Arabic input, a bottom bar, a right dock and common app shortcuts.
Noctalia's native Umbriel template handles colors. Other app themes and plugins
can be configured through their own interfaces. No VSCodium extensions are installed.
LazyVim downloads plugins into user data on first use; language tools are left to
your distro or projects. Mason and parser compilation start disabled.

Existing files are backed up on first apply. Old Home Manager directory links are
backed up and materialized as writable directories; store targets are untouched.
Later applies replace a file only if it still matches the previously applied
version. Local edits and deletions are preserved and reported. Unrelated files
are retained. Source files removed from the repo are not automatically deleted.
Edit installed files for local preferences; edit and commit source files to share
changes across your machines. To reseed all defaults, move aside the installer's
`files.json` and apply again; current conflicts will be backed up.

State and backups live under `$XDG_STATE_HOME/non-nixos-config/` (default
`~/.local/state/non-nixos-config/`). Restore an individual backup by copying it
over its destination after closing the relevant app. State is separate from the
NixOS launcher and no account/hardware files are generated.

Normal apply never pulls commits. `#update` fast-forwards the checkout from its
current upstream, refuses tracked local source edits, then applies unedited
files. Commit source edits before updating. If the pull fails, no dotfiles change.
It does not refresh NixOS inputs, rebuild a system or update native applications.
To update just the installer's Nix dependency, run `nix flake update` in this
directory. The root's dev shells/templates remain separately usable on Linux;
this installer does not add shell hooks or tooling.

Native references: [Umbriel config](https://docs.noctalia.dev/umbriel/configuration/) ·
[Noctalia’s Umbriel template](https://docs.noctalia.dev/noctalia/templates/official/umbriel/).
