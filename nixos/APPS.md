# Apps outside the system config

A Nix profile is your personal list of installed packages. `nix profile add`
adds an app, puts its commands on your user PATH, and creates a profile generation.
It does not edit this repository or need a NixOS rebuild. Run these commands as
your normal user, without sudo. The apps persist across system rebuilds and
remain managed independently of the system generation.

Browse available packages at [NixOS Search](https://search.nixos.org/packages).
Select the 26.05 channel to match the examples. Or search from the terminal:

```sh
nix search github:NixOS/nixpkgs/nixos-26.05 audacity
```

For example, install Audacity outside your system configuration:

```sh
nix profile add github:NixOS/nixpkgs/nixos-26.05#audacity
```

`nix profile install` is an alias for `add` and works on older Nix releases too.
The branch reference tracks stable package updates; a fixed commit stays pinned.

## Browse, update and remove installed apps

```sh
# Only apps explicitly installed in this profile, with names and source revisions
nix profile list
# Machine-readable list
nix profile list --json
# Remove an app using its exact Name from the list
nix profile remove audacity
# Update one app, or every app in the profile
nix profile upgrade audacity
nix profile upgrade --all
```

The list contains top-level profile entries, not every dependency in the store.
It does not list NixOS/Home Manager packages, Flatpaks or apps in other profiles.
Removing a profile entry cannot remove a system-managed copy. Avoid installing
the same app through both the config and a profile: decide which should own it.
Nix shares identical store paths, but duplicate ownership can make it unclear
which copy runs. `command -v APP` shows the executable selected by your PATH.

Removing an app unlinks it from the active profile. Your documents/preferences
are kept, and old profile generations may keep its package data in the store.

## History and space

```sh
nix profile history
nix profile rollback
# Optional: discard profile generations older than 30 days, then collect garbage
nix profile wipe-history --older-than 30d
nix store gc
```

Rollback changes the whole profile to the previous generation, not just one app.
Wiping history removes the ability to roll back to those old generations.
Garbage collection only removes store paths no longer referenced by any retained
profile/system generation or another garbage-collection root. It does not delete
application preferences from your home directory. Do not manually delete `/nix/store`.

For a one-off command, use `nix run github:NixOS/nixpkgs/nixos-26.05#hello` or
`nix shell github:NixOS/nixpkgs/nixos-26.05#hello`. These do not add profile entries.
For project tools, use that project's `shell.nix` and `nix-shell`.

Profiles install application packages, not NixOS service configuration. Drivers,
privileged access, udev rules, firewall rules and services belong in NixOS even
when the related app is installed manually. Unfree packages may require an
explicit licence opt-in for a profile; the system's `allowUnfree` policy does not
automatically apply to a separately evaluated Nixpkgs flake.

References: [add](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-profile-add.html),
[list](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-profile-list.html),
[remove](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-profile-remove.html),
[upgrade](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-profile-upgrade.html),
[history cleanup](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-profile-wipe-history.html).
