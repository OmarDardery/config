# Native editor plugins and notebook dependencies; never called by HM activation.
set -euo pipefail
for command in nvim codium python3 git; do
  command -v "$command" >/dev/null || { printf 'Install native %s first.\n' "$command" >&2; exit 1; }
done
if ! nvim --headless -u NONE -c "if !has('nvim-0.11.2') | cquit 1 | endif" -c qa; then
  printf '%s\n' 'LazyVim requires native Neovim 0.11.2 or newer.' >&2
  exit 1
fi
editor_python="${XDG_DATA_HOME:-$HOME/.local/share}/editor-python"
python3 -m venv "$editor_python"
"$editor_python/bin/python" -m pip install --upgrade \
  pynvim jupyter-client ipykernel jupytext nbformat cairosvg pnglatex plotly pillow requests websocket-client debugpy
"$editor_python/bin/python" -m ipykernel install --user --name editor-python --display-name 'Python (editor tools)'
failed=()
while IFS= read -r extension; do
  [[ -n "$extension" ]] || continue
  if ! codium --install-extension "$extension"; then failed+=("$extension"); fi
done < "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/extensions.list"
nvim --headless '+Lazy! sync' '+UpdateRemotePlugins' +qa
if ((${#failed[@]})); then
  printf 'Some extensions were unavailable from the native editor gallery:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  printf '%s\n' 'Install their publisher-provided VSIX files manually; the other editor setup steps completed.' >&2
  exit 1
fi
