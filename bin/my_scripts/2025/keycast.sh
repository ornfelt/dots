#!/usr/bin/env bash
# keycast.sh - start/stop screenkey (on-screen keystroke display)
set -euo pipefail

# ------------------------------------------------------------------ colors --
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_OK=$'\033[1;32m'
    C_ERR=$'\033[1;31m'
    C_WARN=$'\033[1;33m'
    C_INFO=$'\033[1;36m'
    C_DBG=$'\033[1;35m'
else
    C_RESET='' C_OK='' C_ERR='' C_WARN='' C_INFO='' C_DBG=''
fi

ok()   { printf '%s[ ok ]%s %s\n'  "$C_OK"   "$C_RESET" "$*"; }
err()  { printf '%s[fail]%s %s\n'  "$C_ERR"  "$C_RESET" "$*" >&2; }
warn() { printf '%s[warn]%s %s\n'  "$C_WARN" "$C_RESET" "$*" >&2; }
info() { printf '%s[info]%s %s\n'  "$C_INFO" "$C_RESET" "$*"; }
dbg()  { printf '%s[ dry]%s %s\n'  "$C_DBG"  "$C_RESET" "$*"; }

die() { err "$*"; exit 1; }

# ---------------------------------------------------------------- defaults --
CMD="start"                 # start | kill | status  (also accepted positionally)
CORNER="bottom-right"       # bottom-right|bottom-left|top-right|top-left|none
MARGIN="24"                 # px between the window and the screen edges
HEIGHT="44"                 # window height in px (screenkey scales the font to it)
WIDTH=""                    # window width in px; empty = derived from --max-keys
MAX_KEYS="5"                # roughly how many keystrokes fit before old ones scroll off
POSITION="bottom"           # only used with --corner none: top|center|bottom|fixed
FONT_SIZE="small"           # small | medium | large
TIMEOUT="2.5"               # seconds a keystroke stays on screen
OPACITY="0"                 # 0 = fully transparent background
BG_COLOR="black"
FONT_COLOR="#ebdbb2"
KEY_MODE="composed"         # composed | translated | keysyms | raw
MODS_MODE="normal"          # normal | emacs | mac | win
GEOMETRY=""                 # explicit WxH+X+Y, overrides --corner/--width/--height
SCREEN_SIZE=""              # explicit WxH of the screen, skips autodetection
EXTRA_ARGS=()               # anything after `--` is passed straight to screenkey
DEBUG=0
ASSUME_YES=0

usage() {
    cat <<EOF
Usage: ${0##*/} [start|kill|status] [options] [-- <screenkey args>]

Commands (positional, or via --cmd):
  start                 launch screenkey (default)
  kill | stop           kill any running screenkey process
  status                report whether screenkey is running

Placement (a fixed geometry is computed from these):
  -C, --corner <c>      bottom-right|bottom-left|top-right|top-left|none
                                                        (default: $CORNER)
      --margin <px>     gap to the screen edges         (default: $MARGIN)
  -H, --height <px>     window height, drives font size (default: $HEIGHT)
  -W, --width <px>      window width                    (default: from --max-keys)
  -n, --max-keys <n>    keystrokes visible at a time    (default: $MAX_KEYS)
      --screen-size <WxH>  skip screen autodetection    (default: autodetect)
  -g, --geometry <geo>  explicit WxH+X+Y, overrides the above
  -p, --position <pos>  only with --corner none         (default: $POSITION)

Appearance / behaviour:
  -s, --font-size <sz>  small|medium|large              (default: $FONT_SIZE)
  -t, --timeout <sec>   seconds a key stays visible     (default: $TIMEOUT)
  -o, --opacity <0-1>   background opacity              (default: $OPACITY)
      --bg-color <col>  background color                (default: $BG_COLOR)
      --font-color <c>  font color                      (default: $FONT_COLOR)
  -k, --key-mode <m>    composed|translated|keysyms|raw (default: $KEY_MODE)
  -m, --mods-mode <m>   normal|emacs|mac|win            (default: $MODS_MODE)

Misc:
  -c, --cmd <cmd>       same as the positional command
  -y, --yes             answer yes to the install prompt
  -d, --debug           print commands instead of running them
  -h, --help            show this help

Examples:
  ${0##*/}                          # small, bottom right, ~5 keys, no background
  ${0##*/} kill                     # stop it
  ${0##*/} -n 3 -H 36               # even smaller, ~3 keys
  ${0##*/} --debug start            # show the computed geometry and command
  ${0##*/} -- --screen 1            # pass extra flags to screenkey
EOF
}

# --------------------------------------------------------------------- run --
# Runs a command, or just prints it when --debug is set.
run() {
    if (( DEBUG )); then
        dbg "$(printf '%q ' "$@")"
        return 0
    fi
    "$@"
}

need_arg() { [[ -n "${2:-}" ]] || die "option '$1' requires a value"; }

# ------------------------------------------------------------ arg parsing ---
POSITIONAL_SEEN=0
while (( $# )); do
    case "$1" in
        start|kill|stop|status)
            (( POSITIONAL_SEEN )) && die "unexpected extra command: $1"
            CMD="$1"; POSITIONAL_SEEN=1; shift ;;
        -c|--cmd)        need_arg "$1" "${2:-}"; CMD="$2";         shift 2 ;;
        --cmd=*)         CMD="${1#*=}";                              shift ;;
        -C|--corner)     need_arg "$1" "${2:-}"; CORNER="$2";      shift 2 ;;
        --corner=*)      CORNER="${1#*=}";                           shift ;;
        --margin)        need_arg "$1" "${2:-}"; MARGIN="$2";      shift 2 ;;
        --margin=*)      MARGIN="${1#*=}";                           shift ;;
        -H|--height)     need_arg "$1" "${2:-}"; HEIGHT="$2";      shift 2 ;;
        --height=*)      HEIGHT="${1#*=}";                           shift ;;
        -W|--width)      need_arg "$1" "${2:-}"; WIDTH="$2";       shift 2 ;;
        --width=*)       WIDTH="${1#*=}";                            shift ;;
        -n|--max-keys)   need_arg "$1" "${2:-}"; MAX_KEYS="$2";    shift 2 ;;
        --max-keys=*)    MAX_KEYS="${1#*=}";                         shift ;;
        --screen-size)   need_arg "$1" "${2:-}"; SCREEN_SIZE="$2"; shift 2 ;;
        --screen-size=*) SCREEN_SIZE="${1#*=}";                      shift ;;
        -p|--position)   need_arg "$1" "${2:-}"; POSITION="$2";    shift 2 ;;
        --position=*)    POSITION="${1#*=}";                         shift ;;
        -s|--font-size)  need_arg "$1" "${2:-}"; FONT_SIZE="$2";   shift 2 ;;
        --font-size=*)   FONT_SIZE="${1#*=}";                        shift ;;
        -t|--timeout)    need_arg "$1" "${2:-}"; TIMEOUT="$2";     shift 2 ;;
        --timeout=*)     TIMEOUT="${1#*=}";                          shift ;;
        -o|--opacity)    need_arg "$1" "${2:-}"; OPACITY="$2";     shift 2 ;;
        --opacity=*)     OPACITY="${1#*=}";                          shift ;;
        --bg-color)      need_arg "$1" "${2:-}"; BG_COLOR="$2";    shift 2 ;;
        --bg-color=*)    BG_COLOR="${1#*=}";                         shift ;;
        --font-color)    need_arg "$1" "${2:-}"; FONT_COLOR="$2";  shift 2 ;;
        --font-color=*)  FONT_COLOR="${1#*=}";                       shift ;;
        -k|--key-mode)   need_arg "$1" "${2:-}"; KEY_MODE="$2";    shift 2 ;;
        --key-mode=*)    KEY_MODE="${1#*=}";                         shift ;;
        -m|--mods-mode)  need_arg "$1" "${2:-}"; MODS_MODE="$2";   shift 2 ;;
        --mods-mode=*)   MODS_MODE="${1#*=}";                        shift ;;
        -g|--geometry)   need_arg "$1" "${2:-}"; GEOMETRY="$2";    shift 2 ;;
        --geometry=*)    GEOMETRY="${1#*=}";                         shift ;;
        -y|--yes)        ASSUME_YES=1;                               shift ;;
        -d|--debug)      DEBUG=1;                                    shift ;;
        -h|--help)       usage; exit 0 ;;
        --)              shift; EXTRA_ARGS+=("$@"); break ;;
        -*)              die "unknown option: $1 (try --help)" ;;
        *)               die "unknown argument: $1 (try --help)" ;;
    esac
done

case "$CMD" in
    stop) CMD="kill" ;;
    start|kill|status) ;;
    *) die "unknown command: $CMD (start|kill|status)" ;;
esac

# ------------------------------------------------------------- install bit --
SUDO=""
if [[ $EUID -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 && SUDO="sudo"
fi

install_screenkey() {
    if command -v apt-get >/dev/null 2>&1; then
        info "installing screenkey with apt-get..."
        run $SUDO apt-get update
        run $SUDO apt-get install -y screenkey
    elif command -v pacman >/dev/null 2>&1; then
        info "installing screenkey with pacman..."
        run $SUDO pacman -S --needed --noconfirm screenkey
    else
        err "no supported package manager found (need apt-get or pacman)"
        info "install screenkey manually: https://gitlab.com/screenkey/screenkey"
        return 1
    fi
}

ensure_screenkey() {
    if command -v screenkey >/dev/null 2>&1; then
        return 0
    fi

    warn "screenkey is not installed"
    local answer="n"
    if (( ASSUME_YES )); then
        answer="y"
        info "--yes given, installing without asking"
    else
        read -r -p "Install it now? [y/N] " answer || true
    fi

    case "${answer,,}" in
        y|yes) ;;
        *) die "screenkey is required, aborting" ;;
    esac

    install_screenkey || die "installation failed"

    if (( DEBUG )); then
        return 0
    fi
    command -v screenkey >/dev/null 2>&1 || die "screenkey still not found after install"
    ok "screenkey installed"
}

# ------------------------------------------------------------ geometry bit --
# Screen size as WxH, from --screen-size, xdpyinfo or xrandr.
detect_screen_size() {
    local dims=""
    if [[ -n "$SCREEN_SIZE" ]]; then
        dims="$SCREEN_SIZE"
    elif command -v xdpyinfo >/dev/null 2>&1; then
        dims=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {print $2; exit}' || true)
    elif command -v xrandr >/dev/null 2>&1; then
        dims=$(xrandr --query 2>/dev/null \
               | awk '/ connected primary/ {print $4; exit} / connected/ {print $3; exit}' \
               | cut -d+ -f1 || true)
    fi

    if [[ ! "$dims" =~ ^[0-9]+x[0-9]+$ ]]; then
        warn "could not detect screen size, assuming 1920x1080 (use --screen-size)"
        dims="1920x1080"
    fi
    printf '%s\n' "$dims"
}

# Width per keystroke, as a percentage of the window height. screenkey scales
# the font to the window height, so this tracks --font-size.
key_width_pct() {
    case "$FONT_SIZE" in
        small)  printf '88\n' ;;
        medium) printf '132\n' ;;
        large)  printf '198\n' ;;
        *)      die "unknown font size: $FONT_SIZE (small|medium|large)" ;;
    esac
}

compute_geometry() {
    local dims sw sh w h x y pct
    dims=$(detect_screen_size)
    sw="${dims%x*}"; sh="${dims#*x}"

    [[ "$HEIGHT" =~ ^[0-9]+$ ]]   || die "--height must be a number of pixels"
    [[ "$MARGIN" =~ ^[0-9]+$ ]]   || die "--margin must be a number of pixels"
    [[ "$MAX_KEYS" =~ ^[0-9]+$ ]] || die "--max-keys must be a number"
    h="$HEIGHT"

    if [[ -n "$WIDTH" ]]; then
        [[ "$WIDTH" =~ ^[0-9]+$ ]] || die "--width must be a number of pixels"
        w="$WIDTH"
    else
        pct=$(key_width_pct)
        w=$(( MAX_KEYS * h * pct / 100 ))
    fi

    case "$CORNER" in
        bottom-right) x=$(( sw - w - MARGIN )); y=$(( sh - h - MARGIN )) ;;
        bottom-left)  x=$MARGIN;                y=$(( sh - h - MARGIN )) ;;
        top-right)    x=$(( sw - w - MARGIN )); y=$MARGIN ;;
        top-left)     x=$MARGIN;                y=$MARGIN ;;
        *) die "unknown corner: $CORNER (bottom-right|bottom-left|top-right|top-left|none)" ;;
    esac
    (( x < 0 )) && x=0
    (( y < 0 )) && y=0

    printf '%dx%d+%d+%d\n' "$w" "$h" "$x" "$y"
}

# ------------------------------------------------------------- process bit --
# Prints the pids of running screenkey processes (never this script's own pid).
screenkey_pids() {
    local pids=() p
    while read -r p; do
        [[ -n "$p" ]] || continue
        [[ "$p" == "$$" || "$p" == "$PPID" ]] && continue
        pids+=("$p")
    done < <(pgrep -f '(^|/)screenkey([[:space:]]|$)' 2>/dev/null || true)
    (( ${#pids[@]} )) && printf '%s\n' "${pids[@]}"
    return 0
}

do_status() {
    local pids
    pids=$(screenkey_pids | tr '\n' ' ')
    pids="${pids% }"
    if [[ -n "$pids" ]]; then
        ok "screenkey is running (pid: $pids)"
        return 0
    fi
    info "screenkey is not running"
    return 1
}

do_kill() {
    local pids
    mapfile -t pids < <(screenkey_pids)

    if (( ${#pids[@]} == 0 )); then
        info "no screenkey process found, nothing to kill"
        return 0
    fi

    info "killing screenkey (pid: ${pids[*]})"
    run kill -TERM "${pids[@]}" 2>/dev/null || true

    if (( DEBUG )); then
        return 0
    fi

    # Give it a moment, then force any survivors.
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        sleep 0.2
        mapfile -t pids < <(screenkey_pids)
        (( ${#pids[@]} == 0 )) && break
    done

    if (( ${#pids[@]} )); then
        warn "still alive, sending SIGKILL to ${pids[*]}"
        kill -KILL "${pids[@]}" 2>/dev/null || true
        sleep 0.2
        mapfile -t pids < <(screenkey_pids)
        (( ${#pids[@]} )) && die "could not kill screenkey (pid: ${pids[*]})"
    fi

    ok "screenkey stopped"
}

do_start() {
    ensure_screenkey

    local pids
    pids=$(screenkey_pids | tr '\n' ' ')
    if [[ -n "${pids% }" ]]; then
        warn "screenkey is already running (pid: ${pids% })"
        info "run '${0##*/} kill' to stop it first"
        return 1
    fi

    local args=(
        --font-size "$FONT_SIZE"
        --timeout "$TIMEOUT"
        --opacity "$OPACITY"
        --bg-color "$BG_COLOR"
        --font-color "$FONT_COLOR"
        --key-mode "$KEY_MODE"
        --mods-mode "$MODS_MODE"
    )

    local geometry="$GEOMETRY"
    if [[ -z "$geometry" && "$CORNER" != "none" ]]; then
        geometry=$(compute_geometry)
        info "geometry ${geometry} (${CORNER}, ~${MAX_KEYS} keys visible)"
    fi

    if [[ -n "$geometry" ]]; then
        # a fixed geometry only makes sense with the fixed position
        args+=(--position fixed --geometry "$geometry")
    else
        args+=(--position "$POSITION")
    fi
    (( ${#EXTRA_ARGS[@]} )) && args+=("${EXTRA_ARGS[@]}")

    run screenkey "${args[@]}"

    if (( DEBUG )); then
        return 0
    fi
    ok "screenkey started"
}

case "$CMD" in
    start)  do_start ;;
    kill)   do_kill ;;
    status) do_status ;;
esac
