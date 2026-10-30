# Sync editor plugins and the small extension list; no language environments.
set -euo pipefail
for command in nvim codium git; do
  command -v "$command" >/dev/null || { printf 'Install native %s first.\n' "$command" >&2; exit 1; }
done
if ! nvim --headless -u NONE -c "if !has('nvim-0.11.2') | cquit 1 | endif" -c qa; then
  printf '%s\n' 'LazyVim requires native Neovim 0.11.2 or newer.' >&2
  exit 1
fi
failed=()
while IFS= read -r extension; do
  [[ -n "$extension" ]] || continue
  if ! codium --install-extension "$extension"; then failed+=("$extension"); fi
done < "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/extensions.list"
nvim --headless '+Lazy! sync' +qa
if ((${#failed[@]})); then
  printf 'Some extensions were unavailable from the native editor gallery:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  printf '%s\n' 'Install their publisher-provided VSIX files manually; the other editor setup steps completed.' >&2
  exit 1
fi
