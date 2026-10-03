#!/usr/bin/env bash
# Isolated build-time tests, never invoked against the running desktop.
set -euo pipefail
plugin=$1
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export SCREEN_TOOLKIT_TMPDIR="$work/private"
mkdir -m 700 "$SCREEN_TOOLKIT_TMPDIR"

# Scripts must fail closed instead of falling back to shared /tmp filenames.
for script in capture capture-niri ocr record lens-upload; do
    if env -u SCREEN_TOOLKIT_TMPDIR bash "$plugin/scripts/$script.sh" 0 0 10 10 > /dev/null 2>&1; then
        printf 'Missing private directory accepted: %s\n' "$script" >&2
        exit 1
    fi
done
if env -u SCREEN_TOOLKIT_TMPDIR bash "$plugin/scripts/capture.sh" annotate-window-umbriel "$work/preview.png" > /dev/null 2>&1; then exit 1; fi

# Use the real jq filter, but never contact a compositor or capture the desktop.
umbriel() {
    test "$*" = 'windows --json' || return 1
    printf '%s\n' "$MOCK_WINDOWS"
    return "${MOCK_IPC_STATUS:-0}"
}
grim() {
    printf '%s\n' "$@" > "$work/grim-args"
    test "$(stat -c %a "$(dirname "${@: -1}")")" = 700 || return 1
    if [ "${MOCK_CAPTURE:-ok}" != empty ]; then printf capture > "${@: -1}"; fi
    [ "${MOCK_CAPTURE:-ok}" != fail ]
}
export -f umbriel grim
export work MOCK_WINDOWS='[{"active":false,"id":"other"},{"active":true,"id":"client with spaces"}]'
shopt -s nullglob
target="$SCREEN_TOOLKIT_TMPDIR/passed preview.png"
for cursor in 0 1; do
    export SCREEN_TOOLKIT_CAPTURE_CURSOR=$cursor
    test "$(bash "$plugin/scripts/capture.sh" annotate-window-umbriel "$target")" = '0,0 0x0'
    test "$(< "$target")" = capture
    test "$(stat -c %a "$target")" = 600
    mapfile -t args < "$work/grim-args"
    if [ "$cursor" = 1 ]; then test "${args[0]}" = -c; args=("${args[@]:1}"); fi
    test "${#args[@]}" = 3
    test "${args[0]}" = -T
    test "${args[1]}" = 'client with spaces'
    test "${args[2]}" != "$target"
    staging=("$SCREEN_TOOLKIT_TMPDIR"/umbriel.*)
    test "${#staging[@]}" = 0
done

# Errors must retain the last preview and remove even partially written captures.
for failure in ipc malformed no-active multiple missing-id empty-id numeric-id capture empty publish; do
    export MOCK_WINDOWS='[{"active":true,"id":"client"}]' MOCK_IPC_STATUS=0 MOCK_CAPTURE=ok
    destination=$target
    case "$failure" in
        ipc) MOCK_IPC_STATUS=1 ;;
        malformed) MOCK_WINDOWS='not json' ;;
        no-active) MOCK_WINDOWS='[{"active":false,"id":"client"}]' ;;
        multiple) MOCK_WINDOWS='[{"active":true,"id":"a"},{"active":true,"id":"b"}]' ;;
        missing-id) MOCK_WINDOWS='[{"active":true}]' ;;
        empty-id) MOCK_WINDOWS='[{"active":true,"id":""}]' ;;
        numeric-id) MOCK_WINDOWS='[{"active":true,"id":42}]' ;;
        capture) MOCK_CAPTURE=fail ;;
        empty) MOCK_CAPTURE=empty ;;
        publish) destination="$work/missing/preview.png" ;;
    esac
    printf previous > "$target"
    if bash "$plugin/scripts/capture.sh" annotate-window-umbriel "$destination" > /dev/null 2>&1; then
        printf 'Umbriel error accepted: %s\n' "$failure" >&2
        exit 1
    fi
    test "$(< "$target")" = previous
    staging=("$SCREEN_TOOLKIT_TMPDIR"/umbriel.*)
    test "${#staging[@]}" = 0
done

# Niri capture keeps the final preview but cleans its asynchronous staging area.
niri() { printf 'capture' > "${@: -1}"; }
export -f niri
export NIRI_SOCKET="$work/mock-niri.sock"
bash "$plugin/scripts/capture-niri.sh" annotate-window > /dev/null
test "$(< "$SCREEN_TOOLKIT_TMPDIR/screen-toolkit-annotate.png")" = capture
staging=("$SCREEN_TOOLKIT_TMPDIR"/niri.*)
test "${#staging[@]}" = 0

# Failure paths must also clean processing/upload scratch directories.
grim() { return 1; }
magick() { return 1; }
tesseract() { return 1; }
curl() { return 1; }
jq() { return 1; }
xdg-open() { return 1; }
ffmpeg() { return 1; }
export -f grim magick tesseract curl jq xdg-open ffmpeg
if bash "$plugin/scripts/ocr.sh" 0 0 10 10 eng '' 3 > /dev/null 2>&1; then exit 1; fi
if bash "$plugin/scripts/lens-upload.sh" 0 0 10 10 > /dev/null 2>&1; then exit 1; fi
printf 'mock video' > "$SCREEN_TOOLKIT_TMPDIR/input.mp4"
if bash "$plugin/scripts/record.sh" convert-gif "$SCREEN_TOOLKIT_TMPDIR/input.mp4" "$work/output.gif" > /dev/null 2>&1; then exit 1; fi
staging=("$SCREEN_TOOLKIT_TMPDIR"/ocr.* "$SCREEN_TOOLKIT_TMPDIR"/lens.* "$SCREEN_TOOLKIT_TMPDIR"/record.*)
test "${#staging[@]}" = 0
