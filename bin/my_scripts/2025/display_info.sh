#!/usr/bin/env bash
# display_info.sh - what the display actually is, and what a non-HiDPI-aware app
# (the x11 and sdl gfx backends) is handed instead. Run on each machine and compare.
# Linux counterpart of windows_dots/my_scripts/display_info.ps1; works on X11 and
# on Wayland (sway, hyprland, wlroots, KDE, GNOME), auto-detecting the session.
#
# Usage examples:
# primary display, backend auto-detected:
#   display_info.sh
# every connected output:
#   display_info.sh --all
# one output by name, case insensitive, positional or named:
#   display_info.sh edp
#   display_info.sh --output DP-1
# force a backend instead of auto-detecting the session:
#   display_info.sh --backend x11
#   display_info.sh --backend sway
# machine readable:
#   display_info.sh --all --json
# print the commands this run would use, instead of running them:
#   display_info.sh --all --debug

set -uo pipefail

SCRIPT_NAME="${0##*/}"
SCRIPT_INVOCATION="$SCRIPT_NAME${*:+ $*}"

# ------------------------------------------------------------------ colors --
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_OK=$'\033[1;32m'
    C_ERR=$'\033[1;31m'
    C_WARN=$'\033[1;33m'
    C_INFO=$'\033[1;36m'
    C_HEAD=$'\033[1;35m'
    C_DBG=$'\033[1;35m'
    C_DIM=$'\033[90m'
else
    C_RESET='' C_OK='' C_ERR='' C_WARN='' C_INFO='' C_HEAD='' C_DBG='' C_DIM=''
fi

ok()   { printf '%s[ ok ]%s %s\n'  "$C_OK"   "$C_RESET" "$*"; }
err()  { printf '%s[fail]%s %s\n'  "$C_ERR"  "$C_RESET" "$*" >&2; }
warn() { printf '%s[warn]%s %s\n'  "$C_WARN" "$C_RESET" "$*" >&2; }
info() { printf '%s[info]%s %s\n'  "$C_INFO" "$C_RESET" "$*"; }
dbg()  { printf '%s[ dry]%s %s\n'  "$C_DBG"  "$C_RESET" "$*"; }

die() { err "$*"; exit 1; }

# --------------------------------------------------------------- constants --
readonly BASE_DPI=96            # 100% scaling, same reference Windows uses
readonly MM_PER_INCH=25.4
readonly DEFAULT_CURSOR_SIZE=24 # what Xcursor falls back to when nothing is set
readonly LABEL_WIDTH=27
readonly UNSET_TEXT="(unset)"
readonly UNKNOWN_TEXT="?"
readonly GSETTINGS_IFACE="org.gnome.desktop.interface"

# ---------------------------------------------------------------- defaults --
OUTPUT_FILTER=""        # output name to report (also accepted positionally)
SHOW_ALL=0              # 1 = report every connected output, not just the primary
BACKEND="auto"          # auto|x11|wayland|xrandr|wlr|sway|hypr|kde|gnome
CASE_SENSITIVE=0        # output-name matching; default is case insensitive
AS_JSON=0               # 1 = print JSON instead of the colored listing
DEBUG=0                 # 1 = print the commands instead of running them

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OUTPUT] [options]

Reports, per display: real pixels, refresh rate, physical size and DPI, the
compositor scale, the cursor size, and the desktop size a non-HiDPI-aware
client is handed (the ceiling on render_width).

Options:
  -o, --output <name>   report this output only, e.g. eDP-1, DP-1, HDMI-A-0
                        (also accepted as the first positional argument)
  -a, --all             report every connected output  (default: primary only)
  -b, --backend <b>     auto|x11|wayland|xrandr|wlr|sway|hypr|kde|gnome
                                                        (default: $BACKEND)
  -c, --case-sensitive  match OUTPUT case-sensitively (default: insensitive)
  -j, --json            print JSON instead of the colored listing
  -d, --debug           print the commands this run would use, without running
  -h, --help            show this help

Examples:
  $SCRIPT_NAME                      # the primary display
  $SCRIPT_NAME --all                # every connected display
  $SCRIPT_NAME edp                  # just the internal panel
  $SCRIPT_NAME --backend x11        # ask XWayland instead of the compositor
  $SCRIPT_NAME --all --json         # machine readable
  $SCRIPT_NAME --all --debug        # show the commands behind the numbers
EOF
}

need_arg() { [[ -n "${2:-}" ]] || die "option '$1' requires a value"; }

# ------------------------------------------------------------ arg parsing ---
POSITIONAL_SEEN=0
while (( $# )); do
    case "$1" in
        -o|--output)         need_arg "$1" "${2:-}"; OUTPUT_FILTER="$2"; shift 2 ;;
        --output=*)          OUTPUT_FILTER="${1#*=}";                     shift ;;
        -b|--backend)        need_arg "$1" "${2:-}"; BACKEND="$2";      shift 2 ;;
        --backend=*)         BACKEND="${1#*=}";                          shift ;;
        -a|--all)            SHOW_ALL=1;                                 shift ;;
        -c|--case-sensitive) CASE_SENSITIVE=1;                           shift ;;
        -j|--json)           AS_JSON=1;                                  shift ;;
        -d|--debug)          DEBUG=1;                                    shift ;;
        -h|--help)           usage; exit 0 ;;
        -*)                  die "unknown option: $1 (try --help)" ;;
        *)
            (( POSITIONAL_SEEN )) && die "unexpected extra argument: $1"
            OUTPUT_FILTER="$1"; POSITIONAL_SEEN=1;                        shift ;;
    esac
done

BACKEND="$(printf '%s' "$BACKEND" | tr '[:upper:]' '[:lower:]')"
case "$BACKEND" in
    auto|x11|xrandr|wayland|wlr|sway|hypr|hyprland|kde|kwin|gnome|mutter) ;;
    *) die "unknown backend: $BACKEND (try --help)" ;;
esac
[[ "$BACKEND" == "hyprland" ]] && BACKEND="hypr"
[[ "$BACKEND" == "kwin"     ]] && BACKEND="kde"
[[ "$BACKEND" == "mutter"   ]] && BACKEND="gnome"
[[ "$BACKEND" == "xrandr"   ]] && BACKEND="x11"

have() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------ session detection ---
# Answers x11 / wayland / unknown, preferring what is actually reachable over
# what the environment claims - XDG_SESSION_TYPE is often "tty" under tmux,
# ssh or a service unit even though a session is running.
detect_session() {
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then echo "wayland"; return; fi
    if [[ -n "${DISPLAY:-}" ]];         then echo "x11";     return; fi
    case "${XDG_SESSION_TYPE:-}" in
        wayland) echo "wayland"; return ;;
        x11)     echo "x11";     return ;;
    esac
    if have loginctl; then
        local type
        type="$(loginctl show-session "${XDG_SESSION_ID:-$(loginctl show-user "$USER" -p Display --value 2>/dev/null)}" \
                    -p Type --value 2>/dev/null)"
        case "$type" in wayland|x11) echo "$type"; return ;; esac
    fi
    echo "unknown"
}

# Picks the concrete tool for a wayland session, falling back to XWayland.
detect_wayland_backend() {
    if [[ -n "${SWAYSOCK:-}" ]] && have swaymsg;                    then echo "sway";  return; fi
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && have hyprctl; then echo "hypr";  return; fi
    case "${XDG_CURRENT_DESKTOP:-}" in
        *KDE*|*plasma*|*Plasma*) have kscreen-doctor && { echo "kde";   return; } ;;
        *GNOME*)                 have gdbus         && { echo "gnome"; return; } ;;
    esac
    if have wlr-randr;      then echo "wlr";   return; fi
    if have swaymsg;        then echo "sway";  return; fi
    if have hyprctl;        then echo "hypr";  return; fi
    if have kscreen-doctor; then echo "kde";   return; fi
    if have gdbus;          then echo "gnome"; return; fi
    echo "x11"
}

SESSION="$(detect_session)"
if [[ "$BACKEND" == "auto" ]]; then
    case "$SESSION" in
        wayland) BACKEND="$(detect_wayland_backend)" ;;
        x11)     BACKEND="x11" ;;
        *)       have xrandr && BACKEND="x11" || die "no display session detected (set DISPLAY/WAYLAND_DISPLAY, or use --backend)" ;;
    esac
elif [[ "$BACKEND" == "wayland" ]]; then
    BACKEND="$(detect_wayland_backend)"
fi

backend_label() {
    case "$BACKEND" in
        x11)   echo "X11 (xrandr)" ;;
        wlr)   echo "Wayland (wlr-randr)" ;;
        sway)  echo "Wayland (swaymsg)" ;;
        hypr)  echo "Wayland (hyprctl)" ;;
        kde)   echo "Wayland (kscreen-doctor)" ;;
        gnome) echo "Wayland (Mutter DisplayConfig)" ;;
    esac
}

# --------------------------------------------------------------- collectors --
# Every collector prints one record per enabled output, pipe separated:
#   name|primary|width|height|x|y|refresh|scale|mm_w|mm_h|description
# Unknown fields stay empty. width/height are real (physical) pixels.

collect_x11() {
    xrandr --query 2>/dev/null | awk '
        function flush() {
            # no geometry means the output is connected but not part of the desktop
            if (nm != "" && w != "")
                printf "%s|%d|%s|%s|%s|%s|%s||%s|%s|%s\n", nm, prim, w, h, px, py, rate, mmw, mmh, desc
            nm=""; prim=0; w=""; h=""; px=""; py=""; rate=""; mmw=""; mmh=""; desc=""
        }
        $2 == "connected" {
            flush(); nm=$1
            for (i = 3; i <= NF; i++) {
                if ($i == "primary") prim=1
                else if ($i ~ /^[0-9]+x[0-9]+\+[-0-9]+\+[-0-9]+$/) {
                    split($i, g, /[x+]/); w=g[1]; h=g[2]; px=g[3]; py=g[4]
                }
                else if ($i ~ /^[0-9]+mm$/ && $(i+1) == "x") {
                    mmw=$i; mmh=$(i+2); sub(/mm/, "", mmw); sub(/mm/, "", mmh)
                }
            }
            next
        }
        $2 == "disconnected" { flush(); next }
        # the mode marked with "*" is the one currently driving the output
        nm != "" && /^[ \t]+[0-9]+x[0-9]+/ && index($0, "*") > 0 {
            for (i = 2; i <= NF; i++)
                if (index($i, "*") > 0) { rate=$i; gsub(/[*+]/, "", rate); break }
            if (w == "") { split($1, m, "x"); w=m[1]; h=m[2] }
            next
        }
        END { flush() }
    '
}

collect_wlr() {
    wlr-randr 2>/dev/null | awk '
        function flush() {
            if (nm != "" && enabled != "no")
                printf "%s|0|%s|%s|%s|%s|%s|%s|%s|%s|%s\n", nm, w, h, px, py, rate, scale, mmw, mmh, desc
            nm=""; w=""; h=""; px=""; py=""; rate=""; scale=""; mmw=""; mmh=""; desc=""; enabled=""
        }
        /^[^ \t]/ {
            flush(); nm=$1
            if (match($0, /"[^"]*"/)) desc=substr($0, RSTART+1, RLENGTH-2)
            next
        }
        /Physical size:/ { split($3, s, "x"); mmw=s[1]; mmh=s[2]; next }
        /Enabled:/       { enabled=$2; next }
        /Position:/      { split($2, p, ","); px=p[1]; py=p[2]; next }
        /Scale:/         { scale=$2; next }
        /px,/ && /current/ { split($1, m, "x"); w=m[1]; h=m[2]; rate=$3; next }
        END { flush() }
    '
}

collect_sway() {
    swaymsg -t get_outputs 2>/dev/null | awk '
        function flush() {
            if (nm != "" && inactive == 0)
                printf "%s|%d|%s|%s|%s|%s|%s|%s|||%s\n", nm, prim, w, h, px, py, rate, scale, desc
            nm=""; prim=0; w=""; h=""; px=""; py=""; rate=""; scale=""; desc=""; inactive=0
        }
        /^Output /{
            flush(); nm=$2
            prim = ($0 ~ /\(focused\)/) ? 1 : 0
            inactive = ($0 ~ /\(inactive\)/) ? 1 : 0
            if (match($0, /'"'"'[^'"'"']*'"'"'/)) desc=substr($0, RSTART+1, RLENGTH-2)
            next
        }
        /Current mode:/  { split($3, m, "x"); w=m[1]; h=m[2]; rate=$5; next }
        /Position:/      { split($2, p, ","); px=p[1]; py=p[2]; next }
        /Scale factor:/  { scale=$3; next }
        END { flush() }
    '
}

collect_hypr() {
    hyprctl monitors 2>/dev/null | awk '
        function flush() {
            if (nm != "")
                printf "%s|%d|%s|%s|%s|%s|%s|%s|||%s\n", nm, prim, w, h, px, py, rate, scale, desc
            nm=""; prim=0; w=""; h=""; px=""; py=""; rate=""; scale=""; desc=""
        }
        /^Monitor /{ flush(); nm=$2; next }
        /^[ \t]+[0-9]+x[0-9]+@/ {
            split($1, a, "@"); split(a[1], m, "x"); w=m[1]; h=m[2]; rate=a[2]
            if ($2 == "at") { split($3, p, "x"); px=p[1]; py=p[2] }
            next
        }
        /^[ \t]*description:/ { sub(/^[ \t]*description:[ \t]*/, ""); desc=$0; next }
        /^[ \t]*scale:/       { scale=$2; next }
        /^[ \t]*focused:/     { prim = ($2 == "yes") ? 1 : 0; next }
        END { flush() }
    '
}

collect_kde() {
    have jq || { warn "kscreen-doctor output needs jq to parse; install jq or use --backend x11"; return 1; }
    kscreen-doctor -j 2>/dev/null | jq -r '
        .outputs[] | select(.enabled == true) |
        . as $o | (.currentModeId) as $id |
        ([.modes[] | select(.id == $id)] | first // {}) as $m |
        [ $o.name,
          (if ($o.primary // false) then 1 else 0 end),
          ($m.size.width  // ""), ($m.size.height // ""),
          ($o.pos.x // ""), ($o.pos.y // ""),
          ($m.refreshRate // ""), ($o.scale // ""),
          ($o.sizeMM.width // ""), ($o.sizeMM.height // ""),
          ($o.type // "")
        ] | map(tostring) | join("|")
    ' 2>/dev/null
}

# GNOME exposes no display CLI, so this reads Mutter's DisplayConfig over D-Bus
# and picks the current mode plus the logical-monitor scale out of the variant.
collect_gnome() {
    have python3 || { warn "the GNOME/Mutter backend needs python3; falling back is up to --backend"; return 1; }
    gdbus call --session \
        --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null |
    python3 -c '
import re, sys

blob = sys.stdin.read()

# Where each monitor tuple starts: (("connector", "vendor", "product", "serial"), [modes], {props})
starts = [(m.start(), m.group(1)) for m in
          re.finditer(r"\(\(\x27([^\x27]+)\x27, \x27[^\x27]*\x27, \x27[^\x27]*\x27, \x27[^\x27]*\x27\), \[", blob)]

def owner(pos):
    name = ""
    for start, conn in starts:
        if start < pos:
            name = conn
        else:
            break
    return name

modes, sizes, vendors = {}, {}, {}
# a mode is ("1920x1080@60.0", width, height, refresh, preferred-scale, [scales], {props})
for m in re.finditer(r"\(\x27[^\x27]*@[\d.]+\x27, (\d+), (\d+), ([\d.]+), [\d.]+, \[[^\]]*\], \{[^{}]*\x27is-current\x27: <true>[^{}]*\}\)", blob):
    modes.setdefault(owner(m.start()), (m.group(1), m.group(2), m.group(3)))
for m in re.finditer(r"\x27width-mm\x27: <(\d+)>", blob):
    sizes.setdefault(owner(m.start()), [m.group(1), ""])
for m in re.finditer(r"\x27height-mm\x27: <(\d+)>", blob):
    sizes.setdefault(owner(m.start()), ["", ""])[1] = m.group(1)
for m in re.finditer(r"\x27display-name\x27: <\x27([^\x27]*)\x27>", blob):
    vendors.setdefault(owner(m.start()), m.group(1))

# a logical monitor is (x, y, scale, transform, primary, [(connector, ...)], {props})
for m in re.finditer(r"\((-?\d+), (-?\d+), ([\d.]+), \d+, (true|false), \[\(\x27([^\x27]+)\x27", blob):
    x, y, scale, primary, conn = m.group(1), m.group(2), m.group(3), m.group(4), m.group(5)
    w, h, refresh = modes.get(conn, ("", "", ""))
    mm_w, mm_h = sizes.get(conn, ["", ""])
    print("|".join([conn, "1" if primary == "true" else "0", w, h, x, y, refresh,
                    scale, mm_w, mm_h, vendors.get(conn, "")]))
'
}

collect_records() {
    case "$BACKEND" in
        x11)   have xrandr         || die "xrandr not found"         ; collect_x11   ;;
        wlr)   have wlr-randr      || die "wlr-randr not found"      ; collect_wlr   ;;
        sway)  have swaymsg        || die "swaymsg not found"        ; collect_sway  ;;
        hypr)  have hyprctl        || die "hyprctl not found"        ; collect_hypr  ;;
        kde)   have kscreen-doctor || die "kscreen-doctor not found" ; collect_kde   ;;
        gnome) have gdbus          || die "gdbus not found"          ; collect_gnome ;;
    esac
}

# ---------------------------------------------------------- global settings --
gsetting() { have gsettings && gsettings get "$GSETTINGS_IFACE" "$1" 2>/dev/null | tr -d "'" | sed 's/^uint32 //'; }

xresource() {
    have xrdb || return
    xrdb -query 2>/dev/null | awk -F':[ \t]*' -v key="$1" 'tolower($1) == tolower(key) { print $2; exit }'
}

# The DPI the toolkits are told about, which is what actually drives scaling on X11.
logical_dpi() {
    local dpi
    dpi="$(xresource 'Xft.dpi')"
    [[ -n "$dpi" ]] && { echo "${dpi%%.*}"; return; }
    if have xdpyinfo && [[ -n "${DISPLAY:-}" ]]; then
        dpi="$(xdpyinfo 2>/dev/null | awk '/resolution:/ { split($2, r, "x"); print r[1]; exit }')"
        [[ -n "$dpi" ]] && { echo "$dpi"; return; }
    fi
    echo "$BASE_DPI"
}

cursor_size() {
    local size="${XCURSOR_SIZE:-}"
    [[ -z "$size" ]] && size="$(xresource 'Xcursor.size')"
    [[ -z "$size" ]] && size="$(gsetting cursor-size)"
    [[ -z "$size" ]] && size="$DEFAULT_CURSOR_SIZE"
    echo "${size%%.*}"
}

# --------------------------------------------------------------- math bits --
# awk does the float work; every helper returns an empty string when it cannot.
calc() { awk "BEGIN { $1 }" 2>/dev/null; }

round_div() { # numerator denominator -> rounded integer
    [[ -z "${1:-}" || -z "${2:-}" ]] && return
    calc "if ($2 + 0 == 0) exit; printf \"%d\", int($1 / $2 + 0.5)"
}

fmt_num() { # value decimals -> trimmed fixed-point
    [[ -z "${1:-}" ]] && return
    calc "printf \"%.${2}f\", $1"
}

json_escape() { printf '%s' "${1:-}" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# ------------------------------------------------------------- debug output --
show_commands() {
    local grep_filter=""
    if [[ -n "$OUTPUT_FILTER" ]]; then
        if (( CASE_SENSITIVE )); then grep_filter=" | grep -- '$OUTPUT_FILTER'"
        else                          grep_filter=" | grep -i -- '$OUTPUT_FILTER'"; fi
    fi

    printf '%s# %s%s\n' "$C_DIM" "$SCRIPT_INVOCATION" "$C_RESET"
    printf '%s# session: %s, backend: %s%s\n' "$C_DIM" "$SESSION" "$(backend_label)" "$C_RESET"
    echo
    case "$BACKEND" in
        x11)
            echo "# connected outputs: real pixels, position and physical size"
            echo "xrandr --query | awk '\$2 == \"connected\"'$grep_filter"
            echo "# the mode marked with '*' is the active one (resolution and refresh rate)"
            echo "xrandr --query | grep -- '*'"
            ;;
        wlr)
            echo "# per output: modes (the 'current' one), position, scale and physical size"
            echo "wlr-randr$grep_filter"
            ;;
        sway)
            echo "# per output: current mode, position and scale factor"
            echo "swaymsg -t get_outputs$grep_filter"
            ;;
        hypr)
            echo "# per monitor: mode@refresh, position, scale and focus"
            echo "hyprctl monitors$grep_filter"
            ;;
        kde)
            echo "# per output: current mode, position, scale and physical size"
            echo "kscreen-doctor -j | jq '.outputs[] | select(.enabled)'$grep_filter"
            ;;
        gnome)
            echo "# Mutter's view: monitors with their current mode, then the logical monitors with their scale"
            echo "gdbus call --session --dest org.gnome.Mutter.DisplayConfig \\"
            echo "      --object-path /org/gnome/Mutter/DisplayConfig \\"
            echo "      --method org.gnome.Mutter.DisplayConfig.GetCurrentState$grep_filter"
            ;;
    esac
    echo
    echo "# the DPI handed to the toolkits, and the resulting scaling percentage"
    echo "xrdb -query | grep -i '^Xft.dpi'"
    echo "xdpyinfo | grep -E 'dimensions|resolution'"
    echo "# the cursor size a client gets for a custom cursor of its own"
    echo "echo \"\${XCURSOR_SIZE:-\$(gsettings get $GSETTINGS_IFACE cursor-size)}\""
    echo "# toolkit overrides that change what a client is handed"
    echo "env | grep -E '^(GDK_SCALE|GDK_DPI_SCALE|QT_SCALE_FACTOR|QT_AUTO_SCREEN_SCALE_FACTOR|XCURSOR_SIZE)='"
    if [[ "$BACKEND" != "x11" ]]; then
        echo
        echo "# a non-HiDPI-aware client sees the mode divided by the scale above:"
        echo "#   logical_width = width / scale, logical_height = height / scale"
    fi
}

# ------------------------------------------------------------- presentation --
kv() { printf '%s%-*s%s : %s%s%s\n' "$C_INFO" "$LABEL_WIDTH" "$1" "$C_RESET" "$C_OK" "$2" "$C_RESET"; }

env_or_unset() { local v="${!1:-}"; [[ -n "$v" ]] && echo "$v" || echo "$UNSET_TEXT"; }

print_record() {
    local name primary w h x y refresh scale mm_w mm_h desc
    IFS='|' read -r name primary w h x y refresh scale mm_w mm_h desc <<< "$1"

    local dpi scaling
    if [[ "$BACKEND" == "x11" ]]; then
        # X11 has no per-output scale: everything is driven by the logical DPI.
        dpi="$LOGICAL_DPI"
        scale="$(calc "printf \"%.4f\", $dpi / $BASE_DPI")"
    else
        [[ -z "$scale" ]] && scale="1"
        dpi="$(calc "printf \"%d\", int($BASE_DPI * $scale + 0.5)")"
    fi
    scaling="$(fmt_num "$(calc "printf \"%.4f\", $scale * 100")" 0)"

    # what a client that does not know about scaling is handed
    local legacy_w legacy_h legacy_note
    if [[ "$BACKEND" == "x11" ]]; then
        legacy_w="$w"; legacy_h="$h"
        legacy_note="X11 hands out real pixels, nothing is virtualized"
    else
        legacy_w="$(round_div "$w" "$scale")"
        legacy_h="$(round_div "$h" "$scale")"
        legacy_note="the compositor upscales this to ${w}x${h}"
    fi

    local phys_dpi="" diag=""
    if [[ -n "$mm_w" && "$mm_w" != "0" ]]; then
        phys_dpi="$(calc "printf \"%d\", int($w * $MM_PER_INCH / $mm_w + 0.5)")"
        diag="$(calc "printf \"%.1f\", sqrt($mm_w * $mm_w + $mm_h * $mm_h) / $MM_PER_INCH")"
    fi

    echo
    printf '%s-- %s --%s\n' "$C_HEAD" "$name" "$C_RESET"
    kv "Output"     "$name$( [[ "$primary" == "1" ]] && echo ' (primary)' )$( [[ -n "$desc" ]] && echo "  $C_DIM$desc$C_RESET" )"
    kv "Screen"     "${w:-$UNKNOWN_TEXT}x${h:-$UNKNOWN_TEXT}$( [[ -n "$refresh" ]] && echo " @ $(fmt_num "$refresh" 2) Hz" )"
    [[ -n "$x" ]] && kv "Position" "+$x+$y"
    if [[ -n "$mm_w" && "$mm_w" != "0" ]]; then
        kv "PhysicalSize" "${mm_w}mm x ${mm_h}mm (${diag}\")"
        kv "PhysicalDPI"  "$phys_dpi  ${C_DIM}true pixel density${C_RESET}"
    fi
    kv "DPI"       "$dpi"
    kv "Scaling"   "${scaling}%"
    kv "SysCursor" "${CURSOR_SIZE}x${CURSOR_SIZE}"
    kv "VirtualizedForLegacyApp" "${legacy_w:-$UNKNOWN_TEXT}x${legacy_h:-$UNKNOWN_TEXT}  ${C_DIM}${legacy_note}${C_RESET}"
}

json_record() {
    local name primary w h x y refresh scale mm_w mm_h desc
    IFS='|' read -r name primary w h x y refresh scale mm_w mm_h desc <<< "$1"

    local dpi
    if [[ "$BACKEND" == "x11" ]]; then
        dpi="$LOGICAL_DPI"
        scale="$(calc "printf \"%.4f\", $dpi / $BASE_DPI")"
    else
        [[ -z "$scale" ]] && scale="1"
        dpi="$(calc "printf \"%d\", int($BASE_DPI * $scale + 0.5)")"
    fi

    local legacy_w legacy_h
    if [[ "$BACKEND" == "x11" ]]; then
        legacy_w="$w"; legacy_h="$h"
    else
        legacy_w="$(round_div "$w" "$scale")"; legacy_h="$(round_div "$h" "$scale")"
    fi

    local phys_dpi="null"
    [[ -n "$mm_w" && "$mm_w" != "0" ]] && phys_dpi="$(calc "printf \"%d\", int($w * $MM_PER_INCH / $mm_w + 0.5)")"

    printf '  {"name": "%s", "primary": %s, "width": %s, "height": %s, "x": %s, "y": %s,' \
        "$(json_escape "$name")" "$( [[ "$primary" == "1" ]] && echo true || echo false )" \
        "${w:-null}" "${h:-null}" "${x:-null}" "${y:-null}"
    printf ' "refresh": %s, "scale": %s, "dpi": %s, "physicalDpi": %s,' \
        "${refresh:-null}" "$scale" "$dpi" "$phys_dpi"
    printf ' "widthMm": %s, "heightMm": %s, "cursorSize": %s,' \
        "${mm_w:-null}" "${mm_h:-null}" "$CURSOR_SIZE"
    printf ' "legacyWidth": %s, "legacyHeight": %s, "description": "%s"}' \
        "${legacy_w:-null}" "${legacy_h:-null}" "$(json_escape "$desc")"
}

# ---------------------------------------------------------------------- run --
if (( DEBUG )); then
    show_commands
    exit 0
fi

mapfile -t RECORDS < <(collect_records)
(( ${#RECORDS[@]} )) || die "no enabled outputs reported by $(backend_label) (try --backend x11, or --debug to see the commands)"

# Pick the outputs to report: the named one, all of them, or the primary.
SELECTED=()
if [[ -n "$OUTPUT_FILTER" ]]; then
    needle="$OUTPUT_FILTER"
    (( CASE_SENSITIVE )) || needle="$(printf '%s' "$needle" | tr '[:upper:]' '[:lower:]')"
    for rec in "${RECORDS[@]}"; do
        name="${rec%%|*}"
        (( CASE_SENSITIVE )) || name="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
        [[ "$name" == "$needle" || "$name" == *"$needle"* ]] && SELECTED+=("$rec")
    done
    (( ${#SELECTED[@]} )) || die "no output matching '$OUTPUT_FILTER' (have: $(printf '%s ' "${RECORDS[@]%%|*}"))"
elif (( SHOW_ALL )); then
    SELECTED=("${RECORDS[@]}")
else
    for rec in "${RECORDS[@]}"; do
        [[ "$(cut -d'|' -f2 <<< "$rec")" == "1" ]] && { SELECTED=("$rec"); break; }
    done
    (( ${#SELECTED[@]} )) || SELECTED=("${RECORDS[0]}")
fi

LOGICAL_DPI="$(logical_dpi)"
CURSOR_SIZE="$(cursor_size)"

if (( AS_JSON )); then
    echo "["
    for i in "${!SELECTED[@]}"; do
        json_record "${SELECTED[$i]}"
        (( i < ${#SELECTED[@]} - 1 )) && echo "," || echo
    done
    echo "]"
    exit 0
fi

printf '%s-- session --%s\n' "$C_HEAD" "$C_RESET"
kv "Backend" "$(backend_label)"
kv "Session" "$SESSION  ${C_DIM}XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-$UNSET_TEXT}, ${XDG_CURRENT_DESKTOP:-no desktop}${C_RESET}"
kv "Outputs" "${#RECORDS[@]} enabled, showing ${#SELECTED[@]}"

for rec in "${SELECTED[@]}"; do
    print_record "$rec"
done

echo
printf '%s-- toolkit hints --%s\n' "$C_HEAD" "$C_RESET"
kv "Xft.dpi"                     "$( x="$(xresource 'Xft.dpi')"; [[ -n "$x" ]] && echo "$x" || echo "$UNSET_TEXT" )"
kv "GDK_SCALE"                   "$(env_or_unset GDK_SCALE)"
kv "GDK_DPI_SCALE"               "$(env_or_unset GDK_DPI_SCALE)"
kv "QT_SCALE_FACTOR"             "$(env_or_unset QT_SCALE_FACTOR)"
kv "QT_AUTO_SCREEN_SCALE_FACTOR" "$(env_or_unset QT_AUTO_SCREEN_SCALE_FACTOR)"
kv "XCURSOR_SIZE"                "$(env_or_unset XCURSOR_SIZE)"
kv "scaling-factor"              "$( s="$(gsetting scaling-factor)"; [[ -n "$s" ]] && echo "$s" || echo "$UNSET_TEXT" )"
kv "text-scaling-factor"         "$( s="$(gsetting text-scaling-factor)"; [[ -n "$s" ]] && echo "$s" || echo "$UNSET_TEXT" )"
