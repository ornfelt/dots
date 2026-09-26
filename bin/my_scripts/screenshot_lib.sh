# Shared helpers for the screenshot scripts in my_scripts (POSIX sh, so both
# sh and bash scripts can use it). Source it at the top of a script:
#   . ~/.local/bin/my_scripts/screenshot_lib.sh
# Notifications go to dunst (naughty in awesome) through notify-send.
#
#   shot_notify [NOTIFY_SEND_ARGS...] SUMMARY [BODY]  a notification
#   shot_error SUMMARY [BODY]           a critical one (stays until clicked)
#   shot_need CMD[:PKG]...              exit with a notification naming the
#                                       missing commands and their packages
#   shot_need_py MODULE...              same for python3 modules (pip)
#   shot_grab FILE                      select a region into FILE (maim -s, or
#                                       slurp + grim); exits silently when the
#                                       selection is cancelled (Escape or right
#                                       click), with a notification on errors
#   shot_errmsg [FILE]                  the last line of an error log
#                                       (default $SHOT_ERR), markup escaped
#   shot_esc TEXT                       TEXT with its markup escaped
#   shot_path FILE                      FILE with $HOME shown as ~

# stderr of the last step, for the error notifications
SHOT_ERR=$(mktemp)
trap 'rm -f "$SHOT_ERR"' EXIT

shot_notify() {
    command -v notify-send >/dev/null && notify-send -a screenshot "$@"
}

shot_error() {
    shot_notify -u critical "$@"
}

# dunst and naughty read the body as markup
shot_esc() {
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

shot_errmsg() {
    _msg=$(grep -v '^[[:space:]]*$' "${1:-$SHOT_ERR}" | tail -n 1)
    shot_esc "${_msg:-no error message}"
}

shot_path() {
    case $1 in
        "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
        *) printf '%s' "$1" ;;
    esac
}

shot_need() {
    _missing= _pkgs=
    for _dep do
        command -v "${_dep%%:*}" >/dev/null && continue
        _missing="$_missing ${_dep%%:*}" _pkgs="$_pkgs ${_dep#*:}"
    done
    [ -z "$_missing" ] && return
    shot_error "${0##*/}: missing$_missing" "install:$_pkgs"
    exit 1
}

# find_spec looks the modules up without importing them (no delay before the
# selection starts)
shot_need_py() {
    shot_need python3
    _missing=$(python3 -c 'import sys, importlib.util as u
print(" ".join(m for m in sys.argv[1:] if not u.find_spec(m)))' "$@")
    [ -z "$_missing" ] && return
    shot_error "${0##*/}: missing python module $_missing" "pip install $_missing"
    exit 1
}

shot_grab() {
    mkdir -p "$(dirname "$1")"
    if [ -n "$WAYLAND_DISPLAY" ]; then
        shot_need slurp grim
        _region=$(slurp 2>"$SHOT_ERR") && grim -g "$_region" "$1" 2>"$SHOT_ERR"
    else
        shot_need maim
        # -u leaves the mouse cursor out of the capture
        maim -s -u "$1" 2>"$SHOT_ERR"
    fi && return
    # maim -s (slop) and slurp exit non-zero and say so when cancelled
    grep -qi cancel "$SHOT_ERR" || shot_error "${0##*/}: screenshot failed" "$(shot_errmsg)"
    exit 1
}
