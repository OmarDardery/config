#!/usr/bin/env bash
# Sourced only by bootstrap.sh's explicit host-setup path.

host_setup() {
  local apply_host=$1 LC_ALL=C
  export LC_ALL
  local line key value os_id='' variant='' seen_id=false seen_variant=false
  local version manager_version package state reply
  local -a packages missing=() install_command

  [[ -r /etc/os-release ]] || die 'cannot read /etc/os-release'
  # os-release is data, not shell code. Accept only simple literal ID fields;
  # ignore other keys, and reject duplicates, substitutions and escapes.
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == ID=* || "$line" == VARIANT_ID=* ]] || continue
    key=${line%%=*}
    value=${line#*=}
    if [[ "$value" == \"*\" && ${#value} -ge 2 || "$value" == \'*\' && ${#value} -ge 2 ]]; then
      value=${value:1:${#value}-2}
    fi
    [[ "$value" =~ ^[a-zA-Z0-9._-]*$ ]] || die "unsafe or malformed $key in os-release"
    case "$key" in
      ID)
        [[ "$seen_id" == false ]] || die 'duplicate ID in os-release'
        seen_id=true
        os_id=$value
        ;;
      VARIANT_ID)
        [[ "$seen_variant" == false ]] || die 'duplicate VARIANT_ID in os-release'
        seen_variant=true
        variant=$value
        ;;
    esac
  done < /etc/os-release

  say "Host prerequisites: ID=${os_id:-unknown}, VARIANT_ID=${variant:-none}"
  [[ ! -e /run/ostree-booted && ! -e /ostree && ! -e /sysroot/ostree ]] \
    || die 'OSTree/Atomic hosts are unsupported; use the host image configuration instead'
  case "$os_id:$variant" in
    fedora: | fedora:workstation | fedora:server)
      packages=(polkit polkit-gnome pam systemd-pam gnome-keyring gnome-keyring-pam udisks2 gvfs bluez upower)
      install_command=(dnf --setopt=install_weak_deps=False --setopt=obsoletes=False install)
      ;;
    debian:)
      packages=(polkitd policykit-1-gnome libpam-systemd dbus-user-session gnome-keyring libpam-gnome-keyring udisks2 gvfs bluez upower)
      install_command=(apt-get --no-remove --no-install-recommends install)
      ;;
    *) die 'unsupported host: only exact mutable Fedora (standard/workstation/server) and Debian IDs are supported; NixOS uses declarative configuration' ;;
  esac

  command -v systemctl > /dev/null 2>&1 || die 'systemctl is missing; systemd >=254 is required'
  version=$(systemctl --version) || die 'cannot determine systemd version'
  [[ "$version" =~ ^systemd\ ([0-9]{1,4})($|[[:space:]]) ]] || die 'cannot parse systemd version'
  version=${BASH_REMATCH[1]}
  ((10#$version >= 254)) || die "systemd $version is unsupported: desktop user units require >=254 (Debian 12's stock systemd is too old); upgrade the host manually"
  manager_version=$(systemctl show --property=Version --value) || die 'cannot contact the systemd system manager'
  [[ "$manager_version" =~ ^([0-9]{1,4})($|[[:space:].+~-]) ]] || die 'cannot parse running systemd manager version'
  ((10#${BASH_REMATCH[1]} >= 254)) || die 'running systemd manager is older than 254; complete the host upgrade/reboot manually'

  printf '%s\n' \
    'This is a prerequisite check, NOT a desktop readiness guarantee.' \
    'Only missing base service/native polkit agent/PAM/keyring/GVfs packages are proposed.' \
    'Standalone Umbriel needs native polkit-gnome-authentication-agent-1 autostart as your normal user.' \
    'The Nix-built Noctalia polkit agent expects NixOS helpers; disable it on these hosts.' \
    'Host setup supplies the native-agent prerequisite only; it does not configure or launch the agent.' \
    'No app Flatpaks, Flatpak CLI, compositor, editor, portal or desktop is installed.' \
    'No service enable/start, session registration, PAM script edits or configuration writes.' \
    'Distro package scripts may configure PAM/services and start services: review the transaction.' \
    'Existing audio, networking, drivers, SELinux and firewall policy are left intact.' \
    'No repository additions, package removals, Docker/Podman changes or group membership changes.' \
    '--repo-dir has no effect on host setup; no checkout is required.'

  if [[ "$os_id" == fedora ]]; then
    if ! command -v rpm > /dev/null 2>&1 || ! command -v dnf > /dev/null 2>&1; then
      die 'Fedora requires native rpm and dnf tools'
    fi
  else
    if ! command -v dpkg-query > /dev/null 2>&1 || ! command -v apt-cache > /dev/null 2>&1 \
      || ! command -v apt-get > /dev/null 2>&1; then
      die 'Debian requires native dpkg-query, apt-cache and apt-get tools'
    fi
  fi
  for package in "${packages[@]}"; do
    if [[ "$os_id" == fedora ]]; then
      if rpm -q -- "$package" > /dev/null 2>&1; then continue; fi
    else
      state=$(dpkg-query -W -f='${Status}' -- "$package" 2> /dev/null) || state=
      if [[ "$state" == 'install ok installed' ]]; then continue; fi
    fi
    missing+=("$package")
  done

  if ((${#missing[@]})); then
    printf 'Proposed command:'
    printf ' %q' sudo "${install_command[@]}" "${missing[@]}"
    printf '\n'
    # Preflight uses existing distro metadata only. Installation may refresh
    # metadata after confirmation; no repositories are added by this script.
    for package in "${missing[@]}"; do
      if [[ "$os_id" == fedora ]]; then
        dnf --cacheonly list --available "$package" > /dev/null 2>&1 \
          || die "no cached native candidate for $package; review/refresh distro metadata manually"
      else
        state=$(apt-cache policy "$package") || die "cannot query candidate for $package"
        [[ "$state" =~ Candidate:[[:space:]]+([^[:space:]]+) && "${BASH_REMATCH[1]}" != '(none)' ]] \
          || die "no native candidate for $package; review/refresh distro metadata manually"
      fi
    done
    if [[ "$apply_host" == true ]]; then
      command -v sudo > /dev/null 2>&1 || die 'sudo is required to apply host prerequisites'
      printf '%s\n' 'Review package-manager dependencies and scripts; reject any unexpected removal or stack migration.'
      if ! read -r -p 'Run the displayed sudo package command? Type yes: ' reply < /dev/tty; then
        die 'interactive terminal required; no host changes made'
      fi
      [[ "$reply" == yes ]] || die 'host setup cancelled; no host changes made'
      sudo "${install_command[@]}" "${missing[@]}"
      for package in "${missing[@]}"; do
        if [[ "$os_id" == fedora ]]; then
          rpm -q -- "$package" > /dev/null 2>&1 || die "package verification failed: $package"
        else
          state=$(dpkg-query -W -f='${Status}' -- "$package") || die "package verification failed: $package"
          [[ "$state" == 'install ok installed' ]] || die "package verification failed: $package"
        fi
      done
    else
      printf '%s\n' 'Preview only. Rerun with --setup-host --apply-host for interactive installation.'
    fi
  else
    printf '%s\n' 'All baseline packages are already installed; no sudo command needed.'
  fi

  say 'Read-only service checks (missing/inactive services require manual review)'
  for package in polkit.service systemd-logind.service udisks2.service bluetooth.service upower.service; do
    state=$(systemctl show --property=LoadState --value "$package") || state=unknown
    printf '%s: %s\n' "$package" "${state:-unknown}"
    systemctl is-active "$package" || warn "$package is not active (possibly D-Bus activated or no hardware); not changed"
  done
  if systemctl --user show-environment > /dev/null 2>&1; then
    for package in pipewire.service pipewire-pulse.service wireplumber.service; do
      state=$(systemctl --user show --property=LoadState --value "$package") || state=unknown
      printf 'user %s: %s\n' "$package" "${state:-unknown}"
      systemctl --user is-active "$package" || warn "user $package is not active; existing audio stack was not migrated"
    done
  else
    warn 'no working systemd user manager; review native login/PAM and log in again before desktop activation'
  fi
  printf '%s\n' \
    'Manual checks still required: native GPU/kernel/udev support, logind/PAM login and keyring unlocking,' \
    'Umbriel-only unprivileged native polkit agent autostart, existing PipeWire/WirePlumber/audio, and system/user D-Bus integration.' \
    'Register the HM Wayland session with your display manager manually, or use its supported TTY launcher.' \
    'HM provides user software/portals/Flatpak CLI; this script does not register a DM or configure Flatpak remotes/apps.' \
    'WinBoat: manually verify modern rootful Docker and docker compose v2; docker-group access is root-equivalent.' \
    'KDE Connect: manually review the existing firewall manager/zones for TCP/UDP 1714-1764 only.' \
    'Do not replace firewall defaults, flush rules or disturb mDNS UDP 5353 or DNS policy.' \
    'Host checks finished; desktop readiness has NOT been certified.'
}
