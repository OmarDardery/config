# Standalone Home Manager

```sh
nix --extra-experimental-features 'nix-command flakes' run github:OmarDardery/config
```

Run as your normal Linux user with Nix installed. Supports x86_64 and aarch64.
The launcher clones into `~/config`, records the local identity once, then runs
ordinary `home-manager switch`. Nix supplies the bootstrap tools; no separate
Home Manager installation is needed. From a checkout, use `bash setup.sh`.

| Managed with Nix | Kept with your distro |
| --- | --- |
| VSCodium, Neovim, Git, ripgrep, fd, nixd and nixfmt | Umbriel, Noctalia, Kitty, Starship and Zsh binaries |
| VSCodium settings and two declared extensions | Drivers, login manager, desktop session and system services |
| LazyVim starter and Nix language support | Project language toolchains |
| Desktop, terminal and shell dotfiles | Optional zoxide/direnv binaries |

The structure follows standalone Home Manager conventions: `homeConfigurations`,
a small `home/default.nix`, and shared `home/editors/` modules. The editor modules
are also imported by NixOS. `targets.genericLinux.enable` supplies integration
for other Linux distributions. There is no custom file-copy engine or manifest.

## Apply and update

| Command | Action |
| --- | --- |
| `config-apply` / `rebuild` | Apply the current checkout |
| `up` | Update this flake's lockfile, then apply |
| `config-apply --build-only` | Build a generation without activating |
| `home-manager generations` | List generations, including their activation paths |

`up` preserves source edits and does not pull Git commits. Get repository changes
with `git -C ~/config pull --ff-only`, then run `up`. Native apps still update
through your distro. Restart Zsh after the first activation. In another shell,
source `~/.nix-profile/etc/profile.d/hm-session-vars.sh` to load the environment.

Use `--repo-dir DIR` for a different checkout, `-- OWNER/REPO` for a fork, and
`--ref BRANCH` only for a new clone. Select that branch in the initial `nix run`
URL too when testing an unmerged branch. Existing repositories are not switched.
The independent entry point is:

```sh
nix run 'github:OmarDardery/config?dir=non-nixos'
```

Direct Home Manager use is also supported after bootstrapping:

```sh
home-manager switch --flake "path:$HOME/config/non-nixos#$(id -un)"
```

`local-profile.json` records the user, home, architecture, checkout, XDG directories,
Zsh directory and initial state version. It stays out of Git. Keep `stateVersion`
when updating; edit `configRepo` if you move the checkout. `path:` includes this
ignored file. Flake evaluation stays pure and does not read identity from the
calling shell. No shared development shells or global language runtimes are added.

## Migration and edits

Home Manager owns the configured files as store symlinks. Edit their sources in
this repository and apply again. Existing conflicting files are backed up beside
the originals with a unique `.before-home-manager-*` suffix. The previous copier's
backups under `~/.local/state/non-nixos-config/backups` remain available.
Old `~/.local/bin/config-apply` launchers continue to use the new entry point.

Configured Neovim files are linked individually, so additional Lua files remain
yours. LazyVim downloads plugins on first use. Mason and Tree-sitter compilation
start disabled; project language tools belong in each project's environment.
VSCodium's configured settings/extensions are declarative; unrelated keybindings
remain untouched. Put native shell additions in `.zshrc.local`.

No desktop apps are started or restarted by activation. Select Umbriel at login;
it launches Noctalia directly. Use a compatible native Umbriel and Noctalia v5.
Validate native configs after installation:

```sh
umbriel config validate -c ~/.config/umbriel/config.toml
noctalia config validate ~/.config/noctalia/config.toml
```

For GUI driver integration, follow Home Manager's `targets.genericLinux.gpu`
activation guidance if it reports missing integration. Proprietary NVIDIA
libraries must match the distro's driver; the NixOS NVIDIA pin is not reused.

To roll back, run an earlier generation's `activate` script shown by
`home-manager generations`. This rolls back packages and managed files;
application data remains in your home.

References: [Misterio77's starter](https://github.com/Misterio77/nix-starter-configs/tree/main/minimal),
[GooseRooster's standalone configs](https://github.com/GooseRooster/home-manager),
and the [Home Manager manual](https://nix-community.github.io/home-manager/installation/standalone.html).
