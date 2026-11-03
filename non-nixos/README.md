# Native Linux dotfiles

```sh
curl -fsSL https://raw.githubusercontent.com/OmarDardery/config/main/setup.sh | bash
```

Requires distro-installed Bash, curl, Git and Python 3.10+. Nix is optional; no
Home Manager is used. Run as your normal user. Default checkout: `~/config`.
From an existing checkout use `bash setup.sh` or `python3 non-nixos/apply.py`.

The installer configures these files and installs two small commands in
`~/.local/bin`. It never installs applications, fonts, extensions, drivers or
services, changes your login shell, or starts/restarts apps. Apps stay under your
distro's native package manager. LazyVim fetches its plugins when first opened.

| Source under `dotfiles/` | Destination |
| --- | --- |
| `nvim/` | `$XDG_CONFIG_HOME/nvim/` |
| `VSCodium/User/settings.json` | `$XDG_CONFIG_HOME/VSCodium/User/settings.json` |
| `umbriel/config.toml` | `$XDG_CONFIG_HOME/umbriel/config.toml` |
| `noctalia/config.toml` | `$XDG_CONFIG_HOME/noctalia/config.toml` |
| `kitty/kitty.conf` | `$XDG_CONFIG_HOME/kitty/kitty.conf` |
| `starship.toml` | `$XDG_CONFIG_HOME/starship.toml` |
| `zsh/.zshrc` | `$ZDOTDIR/.zshrc`, or `~/.zshrc` when unset |

`XDG_CONFIG_HOME` defaults to `~/.config`. Native prerequisites:

- Neovim 0.11.2+ with LuaJIT, Git, ripgrep and fd for LazyVim.
- VSCodium (`codium`), Kitty, Starship and Zsh for their respective dotfiles.
- Umbriel and **Noctalia v5** (Rust/TOML, rather than the legacy Quickshell shell).
- Optional JetBrainsMono Nerd Font; optional zoxide/direnv for shell integrations.

These are app requirements, not packages the installer installs. Distro package
names and availability differ; use native packages compatible with these configs.
Noctalia/Umbriel syntax is also checked against the NixOS flake's pinned versions.
Validate against the actual native binaries after installing them:

```sh
umbriel config validate -c ~/.config/umbriel/config.toml
noctalia config validate ~/.config/noctalia/config.toml
```

Choose Umbriel at login; it starts Noctalia directly. The defaults include
English/Arabic input, a bottom bar that reserves space, and a right dock.
Noctalia's native Umbriel template handles compositor colors. Kitty uses its
normal palette until a `noctalia*.conf` palette is present. Starship is configured
statically; Zsh initializes it only when the native executable exists. Zsh also
adds `~/.local/bin` to `PATH`. Start `zsh` to use it; selecting it as the login
shell is your choice. Machine-specific shell additions belong in `.zshrc.local`.

## Apply and update

```sh
~/.local/bin/config-apply
~/.local/bin/config-update
```

In a new Zsh session, `up` and `update` are aliases for these commands. Apply uses
the checkout as-is. Update runs `git pull --ff-only` and applies unedited defaults;
it refuses tracked source edits or a diverged checkout. Native app updates stay
with your distro. No flake operation is needed for this Nix-free path.

Existing files are backed up on first apply. Later applies preserve local edits
and deletions; unrelated files remain untouched. Old Home Manager directory links
are backed up and materialized as writable directories. Source files removed from
the repo are not automatically deleted. VSCodium extensions and keybindings stay
yours. Mason and Tree-sitter compilation start disabled; project tooling belongs
in project environments or native packages.

State and backups live under `$XDG_STATE_HOME/non-nixos-config/`, default
`~/.local/state/non-nixos-config/`. Restore files by copying from a backup after
closing the app. To reseed defaults, move aside `files.json` and apply again;
current conflicts will be backed up. Launcher replacements are backed up too.

For an existing Nix installation, these optional commands still work:

```sh
nix run 'github:OmarDardery/config?dir=non-nixos'
nix run 'github:OmarDardery/config?dir=non-nixos#update'
```

Use `-- --repo-dir ~/dotfiles` for another checkout, `-- OWNER/REPO` for a fork,
and `--ref BRANCH` only for a new clone. Source URLs must identify the same branch
as `--ref` when testing an unmerged launcher. The small flake is independent of the
NixOS system and installs only its Git/Python launcher dependencies into the Nix store.
