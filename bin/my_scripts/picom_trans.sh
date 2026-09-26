#!/bin/sh
# Change window opacity like picom-trans and show the new value:
#   picom_trans.sh STEP          the focused window, STEP like -5 or +5
#   picom_trans.sh --all STEP    every window (_NET_CLIENT_LIST)
#   picom_trans.sh --reset       every window back to picom.conf
# The opacity is _NET_WM_WINDOW_OPACITY on the window's toplevel (as
# picom-trans sets it), which overrides picom.conf's opacity-rule. A window
# without it starts from its opacity-rule (class_g rules), not from 100 like
# picom-trans: a terminal at 91 goes to 86 on -5, not up to 95. Values are
# rounded (picom-trans rounds down: 100 -5 gave 94). Without picom running
# nothing changes: say that instead

conf=${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf
max=4294967295 # 0xffffffff: 100%
min=10 # don't make a window invisible

notify() {
    # the stack tag makes each key press replace the last notification
    notify-send -a picom -t 1500 -h string:x-dunst-stack-tag:opacity "$@"
}

# The ancestor of window $1 that is a child of the root window (the frame in
# a reparenting WM like awesome, the window itself in dwm)
toplevel() {
    _w=$1
    while _info=$(xwininfo -children -id "$_w" 2>/dev/null); do
        case $_info in *"Parent window id: "*"(the root window)"*) break ;; esac
        _w=$(printf '%s\n' "$_info" | sed -n 's/^ *Parent window id: \(0x[[:xdigit:]]*\).*/\1/p')
        [ -n "$_w" ] || return 1
    done
    echo "$_w"
}

# The opacity-rule percentage in picom.conf for window $1's class, if any
rule_opacity() {
    _class=$(xprop -id "$1" WM_CLASS 2>/dev/null | sed -n 's/.*", "\(.*\)"$/\1/p')
    [ -n "$_class" ] || return
    awk -F"'" -v c="$_class" '
        /^[[:space:]]*opacity-rule/ { inrule = 1 }
        inrule && /^[[:space:]]*"[0-9]+:[[:space:]]*class_g[[:space:]]*=[[:space:]]*'"'"'/ && $2 == c {
            match($1, /[0-9]+/); print substr($1, RSTART, RLENGTH); exit
        }
        inrule && /\]/ { exit }' "$conf"
}

# The opacity (0-100) of window $1: its property, else its rule, else 100
get_opacity() {
    _cur=$(xprop -id "$(toplevel "$1")" -notype -f _NET_WM_WINDOW_OPACITY 32c '$0' _NET_WM_WINDOW_OPACITY)
    _cur=${_cur#_NET_WM_WINDOW_OPACITY}
    case $_cur in
        *[!0-9]* | "") _rule=$(rule_opacity "$1"); echo "${_rule:-100}" ;;
        *) echo $(( (_cur * 100 + max / 2) / max )) ;;
    esac
}

# Change window $1's opacity by $2 and print the new value
step_opacity() {
    _new=$(( $(get_opacity "$1") + $2 ))
    [ $_new -gt 100 ] && _new=100
    [ $_new -lt $min ] && _new=$min
    xprop -id "$(toplevel "$1")" -f _NET_WM_WINDOW_OPACITY 32c \
        -set _NET_WM_WINDOW_OPACITY $(( (_new * max + 50) / 100 )) || return
    echo $_new
}

clients() {
    xprop -root _NET_CLIENT_LIST | sed 's/^[^#]*#//; s/,/ /g'
}

focused() {
    _id=$(xprop -root _NET_ACTIVE_WINDOW | sed -n 's/.*# \(0x[[:xdigit:]]*\).*/\1/p')
    [ "$_id" != 0x0 ] && echo "$_id"
}

if ! pgrep -x picom >/dev/null; then
    notify -u critical "Opacity" "picom isn't running"
    exit 1
fi

case $1 in
    --reset)
        for w in $(clients); do
            xprop -id "$(toplevel "$w")" -remove _NET_WM_WINDOW_OPACITY 2>/dev/null
        done
        notify "Opacity reset" "all windows back to picom.conf"
        ;;
    --all)
        for w in $(clients); do
            step_opacity "$w" "$2" >/dev/null
        done
        f=$(focused)
        if [ -n "$f" ]; then
            o=$(get_opacity "$f")
            notify -h int:value:"$o" "All windows $2%" "focused window: $o%"
        else
            notify "All windows $2%"
        fi
        ;;
    *)
        f=$(focused)
        if [ -z "$f" ]; then
            notify "Opacity" "no focused window"
            exit 1
        fi
        if ! o=$(step_opacity "$f" "$1" 2>&1); then
            notify -u critical "Opacity: can't set it" "$(printf '%s' "$o" | tail -n 1)"
            exit 1
        fi
        notify -h int:value:"$o" "Opacity $o%"
        ;;
esac
