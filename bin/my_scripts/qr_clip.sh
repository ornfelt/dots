#!/bin/bash
#
# Show a QR code of the clipboard contents (or of the arguments, if given).
# Needs qrencode, xclip and feh.

# Print to stderr and, since this usually runs from a keybind with no
# terminal, also show it as a notification
err() {
    echo "qr_clip: $1" >&2
    command -v notify-send >/dev/null && notify-send "qr_clip" "$1"
    exit 1
}

missing=()
for cmd in qrencode xclip feh; do
    command -v "$cmd" >/dev/null || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
    err "missing: ${missing[*]}. Install with: sudo apt install ${missing[*]}"
fi

if [ -n "$1" ]; then
    target="$*"
else
    target="$(xclip -selection clipboard -o)" || err "could not read the clipboard."
    [ -n "$target" ] || err "clipboard empty."
fi

# Temp file instead of temp_code.png in whatever directory this runs from
img=$(mktemp --suffix=.png) || err "could not create a temp file."
trap 'rm -f "$img"' EXIT

qrencode "$target" -o "$img" || err "qrencode failed (text too long?)."
feh --scale-down --auto-zoom "$img"
