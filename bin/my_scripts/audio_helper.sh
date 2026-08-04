#!/usr/bin/env bash
# =============================================================================
#  audio-helper.sh - inspect, explain and test the Linux audio stack
#
#  Supports backends : alsa | pulse | pipewire | auto
#  Supports distros  : Debian/Ubuntu (apt), Arch/Manjaro (pacman),
#                      Fedora (dnf), openSUSE (zypper), Alpine (apk)
#
#  Everything is printed with descriptions so the output is understandable
#  without memorising what each tool spits out. Use -v for the long version,
#  --raw for the untouched command output, --debug to only print commands.
# =============================================================================

set -uo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
VERSION="1.0.0"

# -----------------------------------------------------------------------------
# Defaults (overridable by CLI flags)
# -----------------------------------------------------------------------------
COMMAND=""
BACKEND="auto"          # auto | alsa | pulse | pipewire
DEVICE=""               # e.g. default, hw:0,0, plughw:1,0, or a pulse sink name
CHANNELS=2
RATE=48000
FREQ=440
DURATION=3
LOOPS=1
TEST_TYPE="auto"        # auto | speaker | pink | white | wav | tone | bell
VERBOSE=false
DEBUG=false
RAW_MODE="off"          # off | only | both
SHOW_ALL=false
COLOR_MODE="auto"       # auto | always | never

BACKEND_DETECTED=""
BACKEND_HOW=""
RUN_OUT=""
RUN_RC=0
declare -a MISSING_PKGS=()

# -----------------------------------------------------------------------------
# Colors + output helpers
# -----------------------------------------------------------------------------
setup_colors() {
    local use=false
    case "$COLOR_MODE" in
        always) use=true ;;
        never)  use=false ;;
        auto)   if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then use=true; fi ;;
    esac
    if $use; then
        RESET='\033[0m'
        RED='\033[31m'
        GREEN='\033[32m'
        YELLOW='\033[33m'
        BLUE='\033[34m'
        MAGENTA='\033[35m'
        CYAN='\033[36m'
        DARKGRAY='\033[90m'
        BOLD='\033[1m'
    else
        RESET=''; RED=''; GREEN=''; YELLOW=''; BLUE=''
        MAGENTA=''; CYAN=''; DARKGRAY=''; BOLD=''
    fi
}
setup_colors

write_ok()      { echo -e "${GREEN}${1}${RESET}"; }
write_err()     { echo -e "${RED}${1}${RESET}"; }
write_warn()    { echo -e "${YELLOW}${1}${RESET}"; }
write_info()    { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt(){ echo -e "${MAGENTA}${1}${RESET}"; }
write_dim()     { echo -e "${DARKGRAY}${1}${RESET}"; }
write_blue()    { echo -e "${BLUE}${1}${RESET}"; }

WIDTH=78
if command -v tput >/dev/null 2>&1; then
    _c="$(tput cols 2>/dev/null || echo 78)"
    [[ "$_c" =~ ^[0-9]+$ ]] && WIDTH=$(( _c > 100 ? 100 : _c ))
    unset _c
fi

hr() { local line; printf -v line '%*s' "$WIDTH" ''; write_dim "${line// /-}"; }

title() {
    echo
    echo -e "${BOLD}${MAGENTA}=== ${1} ===${RESET}"
    [[ -n "${2:-}" ]] && write_dim "    ${2}"
}

section() {
    echo
    echo -e "${BOLD}${CYAN}-- ${1}${RESET}"
    [[ -n "${2:-}" ]] && write_dim "   ${2}"
}

# key/value with fixed-width key
kv()  { printf "   ${GREEN}%-26s${RESET} %s\n" "${1}:" "${2}"; }
kv2() { printf "     ${CYAN}%-24s${RESET} %s\n" "${1}:" "${2}"; }

# explanation lines
note()  { echo -e "      ${DARKGRAY}-> ${*}${RESET}"; }
vnote() { if $VERBOSE; then echo -e "      ${DARKGRAY}-> ${*}${RESET}"; fi; }

bullet() { echo -e "   ${YELLOW}*${RESET} ${*}"; }

pretty() { [[ "$RAW_MODE" != "only" ]]; }

have() { command -v "$1" >/dev/null 2>&1; }

# -----------------------------------------------------------------------------
# Command execution / debug mode
# -----------------------------------------------------------------------------
cmdline() {
    local out="" a
    for a in "$@"; do
        if [[ "$a" =~ ^[A-Za-z0-9_./:=,@%+-]+$ ]]; then
            out+="${a} "
        else
            out+="$(printf '%q' "$a") "
        fi
    done
    printf '%s' "${out% }"
}

show_cmd() { echo -e "   ${MAGENTA}\$ $(cmdline "$@")${RESET}"; }

# print a shell one-liner exactly as typed (for pipelines and globs)
show_cmd_raw() { echo -e "   ${MAGENTA}\$ ${1}${RESET}"; }

# run <cmd...>
#   normal mode : executes, stores stdout+stderr in $RUN_OUT, code in $RUN_RC,
#                 returns 0 so the caller can format the result
#   debug mode  : only prints the command, returns 1 so the caller skips
#                 formatting but keeps walking through the remaining commands
run() {
    RUN_OUT=""; RUN_RC=0
    if $DEBUG; then
        show_cmd "$@"
        return 1
    fi
    if $VERBOSE || [[ "$RAW_MODE" != "off" ]]; then
        show_cmd "$@"
    fi
    RUN_OUT="$("$@" 2>&1)"
    RUN_RC=$?
    if [[ "$RAW_MODE" != "off" ]]; then
        write_dim "   +-- raw output ----------------------------------------"
        if [[ -n "$RUN_OUT" ]]; then
            printf '%s\n' "$RUN_OUT" | sed "s/^/   | /"
        else
            write_dim "   | (no output)"
        fi
        write_dim "   +-- exit code: ${RUN_RC} ---------------------------------"
    fi
    return 0
}

# run_live: for commands whose output should stream to the terminal (playback)
run_live() {
    RUN_RC=0
    if $DEBUG; then
        show_cmd "$@"
        return 1
    fi
    show_cmd "$@"
    echo
    "$@"
    RUN_RC=$?
    return 0
}

# read a file with the same debug semantics as run()
run_cat() {
    local f="$1"
    if $DEBUG; then
        show_cmd cat "$f"
        return 1
    fi
    if [[ ! -r "$f" ]]; then
        RUN_OUT=""; RUN_RC=1
        return 0
    fi
    run cat "$f"
}

# -----------------------------------------------------------------------------
# Distro / package handling
# -----------------------------------------------------------------------------
DISTRO_ID=""; DISTRO_LIKE=""; DISTRO_NAME=""; PKG_MGR=""; PKG_FAMILY=""

os_release_get() {
    [[ -r /etc/os-release ]] || return 1
    sed -n "s/^$1=//p" /etc/os-release | tr -d '"' | head -n1
}

detect_distro() {
    DISTRO_ID="$(os_release_get ID || true)"
    DISTRO_LIKE="$(os_release_get ID_LIKE || true)"
    DISTRO_NAME="$(os_release_get PRETTY_NAME || true)"
    [[ -z "$DISTRO_NAME" ]] && DISTRO_NAME="${DISTRO_ID:-unknown Linux}"

    if have pacman;  then PKG_MGR="pacman";  PKG_FAMILY="arch"
    elif have apt;    then PKG_MGR="apt";     PKG_FAMILY="debian"
    elif have apt-get;then PKG_MGR="apt-get"; PKG_FAMILY="debian"
    elif have dnf;    then PKG_MGR="dnf";     PKG_FAMILY="fedora"
    elif have zypper; then PKG_MGR="zypper";  PKG_FAMILY="suse"
    elif have apk;    then PKG_MGR="apk";     PKG_FAMILY="alpine"
    else
        # fall back on os-release when no package manager binary is visible
        case " ${DISTRO_ID} ${DISTRO_LIKE} " in
            *arch*)            PKG_MGR="pacman"; PKG_FAMILY="arch" ;;
            *debian*|*ubuntu*) PKG_MGR="apt";    PKG_FAMILY="debian" ;;
            *fedora*|*rhel*)   PKG_MGR="dnf";    PKG_FAMILY="fedora" ;;
            *suse*)            PKG_MGR="zypper"; PKG_FAMILY="suse" ;;
            *)                 PKG_MGR="unknown";PKG_FAMILY="unknown" ;;
        esac
    fi
}

# pkg_for <tool> -> package name for the detected distro
pkg_for() {
    local tool="$1"
    case "$PKG_FAMILY" in
        debian)
            case "$tool" in
                aplay|arecord|amixer|alsamixer|alsactl|speaker-test|alsa-info.sh|alsaucm) echo "alsa-utils" ;;
                pactl|paplay|parecord|pacat|pamon|pactl) echo "pulseaudio-utils" ;;
                pw-cli|pw-dump|pw-play|pw-cat|pw-top|pw-metadata|pw-record) echo "pipewire-bin" ;;
                wpctl) echo "wireplumber" ;;
                play|sox) echo "sox" ;;
                jq) echo "jq" ;;
                lsof) echo "lsof" ;;
                *) echo "$tool" ;;
            esac ;;
        arch)
            case "$tool" in
                aplay|arecord|amixer|alsamixer|alsactl|speaker-test|alsa-info.sh|alsaucm) echo "alsa-utils" ;;
                pactl|paplay|parecord|pacat|pamon) echo "libpulse" ;;
                pw-cli|pw-dump|pw-play|pw-cat|pw-top|pw-metadata|pw-record) echo "pipewire" ;;
                wpctl) echo "wireplumber" ;;
                play|sox) echo "sox" ;;
                jq) echo "jq" ;;
                lsof) echo "lsof" ;;
                *) echo "$tool" ;;
            esac ;;
        fedora)
            case "$tool" in
                aplay|arecord|amixer|alsamixer|alsactl|speaker-test|alsa-info.sh|alsaucm) echo "alsa-utils" ;;
                pactl|paplay|parecord|pacat|pamon) echo "pulseaudio-utils" ;;
                pw-cli|pw-dump|pw-play|pw-cat|pw-top|pw-metadata|pw-record) echo "pipewire-utils" ;;
                wpctl) echo "wireplumber" ;;
                play|sox) echo "sox" ;;
                *) echo "$tool" ;;
            esac ;;
        suse)
            case "$tool" in
                aplay|arecord|amixer|alsamixer|alsactl|speaker-test) echo "alsa-utils" ;;
                pactl|paplay|parecord|pacat) echo "pulseaudio-utils" ;;
                pw-cli|pw-dump|pw-play|pw-cat|pw-top|pw-metadata|pw-record) echo "pipewire-tools" ;;
                wpctl) echo "wireplumber" ;;
                play|sox) echo "sox" ;;
                *) echo "$tool" ;;
            esac ;;
        alpine)
            case "$tool" in
                aplay|arecord|amixer|alsamixer|alsactl|speaker-test) echo "alsa-utils" ;;
                pactl|paplay|parecord|pacat) echo "pulseaudio-utils" ;;
                pw-cli|pw-dump|pw-play|pw-cat|pw-top|pw-metadata|pw-record) echo "pipewire-tools" ;;
                wpctl) echo "wireplumber" ;;
                play|sox) echo "sox" ;;
                *) echo "$tool" ;;
            esac ;;
        *) echo "$tool" ;;
    esac
}

install_hint() {
    local pkg="$1"
    case "$PKG_MGR" in
        apt|apt-get) echo "sudo ${PKG_MGR} install -y ${pkg}" ;;
        pacman)      echo "sudo pacman -S --needed ${pkg}" ;;
        dnf)         echo "sudo dnf install -y ${pkg}" ;;
        zypper)      echo "sudo zypper install -y ${pkg}" ;;
        apk)         echo "sudo apk add ${pkg}" ;;
        *)           echo "install the package providing '${pkg}' with your package manager" ;;
    esac
}

remember_missing() {
    local pkg="$1" x
    if ((${#MISSING_PKGS[@]})); then
        for x in "${MISSING_PKGS[@]}"; do [[ "$x" == "$pkg" ]] && return 0; done
    fi
    MISSING_PKGS+=("$pkg")
}

# need_tool <tool> [why] -> 0 if usable, 1 (with install hint) otherwise
need_tool() {
    local tool="$1" why="${2:-}"
    if have "$tool"; then return 0; fi
    local pkg; pkg="$(pkg_for "$tool")"
    remember_missing "$pkg"
    if $DEBUG; then
        # In debug mode we still want to show the command that WOULD run,
        # so report the missing tool but let the caller continue.
        write_warn "   [note] '${tool}' is not installed here${why:+ (${why})}"
        write_dim  "      -> $(install_hint "$pkg")"
        return 0
    fi
    write_warn "   [skip] '${tool}' is not installed${why:+ (${why})}"
    write_dim  "      -> $(install_hint "$pkg")"
    return 1
}

print_missing_summary() {
    ((${#MISSING_PKGS[@]})) || return 0
    section "Missing tools" "Install these to get the full picture"
    local pkg
    for pkg in "${MISSING_PKGS[@]}"; do
        bullet "$(install_hint "$pkg")"
    done
}

# -----------------------------------------------------------------------------
# Backend detection
# -----------------------------------------------------------------------------
detect_backend() {
    local b="alsa" how="no sound server found - falling back to bare ALSA"

    if have pactl; then
        local info
        info="$(pactl info 2>/dev/null)"
        if [[ -n "$info" ]]; then
            if grep -qi 'PipeWire' <<<"$info"; then
                b="pipewire"; how="pactl reached a server that identifies itself as PipeWire (pipewire-pulse bridge)"
            else
                b="pulse"; how="pactl reached a genuine PulseAudio daemon"
            fi
        fi
    fi
    if [[ "$b" == "alsa" ]] && have wpctl && wpctl status >/dev/null 2>&1; then
        b="pipewire"; how="wpctl can talk to the WirePlumber session manager"
    fi
    if [[ "$b" == "alsa" ]]; then
        if pgrep -x pipewire >/dev/null 2>&1; then
            b="pipewire"; how="a 'pipewire' process is running (no pulse compatibility socket answered)"
        elif pgrep -x pulseaudio >/dev/null 2>&1; then
            b="pulse"; how="a 'pulseaudio' process is running"
        fi
    fi

    BACKEND_DETECTED="$b"
    BACKEND_HOW="$how"
}

resolve_backend() {
    detect_backend
    if [[ "$BACKEND" == "auto" ]]; then
        BACKEND="$BACKEND_DETECTED"
    fi
}

# Default PCM/device string for the active backend
default_device() {
    if [[ -n "$DEVICE" ]]; then echo "$DEVICE"; return; fi
    case "$BACKEND" in
        pulse)    echo "pulse" ;;
        pipewire) echo "pipewire" ;;
        *)        echo "default" ;;
    esac
}

find_sample_file() {
    local c
    for c in \
        /usr/share/sounds/alsa/Front_Center.wav \
        /usr/share/sounds/alsa/Noise.wav \
        /usr/share/sounds/freedesktop/stereo/bell.oga \
        /usr/share/sounds/freedesktop/stereo/complete.oga \
        /usr/share/sounds/freedesktop/stereo/message.oga \
        /usr/share/sounds/Oxygen-Sys-App-Positive.ogg
    do
        [[ -f "$c" ]] && { echo "$c"; return 0; }
    done
    return 1
}

# =============================================================================
#  HELP
# =============================================================================
usage() {
    echo -e "${BOLD}${MAGENTA}${SCRIPT_NAME}${RESET} ${DARKGRAY}v${VERSION}${RESET} - Linux audio inspector & tester"
    hr
    write_info "USAGE"
    echo "  ${SCRIPT_NAME} <command> [options]"
    echo
    write_info "COMMANDS"
    printf "   ${GREEN}%-12s${RESET} %s\n" "info"     "Overview: kernel modules, cards, server, defaults"
    printf "   ${GREEN}%-12s${RESET} %s\n" "devices"  "List playback + capture devices for the backend"
    printf "   ${GREEN}%-12s${RESET} %s\n" "test"     "Play a test sound (see --type)"
    printf "   ${GREEN}%-12s${RESET} %s\n" "record"   "Record a few seconds from the mic, then play it back"
    printf "   ${GREEN}%-12s${RESET} %s\n" "mixer"    "Volume / mute state of every channel or sink"
    printf "   ${GREEN}%-12s${RESET} %s\n" "streams"  "Applications currently producing/consuming audio"
    printf "   ${GREEN}%-12s${RESET} %s\n" "config"   "Config files, runtime settings, buffer/latency values"
    printf "   ${GREEN}%-12s${RESET} %s\n" "modules"  "Kernel side: snd_* modules, /proc/asound, firmware"
    printf "   ${GREEN}%-12s${RESET} %s\n" "diagnose" "Run health checks and suggest fixes"
    printf "   ${GREEN}%-12s${RESET} %s\n" "deps"     "Which audio tools are installed / how to install them"
    printf "   ${GREEN}%-12s${RESET} %s\n" "help"     "This text"
    echo
    write_info "OPTIONS"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-b, --backend <name>"  "alsa | pulse | pipewire | auto   (default: auto)"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-D, --device <dev>"    "PCM or sink, e.g. default, hw:0,0, plughw:1,0"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-c, --channels <n>"    "Channel count for test/record (default: ${CHANNELS})"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-r, --rate <hz>"       "Sample rate for test/record (default: ${RATE})"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-t, --type <kind>"     "auto | speaker | pink | white | wav | tone | bell"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-f, --freq <hz>"       "Sine frequency for speaker/tone (default: ${FREQ})"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-d, --duration <sec>"  "Seconds for tone/record (default: ${DURATION})"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-l, --loops <n>"       "speaker-test loops (default: ${LOOPS})"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-v, --verbose"         "Much more explanation + show every command"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-a, --all"             "Include the long/noisy listings too"
    printf "   ${GREEN}%-24s${RESET} %s\n" "    --raw"             "Print raw command output ONLY (no formatting)"
    printf "   ${GREEN}%-24s${RESET} %s\n" "    --raw-also"        "Print raw output AND the formatted version"
    printf "   ${GREEN}%-24s${RESET} %s\n" "    --debug"           "Print the commands instead of running them"
    printf "   ${GREEN}%-24s${RESET} %s\n" "    --color <when>"    "auto | always | never"
    printf "   ${GREEN}%-24s${RESET} %s\n" "-h, --help"            "Show this help"
    echo
    write_info "BACKENDS"
    echo -e "   ${GREEN}alsa${RESET}     Kernel-level sound API. Devices look like ${YELLOW}hw:CARD,DEVICE${RESET}."
    write_dim "            hw:0,0 = raw hardware (no conversion), plughw:0,0 = with"
    write_dim "            automatic rate/format/channel conversion, default = whatever"
    write_dim "            /etc/asound.conf or ~/.asoundrc points at."
    echo -e "   ${GREEN}pulse${RESET}    PulseAudio sound server. Devices are named ${YELLOW}sinks${RESET} (output)"
    write_dim "            and ${YELLOW}sources${RESET} (input); apps connect as sink-inputs."
    echo -e "   ${GREEN}pipewire${RESET} Modern server that replaces both PulseAudio and JACK. It"
    write_dim "            usually still answers pactl through the pipewire-pulse bridge,"
    write_dim "            so 'pulse' commands work but report PipeWire."
    echo -e "   ${GREEN}auto${RESET}     Probe the system and pick whichever is actually running."
    echo
    write_info "EXAMPLES"
    bullet "${SCRIPT_NAME} info -v                      # full annotated system report"
    bullet "${SCRIPT_NAME} test                         # test sound on the detected backend"
    bullet "${SCRIPT_NAME} test -D default -c 2 -r 48000"
    bullet "${SCRIPT_NAME} test -b alsa -D plughw:1,0 -t pink"
    bullet "${SCRIPT_NAME} test -b pulse -t bell"
    bullet "${SCRIPT_NAME} devices -b pipewire"
    bullet "${SCRIPT_NAME} info --raw                   # untouched tool output"
    bullet "${SCRIPT_NAME} test --debug                 # just show me the command"
    bullet "${SCRIPT_NAME} diagnose"
    echo
    write_info "NOTES"
    write_dim "   * --debug never executes the reported commands, so you can copy them"
    write_dim "     into a terminal. Backend auto-detection still probes (read-only)."
    write_dim "   * Exit code is 0 unless a requested command failed."
    write_dim "   * NO_COLOR=1 in the environment also disables colors."
    hr
}

# =============================================================================
#  FORMATTERS
# =============================================================================

# aplay -l / arecord -l
format_alsa_devices() {
    local text="$1" kind="$2" line
    local card cardid cardlong dev devid devlong
    local found=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^card[[:space:]]+([0-9]+):[[:space:]]+([^[]+)\[([^]]*)\],[[:space:]]+device[[:space:]]+([0-9]+):[[:space:]]+([^[]+)\[([^]]*)\] ]]; then
            found=true
            card="${BASH_REMATCH[1]}"
            cardid="${BASH_REMATCH[2]}"; cardid="${cardid%% }"
            cardlong="${BASH_REMATCH[3]}"
            dev="${BASH_REMATCH[4]}"
            devid="${BASH_REMATCH[5]}"; devid="${devid%% }"
            devlong="${BASH_REMATCH[6]}"
            echo
            write_ok "   [ hw:${card},${dev} ]  ${cardlong} / ${devlong}"
            kv2 "Card index"   "${card}  (ALSA card id: ${cardid})"
            kv2 "Device index" "${dev}   (device id: ${devid})"
            if [[ "$kind" == "playback" ]]; then
                kv2 "Direct use"   "aplay -D hw:${card},${dev} file.wav"
                kv2 "Safe use"     "aplay -D plughw:${card},${dev} file.wav"
                kv2 "Test it"      "speaker-test -D plughw:${card},${dev} -c ${CHANNELS} -r ${RATE} -t sine"
            else
                kv2 "Direct use"   "arecord -D plughw:${card},${dev} -f cd out.wav"
            fi
            vnote "hw:X,Y talks to the hardware with no conversion: the card must natively"
            vnote "accept your rate/format or the command fails with 'Invalid argument'."
            vnote "plughw:X,Y inserts ALSA's plug layer which resamples and reformats for you."
        elif [[ "$line" =~ Subdevices:\ ([0-9]+)/([0-9]+) ]]; then
            kv2 "Subdevices free" "${BASH_REMATCH[1]} of ${BASH_REMATCH[2]}"
            vnote "0 free means something already has the device open in exclusive mode."
        fi
    done <<< "$text"
    if ! $found; then
        write_warn "   No ${kind} devices reported by ALSA."
        note "Either no driver is bound to your audio hardware, or another user/"
        note "container owns /dev/snd. Try: ${SCRIPT_NAME} modules"
    fi
}

# aplay -L / arecord -L  (PCM names)
format_alsa_pcms() {
    local text="$1" line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^[^[:space:]] ]]; then
            write_ok "   ${line}"
        else
            write_dim "       ${line#"${line%%[![:space:]]*}"}"
        fi
    done <<< "$text"
    note "Left column = PCM name you pass to -D. Indented lines are its description."
    vnote "Useful ones: 'default' (whatever your config points at), 'sysdefault' (card"
    vnote "default without user overrides), 'pulse'/'pipewire' (route via the server),"
    vnote "'hw:CARD=x,DEV=y' (direct), 'plughw:...' (converted), 'null' (discard)."
}

# pactl info
format_pactl_info() {
    local text="$1" line key val
    while IFS= read -r line; do
        [[ "$line" != *:* ]] && continue
        key="${line%%:*}"
        val="${line#*: }"
        [[ "$val" == "$line" ]] && val=""
        case "$key" in
            "Server Name")
                kv "Server implementation" "$val"
                note "If this mentions PipeWire, PulseAudio is only being emulated." ;;
            "Server Version")      kv "Server version" "$val" ;;
            "Server String")
                kv "Server socket" "$val"
                vnote "The unix socket clients connect to, usually under \$XDG_RUNTIME_DIR." ;;
            "Default Sample Specification")
                kv "Default sample spec" "$val"
                note "format / channel count / sample rate the server mixes at."
                vnote "s16le = signed 16-bit little-endian, float32le = 32-bit float, etc."
                vnote "Everything an app sends gets resampled into this before hitting the card." ;;
            "Default Channel Map")
                kv "Default channel map" "$val"
                vnote "Which speaker each channel index feeds (front-left, front-right, lfe...)." ;;
            "Default Sink")
                kv "Default OUTPUT (sink)" "$val"
                note "Where audio goes when an app does not request a specific device."
                if [[ "$val" == *auto_null* || "$val" == *dummy* ]]; then
                    write_err "      !! This is a dummy sink - no real hardware is attached."
                fi ;;
            "Default Source")
                kv "Default INPUT (source)" "$val"
                note "Microphone / capture device used by default. '.monitor' means it"
                note "records what is being played rather than a real microphone." ;;
            "Tile Size")
                kv "Shared memory tile" "$val"
                vnote "Block size used for zero-copy transfer between client and server." ;;
            "User Name"|"Host Name")
                kv "$key" "$val" ;;
            "Cookie")
                if $VERBOSE; then kv "Auth cookie" "$val"; fi ;;
            *)
                if $VERBOSE; then kv "$key" "$val"; fi ;;
        esac
    done <<< "$text"
}

# pactl list short sinks|sources
format_pactl_short() {
    local text="$1" kind="$2"
    local idx name driver spec state
    local any=false
    while IFS=$'\t' read -r idx name driver spec state; do
        [[ -z "${idx:-}" ]] && continue
        any=true
        echo
        write_ok "   [#${idx}] ${name}"
        kv2 "Driver module" "${driver:-?}"
        kv2 "Sample format" "${spec:-?}"
        kv2 "State"         "$(explain_state "${state:-}")"
        vnote "Use it explicitly with: pactl set-default-${kind%s} ${name}"
        vnote "or play to it with:     paplay --device=${name} file.wav"
    done <<< "$text"
    $any || write_warn "   No ${kind} found."
}

explain_state() {
    case "${1^^}" in
        RUNNING)   echo -e "${GREEN}RUNNING${RESET}   - actively moving audio right now" ;;
        IDLE)      echo -e "${YELLOW}IDLE${RESET}      - open and ready, nothing playing" ;;
        SUSPENDED) echo -e "${DARKGRAY}SUSPENDED${RESET} - powered down to save energy (normal; wakes on demand)" ;;
        "")        echo "unknown" ;;
        *)         echo "$1" ;;
    esac
}

# hw_params from /proc/asound/cardX/pcmYp/subZ/hw_params
format_hw_params() {
    local text="$1" line key val rate=0 period=0 buffer=0
    while IFS= read -r line; do
        [[ "$line" != *:* ]] && continue
        key="${line%%:*}"; val="${line#*: }"
        case "$key" in
            access)
                kv2 "Transfer mode" "$val"
                vnote "RW_INTERLEAVED = app writes L,R,L,R...; MMAP_* = shared memory ring." ;;
            format)
                kv2 "Sample format" "$val"
                vnote "S16_LE = signed 16-bit little-endian, S32_LE = 32-bit, FLOAT_LE = float." ;;
            channels) kv2 "Channels" "$val" ;;
            rate)
                rate="${val%% *}"
                kv2 "Sample rate" "${rate} Hz" ;;
            period_size)
                period="$val"
                kv2 "Period size" "${val} frames"
                vnote "Frames handed over per hardware interrupt - the latency granularity." ;;
            buffer_size)
                buffer="$val"
                kv2 "Buffer size" "${val} frames" ;;
        esac
    done <<< "$text"
    if [[ "$rate" =~ ^[0-9]+$ ]] && (( rate > 0 )); then
        local pms bms
        pms="$(awk -v p="$period" -v r="$rate" 'BEGIN{printf "%.2f", (p/r)*1000}')"
        bms="$(awk -v b="$buffer" -v r="$rate" 'BEGIN{printf "%.2f", (b/r)*1000}')"
        kv2 "Period latency" "${pms} ms"
        kv2 "Buffer latency" "${bms} ms  (worst-case output delay)"
        note "Smaller buffer = lower latency but more CPU wakeups and more xrun risk."
    fi
}

# =============================================================================
#  SECTIONS
# =============================================================================

section_system() {
    section "System" "Where we are running"
    kv "Distribution"    "${DISTRO_NAME}"
    kv "Package manager" "${PKG_MGR}"
    kv "Kernel"          "$(uname -r) ($(uname -m))"
    kv "Requested backend" "${1:-$BACKEND}"
    kv "Detected backend"  "${BACKEND_DETECTED}"
    note "${BACKEND_HOW}"
    kv "Using backend"   "${BACKEND}"
    if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
        kv "XDG_RUNTIME_DIR" "${XDG_RUNTIME_DIR}"
    else
        write_warn "   XDG_RUNTIME_DIR is not set"
        note "PulseAudio/PipeWire clients need it to find the server socket."
    fi
    vnote "Backend detection is read-only and runs even in --debug mode."
}

section_services() {
    have systemctl || return 0
    section "Audio services (user session)" "systemd --user units that provide sound"
    local unit state
    for unit in pipewire.socket pipewire.service pipewire-pulse.socket \
                pipewire-pulse.service wireplumber.service pulseaudio.socket \
                pulseaudio.service; do
        if $DEBUG; then continue; fi
        state="$(systemctl --user is-active "$unit" 2>/dev/null || true)"
        [[ -z "$state" || "$state" == "inactive" ]] && continue
        case "$state" in
            active) printf "   ${GREEN}%-28s${RESET} %s\n" "$unit" "active" ;;
            failed) printf "   ${RED}%-28s${RESET} %s\n"   "$unit" "FAILED" ;;
            *)      printf "   ${YELLOW}%-28s${RESET} %s\n" "$unit" "$state" ;;
        esac
    done
    if $DEBUG; then
        show_cmd systemctl --user is-active pipewire.service pipewire-pulse.service wireplumber.service pulseaudio.service
    fi
    vnote "Sockets being active is enough - the service starts on first client connect."
    vnote "pipewire-pulse provides the PulseAudio-compatible socket; wireplumber is the"
    vnote "session/policy manager that decides routing and default devices."
}

section_alsa_kernel() {
    section "Kernel sound cards" "/proc/asound/cards - what the kernel driver layer sees"
    if run_cat /proc/asound/cards; then
        if [[ -z "$RUN_OUT" || "$RUN_RC" -ne 0 ]]; then
            write_err "   Could not read /proc/asound/cards (no ALSA in this kernel/container?)"
        elif pretty; then
            printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
            note "Each entry is 'index [id]: driver - shortname'. The index is the number"
            note "you use in hw:INDEX,DEVICE."
        fi
    fi

    section "Sound-related kernel modules" "/proc/asound/modules"
    if run_cat /proc/asound/modules; then
        if [[ -n "$RUN_OUT" && "$RUN_RC" -eq 0 ]] && pretty; then
            printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
            note "Driver module bound to each card index (snd_hda_intel, snd_usb_audio, ...)."
        fi
    fi

    if $SHOW_ALL || $VERBOSE; then
        section "Loaded snd_* modules" "lsmod filtered on sound modules"
        if have lsmod; then
            if $DEBUG; then
                show_cmd lsmod
                show_cmd_raw "lsmod | awk 'NR==1 || /^snd/'"
            else
                lsmod 2>/dev/null | awk 'NR==1 || /^snd/' | sed 's/^/   /'
            fi
            vnote "'Used by' column shows refcounts; a module with 0 users may mean the"
            vnote "card is not in use, not that it is broken."
        fi
    fi
}

section_alsa_info() {
    section "ALSA playback devices" "aplay -l - hardware outputs the kernel exposes"
    if need_tool aplay "ALSA command line tools"; then
        if run aplay -l; then
            if [[ $RUN_RC -ne 0 ]]; then
                write_err "   aplay -l failed:"
                printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
            elif pretty; then
                format_alsa_devices "$RUN_OUT" "playback"
            fi
        fi

        section "ALSA capture devices" "arecord -l - hardware inputs"
        if run arecord -l; then
            if [[ $RUN_RC -eq 0 ]] && pretty; then
                format_alsa_devices "$RUN_OUT" "capture"
            fi
        fi

        if $SHOW_ALL || $VERBOSE; then
            section "ALSA PCM names" "aplay -L - every logical device you can pass to -D"
            if run aplay -L; then
                [[ $RUN_RC -eq 0 ]] && pretty && format_alsa_pcms "$RUN_OUT"
            fi
        else
            write_dim "   (use -a or -v to also list every logical PCM name from 'aplay -L')"
        fi
    fi
}

section_alsa_active_streams() {
    section "Active ALSA streams" "hw_params of every PCM currently open"
    local f found=false
    if $DEBUG; then
        show_cmd_raw 'cat /proc/asound/card*/pcm*/sub*/hw_params'
        return 0
    fi
    shopt -s nullglob
    for f in /proc/asound/card*/pcm*/sub*/hw_params; do
        local content
        content="$(cat "$f" 2>/dev/null)"
        [[ -z "$content" || "$content" == "closed" ]] && continue
        found=true
        local pcm="${f#/proc/asound/}"; pcm="${pcm%/hw_params}"
        echo
        write_ok "   [ ${pcm} ]"
        pretty && format_hw_params "$content"
        if ! pretty; then printf '%s\n' "$content" | sed 's/^/   | /'; fi
    done
    shopt -u nullglob
    if ! $found; then
        write_dim "   No PCM is currently open - nothing is playing or recording via ALSA."
        note "Start playback and re-run to see the negotiated rate/format/buffer sizes."
    fi
}

section_alsa_mixer() {
    section "ALSA mixer" "amixer - hardware volume controls and mute switches"
    need_tool amixer || return 0
    local card_arg=()
    [[ -n "$DEVICE" && "$DEVICE" =~ ^(hw|plughw):([0-9]+) ]] && card_arg=(-c "${BASH_REMATCH[2]}")
    if run amixer "${card_arg[@]}" ; then
        [[ $RUN_RC -ne 0 ]] && { write_err "   amixer failed"; return 0; }
        pretty || return 0
        local line ctl
        while IFS= read -r line; do
            if [[ "$line" =~ ^Simple\ mixer\ control\ \'([^\']+)\',([0-9]+) ]]; then
                ctl="${BASH_REMATCH[1]}"
                echo
                write_ok "   [ ${ctl} ]"
            elif [[ "$line" =~ Playback[[:space:]].*\[([0-9]+)%\].*\[(on|off)\] ]]; then
                local pct="${BASH_REMATCH[1]}" sw="${BASH_REMATCH[2]}"
                if [[ "$sw" == "off" ]]; then
                    kv2 "Playback" "$(echo -e "${RED}MUTED${RESET}") at ${pct}%"
                    note "This control is muted - unmute with: amixer set '${ctl}' unmute"
                else
                    kv2 "Playback" "${pct}%  (unmuted)"
                fi
            elif [[ "$line" =~ Capture[[:space:]].*\[([0-9]+)%\].*\[(on|off)\] ]]; then
                kv2 "Capture" "${BASH_REMATCH[1]}%  (${BASH_REMATCH[2]})"
            elif [[ "$line" =~ Capabilities:\ (.*) ]] && $VERBOSE; then
                kv2 "Capabilities" "${BASH_REMATCH[1]}"
                vnote "pvolume=per-channel playback volume, pswitch=playback mute,"
                vnote "cvolume/cswitch=same for capture, enum=selectable list of values."
            fi
        done <<< "$RUN_OUT"
        note "'Master' is the overall output, 'PCM' the digital level, 'Speaker'/'Headphone'"
        note "individual outputs. A muted control anywhere in the chain kills the sound."
    fi
}

section_pulse_info() {
    section "Sound server info" "pactl info - what the server core is doing"
    need_tool pactl "PulseAudio client tools (also used to talk to PipeWire)" || return 0
    if run pactl info; then
        if [[ $RUN_RC -ne 0 ]]; then
            write_err "   Could not contact a PulseAudio/PipeWire server."
            printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
            note "Common causes: no session bus, XDG_RUNTIME_DIR unset, server not started,"
            note "or you are in a different user session (e.g. ssh without a seat)."
            return 0
        fi
        pretty && format_pactl_info "$RUN_OUT"
    fi
}

section_pulse_devices() {
    need_tool pactl || return 0
    section "Outputs (sinks)" "pactl list short sinks - everything you can play to"
    if run pactl list short sinks; then
        [[ $RUN_RC -eq 0 ]] && pretty && format_pactl_short "$RUN_OUT" "sinks"
    fi
    section "Inputs (sources)" "pactl list short sources - microphones and monitors"
    if run pactl list short sources; then
        [[ $RUN_RC -eq 0 ]] && pretty && format_pactl_short "$RUN_OUT" "sources"
    fi
    section "Cards and profiles" "pactl list short cards - physical devices and their modes"
    if run pactl list short cards; then
        if [[ $RUN_RC -eq 0 ]] && pretty; then
            printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
            note "A card is the hardware; a profile (stereo/surround/HDMI/headset) decides"
            note "which sinks and sources it currently exposes."
            vnote "Switch with: pactl set-card-profile <card> <profile>"
            vnote "List profiles with: pactl list cards | grep -A20 Profiles"
        fi
    fi
    if $SHOW_ALL; then
        section "Full sink detail" "pactl list sinks - ports, volumes, latency, properties"
        if run pactl list sinks; then
            [[ $RUN_RC -eq 0 ]] && pretty && printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
        fi
    else
        write_dim "   (use -a for the full 'pactl list sinks' detail)"
    fi
}

section_pulse_streams() {
    need_tool pactl || return 0
    section "Playback streams" "pactl list short sink-inputs - apps producing audio"
    if run pactl list short sink-inputs; then
        if [[ $RUN_RC -eq 0 ]] && pretty; then
            if [[ -z "$RUN_OUT" ]]; then
                write_dim "   Nothing is playing right now."
            else
                printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
                note "Columns: index, sink it feeds, client, driver module, sample spec."
                vnote "Move a stream to another output: pactl move-sink-input <index> <sink>"
            fi
        fi
    fi
    section "Capture streams" "pactl list short source-outputs - apps recording"
    if run pactl list short source-outputs; then
        if [[ $RUN_RC -eq 0 ]] && pretty; then
            [[ -z "$RUN_OUT" ]] && write_dim "   Nothing is recording right now." \
                                || printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
        fi
    fi
    if ( have lsof || $DEBUG ) && ( $VERBOSE || $SHOW_ALL ); then
        section "Processes holding /dev/snd" "lsof - who has the raw device open"
        if run lsof /dev/snd/ ; then
            [[ -n "$RUN_OUT" ]] && pretty && printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
            note "A process here bypasses the sound server and may block it exclusively."
        fi
    fi
}

section_pulse_mixer() {
    need_tool pactl || return 0
    section "Sink volumes" "pactl list sinks - volume and mute per output"
    if run pactl list sinks; then
        [[ $RUN_RC -ne 0 ]] && return 0
        pretty || return 0
        local line name
        while IFS= read -r line; do
            line="${line#"${line%%[![:space:]]*}"}"
            case "$line" in
                Name:*)   name="${line#Name: }"; echo; write_ok "   [ ${name} ]" ;;
                Mute:*)
                    local m="${line#Mute: }"
                    if [[ "$m" == "yes" ]]; then
                        kv2 "Muted" "$(echo -e "${RED}YES${RESET}")"
                        note "Unmute with: pactl set-sink-mute ${name:-@DEFAULT_SINK@} 0"
                    else
                        kv2 "Muted" "no"
                    fi ;;
                Volume:*) kv2 "Volume" "${line#Volume: }"
                          vnote "Values above 100% are software amplification and can clip." ;;
                "Base Volume:"*) $VERBOSE && kv2 "Base volume" "${line#Base Volume: }" ;;
                Latency:*) kv2 "Latency" "${line#Latency: }"
                           vnote "'actual' is the measured delay, 'configured' the requested one." ;;
            esac
        done <<< "$RUN_OUT"
        note "Quick set: pactl set-sink-volume @DEFAULT_SINK@ 50%"
    fi
}

section_pipewire_info() {
    section "PipeWire graph" "wpctl status - devices, streams and defaults as a tree"
    if need_tool wpctl "WirePlumber session manager CLI"; then
        if run wpctl status; then
            if [[ $RUN_RC -eq 0 ]] && pretty; then
                printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
                note "'*' marks the default device. Numbers on the left are node IDs you can"
                note "pass to wpctl (e.g. wpctl set-volume 42 0.5, wpctl set-default 42)."
                vnote "Audio > Sinks = outputs, Sources = inputs, Streams = running apps."
                vnote "Filters/Devices sections list virtual nodes and ALSA card objects."
            fi
        fi
    fi

    section "PipeWire core" "pw-cli info 0 - version, quantum and clock rate"
    if need_tool pw-cli "PipeWire CLI tools"; then
        if run pw-cli info 0; then
            if [[ $RUN_RC -eq 0 ]] && pretty; then
                printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
                note "cookie/name identify the daemon instance; the props block holds the"
                note "negotiated clock rate and quantum used by the whole graph."
            fi
        fi
    fi

    section "PipeWire settings" "pw-metadata -n settings - live latency configuration"
    if need_tool pw-metadata "PipeWire CLI tools"; then
        if run pw-metadata -n settings; then
            if [[ $RUN_RC -eq 0 ]] && pretty; then
                local rate="" quantum="" line
                while IFS= read -r line; do
                    [[ "$line" =~ key:\'([^\']+)\'\ value:\'([^\']*)\' ]] || continue
                    local k="${BASH_REMATCH[1]}" v="${BASH_REMATCH[2]}"
                    case "$k" in
                        clock.rate)          rate="$v";    kv "Default clock rate" "${v} Hz" ;;
                        clock.quantum)       quantum="$v"; kv "Default quantum" "${v} frames" ;;
                        clock.force-rate)    [[ "$v" != "0" ]] && kv "Forced rate" "${v} Hz" ;;
                        clock.force-quantum) [[ "$v" != "0" ]] && kv "Forced quantum" "${v} frames" ;;
                        clock.min-quantum)   $VERBOSE && kv "Min quantum" "$v" ;;
                        clock.max-quantum)   $VERBOSE && kv "Max quantum" "$v" ;;
                    esac
                done <<< "$RUN_OUT"
                if [[ -n "$rate" && -n "$quantum" && "$rate" != "0" ]]; then
                    local ms; ms="$(awk -v q="$quantum" -v r="$rate" 'BEGIN{printf "%.2f", (q/r)*1000}')"
                    kv "Graph latency" "${ms} ms  (quantum / rate)"
                    note "Quantum is how many frames PipeWire processes per cycle. Lower means"
                    note "lower latency and higher CPU load; 'force-quantum' pins it."
                    vnote "Change temporarily: pw-metadata -n settings 0 clock.force-quantum 256"
                    vnote "Persist it in ~/.config/pipewire/pipewire.conf.d/*.conf"
                fi
            fi
        fi
    fi

    if $SHOW_ALL; then
        section "All PipeWire nodes" "pw-cli ls Node - every object in the graph"
        if ( have pw-cli || $DEBUG ) && run pw-cli ls Node; then
            [[ $RUN_RC -eq 0 ]] && pretty && printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
        fi
    else
        write_dim "   (use -a to dump every node with 'pw-cli ls Node')"
    fi
    write_dim "   (live per-stream latency/xruns: run 'pw-top' in a terminal)"
}

section_config_files() {
    section "Configuration files" "Which files can override your audio setup"
    local f
    local files=(
        "/etc/asound.conf|ALSA system-wide config: defines the 'default' PCM, dmix, plugins"
        "$HOME/.asoundrc|ALSA per-user config, overrides /etc/asound.conf"
        "/etc/pulse/default.pa|PulseAudio startup script: modules loaded at boot"
        "$HOME/.config/pulse/default.pa|Per-user PulseAudio startup overrides"
        "/etc/pulse/daemon.conf|PulseAudio core: resampler, default rate, fragment sizes"
        "$HOME/.config/pulse/daemon.conf|Per-user PulseAudio core overrides"
        "/usr/share/pipewire/pipewire.conf|PipeWire defaults (do not edit - copy first)"
        "$HOME/.config/pipewire/pipewire.conf|Per-user PipeWire core config"
        "/etc/wireplumber|WirePlumber policy (routing, default device rules)"
        "$HOME/.config/wireplumber|Per-user WirePlumber policy"
        "$HOME/.config/pipewire/pipewire.conf.d|Drop-in fragments - preferred way to tweak"
    )
    for f in "${files[@]}"; do
        local path="${f%%|*}" desc="${f#*|}"
        if [[ -e "$path" ]]; then
            write_ok "   [x] ${path}"
            write_dim "       ${desc}"
        elif $VERBOSE; then
            write_dim "   [ ] ${path}"
            write_dim "       ${desc}"
        fi
    done
    $VERBOSE || write_dim "   (use -v to also list the files that do not exist)"

    if [[ -r /etc/asound.conf || -r "$HOME/.asoundrc" ]]; then
        note "A custom ALSA config is present - it decides what 'default' means, which is"
        note "the most common reason speaker-test works but applications stay silent."
    fi
}

# =============================================================================
#  COMMANDS
# =============================================================================

cmd_info() {
    title "Audio system overview" "backend: ${BACKEND}"
    section_system
    section_services
    case "$BACKEND" in
        alsa)
            section_alsa_kernel
            section_alsa_info
            section_alsa_active_streams
            ;;
        pulse)
            section_pulse_info
            section_pulse_devices
            section_alsa_kernel
            ;;
        pipewire)
            section_pipewire_info
            section_pulse_info
            section_pulse_devices
            section_alsa_kernel
            ;;
    esac
    section_config_files
    print_missing_summary
    echo
    write_dim "Tip: '${SCRIPT_NAME} diagnose' checks for the usual silent-audio causes."
}

cmd_devices() {
    title "Audio devices" "backend: ${BACKEND}"
    case "$BACKEND" in
        alsa)     section_alsa_info ;;
        pulse)    section_pulse_devices ;;
        pipewire) section_pipewire_info; section_pulse_devices ;;
    esac
    if $VERBOSE || $SHOW_ALL || [[ "$BACKEND" != "alsa" ]]; then
        section_alsa_kernel
    fi
    print_missing_summary
}

cmd_mixer() {
    title "Volume and mute state" "backend: ${BACKEND}"
    case "$BACKEND" in
        alsa) section_alsa_mixer ;;
        pulse|pipewire)
            section_pulse_mixer
            if ( have wpctl || $DEBUG ) && [[ "$BACKEND" == "pipewire" ]]; then
                section "Default device volume" "wpctl get-volume"
                run wpctl get-volume @DEFAULT_AUDIO_SINK@ && pretty && \
                    printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
                run wpctl get-volume @DEFAULT_AUDIO_SOURCE@ && pretty && \
                    printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
                note "1.00 = 100%. Set with: wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5"
                note "Toggle mute with: wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            fi
            section_alsa_mixer
            ;;
    esac
    print_missing_summary
}

cmd_streams() {
    title "Active audio streams" "backend: ${BACKEND}"
    case "$BACKEND" in
        alsa) section_alsa_active_streams ;;
        pulse|pipewire)
            section_pulse_streams
            section_alsa_active_streams
            ;;
    esac
    print_missing_summary
}

cmd_config() {
    title "Audio configuration" "backend: ${BACKEND}"
    section_config_files
    case "$BACKEND" in
        pipewire) section_pipewire_info ;;
        pulse)    section_pulse_info ;;
        alsa)     section_alsa_active_streams ;;
    esac
    if [[ -r /etc/asound.conf ]] && ( $VERBOSE || $SHOW_ALL ); then
        section "/etc/asound.conf"
        run_cat /etc/asound.conf && pretty && printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
    fi
    if [[ -r "$HOME/.asoundrc" ]] && ( $VERBOSE || $SHOW_ALL ); then
        section "~/.asoundrc"
        run_cat "$HOME/.asoundrc" && pretty && printf '%s\n' "$RUN_OUT" | sed 's/^/   /'
    fi
    print_missing_summary
}

cmd_modules() {
    title "Kernel audio layer" "drivers, cards and firmware"
    section_alsa_kernel
    section_alsa_active_streams
    section "Kernel messages" "dmesg filtered on sound-related lines"
    if $DEBUG; then
        show_cmd_raw "dmesg | grep -iE 'snd|sof-audio|hda|usb-audio' | tail -n 25"
    elif have dmesg; then
        local out
        out="$(dmesg 2>/dev/null | grep -iE 'snd|sof-audio|hda|usb-audio' | tail -n 25)"
        if [[ -z "$out" ]]; then
            write_dim "   No sound-related kernel messages readable (try with sudo)."
        else
            printf '%s\n' "$out" | sed 's/^/   /'
            note "Lines containing 'firmware', 'error' or 'failed' are worth reading first."
            vnote "Missing firmware on modern Intel laptops usually means the sof-firmware"
            vnote "package is not installed."
        fi
    fi
    print_missing_summary
}

cmd_deps() {
    title "Audio tooling" "what is installed and what each tool is for"
    kv "Distribution"    "${DISTRO_NAME}"
    kv "Package manager" "${PKG_MGR}"

    local entries=(
        "aplay|ALSA playback + device listing (aplay -l)"
        "arecord|ALSA recording + capture device listing"
        "amixer|ALSA mixer control from the shell"
        "alsamixer|Interactive ncurses mixer"
        "speaker-test|Generates test tones straight through ALSA"
        "alsactl|Saves and restores mixer state"
        "pactl|Control a PulseAudio (or pipewire-pulse) server"
        "paplay|Play a file through the sound server"
        "parecord|Record through the sound server"
        "pw-cli|Inspect and control the PipeWire graph"
        "pw-dump|Dump the whole PipeWire state as JSON"
        "pw-play|Play a file directly through PipeWire"
        "pw-record|Record directly through PipeWire"
        "pw-top|Live view of nodes, quantum, xruns"
        "pw-metadata|Read/write live PipeWire settings"
        "wpctl|WirePlumber control: status, volume, defaults"
        "sox|Generate and process audio (the 'play' command)"
        "lsof|Find which process holds /dev/snd open"
    )
    echo
    local e tool desc
    for e in "${entries[@]}"; do
        tool="${e%%|*}"; desc="${e#*|}"
        if have "$tool"; then
            printf "   ${GREEN}%-14s${RESET} ${DARKGRAY}%s${RESET}\n" "[ok] $tool" "$desc"
        else
            printf "   ${RED}%-14s${RESET} ${DARKGRAY}%s${RESET}\n" "[--] $tool" "$desc"
            remember_missing "$(pkg_for "$tool")"
        fi
    done
    print_missing_summary
    if ((${#MISSING_PKGS[@]})); then
        echo
        write_info "Install everything missing in one go:"
        local all="${MISSING_PKGS[*]}"
        bullet "$(install_hint "$all")"
    else
        echo
        write_ok "All known audio tools are installed."
    fi
}

cmd_test() {
    title "Playback test" "backend: ${BACKEND}, type: ${TEST_TYPE}"
    local dev; dev="$(default_device)"
    local type="$TEST_TYPE"

    if [[ "$type" == "auto" ]]; then
        case "$BACKEND" in
            alsa)             type="speaker" ;;
            pulse|pipewire)   if have speaker-test; then type="speaker"; else type="bell"; fi ;;
        esac
    fi

    kv "Backend"    "$BACKEND"
    kv "Device/PCM" "$dev"
    kv "Channels"   "$CHANNELS"
    kv "Sample rate" "${RATE} Hz"
    kv "Test type"  "$type"
    case "$BACKEND" in
        alsa)     note "Going straight to ALSA. If a sound server owns the card exclusively"
                  note "this can fail with 'Device or resource busy'." ;;
        pulse)    note "Routing through the PulseAudio 'pulse' PCM, so the server mixes it." ;;
        pipewire) note "Routing through the PipeWire ALSA plugin ('pipewire' PCM)." ;;
    esac
    echo

    case "$type" in
        speaker|pink|white)
            need_tool speaker-test || return 1
            local tone="sine"
            [[ "$type" == "pink" ]]  && tone="pink"
            [[ "$type" == "white" ]] && tone="white"
            local args=(speaker-test -D "$dev" -c "$CHANNELS" -r "$RATE" -t "$tone" -l "$LOOPS")
            [[ "$tone" == "sine" ]] && args+=(-f "$FREQ")
            write_info "Playing ${tone} through each channel in turn..."
            vnote "speaker-test walks the channels one by one so you can verify that left"
            vnote "and right are not swapped. -l ${LOOPS} means ${LOOPS} pass(es) then exit."
            vnote "-t sine plays a pure tone, -t pink is pink noise (equal energy per octave,"
            vnote "the standard signal for checking speakers), -t white is flat white noise."
            if run_live "${args[@]}"; then
                report_test_result "$RUN_RC" "$dev"
            fi
            ;;
        wav)
            need_tool speaker-test || return 1
            write_info "Playing the built-in spoken channel-ID samples..."
            vnote "-t wav uses the Front_Left/Front_Right voice files so you hear which"
            vnote "speaker is which without guessing."
            if run_live speaker-test -D "$dev" -c "$CHANNELS" -r "$RATE" -t wav -l "$LOOPS"; then
                report_test_result "$RUN_RC" "$dev"
            fi
            ;;
        tone)
            if have play; then
                write_info "Generating a ${FREQ} Hz sine for ${DURATION}s with sox..."
                vnote "sox's 'play' obeys AUDIODRIVER/AUDIODEV, so it uses whatever default"
                vnote "output your system exposes rather than a specific ALSA PCM."
                if run_live play -n -q synth "$DURATION" sine "$FREQ" vol 0.4; then
                    report_test_result "$RUN_RC" "$dev"
                fi
            else
                need_tool play "sox provides the 'play' command" || return 1
            fi
            ;;
        bell)
            local file
            if ! file="$(find_sample_file)"; then
                if $DEBUG; then
                    file="/usr/share/sounds/alsa/Front_Center.wav"
                else
                    write_err "   No sample sound file found on this system."
                    note "Install a sound theme, e.g. $(install_hint "sound-theme-freedesktop")"
                    note "or point at your own file: ${SCRIPT_NAME} test -t bell -D <sink> ..."
                    return 1
                fi
            fi
            kv "Sample file" "$file"
            case "$BACKEND" in
                pipewire)
                    if have pw-play || $DEBUG; then
                        run_live pw-play "$file" && report_test_result "$RUN_RC" "$dev"
                    elif have paplay; then
                        run_live paplay "$file" && report_test_result "$RUN_RC" "$dev"
                    else
                        need_tool pw-play || return 1
                    fi ;;
                pulse)
                    need_tool paplay || return 1
                    local pargs=(paplay)
                    [[ -n "$DEVICE" ]] && pargs+=(--device="$DEVICE")
                    pargs+=("$file")
                    run_live "${pargs[@]}" && report_test_result "$RUN_RC" "$dev" ;;
                alsa)
                    need_tool aplay || return 1
                    run_live aplay -D "$dev" "$file" && report_test_result "$RUN_RC" "$dev" ;;
            esac
            ;;
        *)
            write_err "Unknown test type: ${type}"
            write_dim "Valid: auto, speaker, pink, white, wav, tone, bell"
            return 2 ;;
    esac
}

report_test_result() {
    local rc="$1" dev="$2"
    echo
    if [[ "$rc" -eq 0 ]]; then
        write_ok "Test finished (exit code 0)."
        note "Heard nothing? The command succeeded, so the audio reached the device."
        note "Check volume/mute (${SCRIPT_NAME} mixer) and the output port selection."
    else
        write_err "Test failed with exit code ${rc}."
        case "$rc" in
            1) note "Usually a wrong PCM name or unsupported rate/format." 
               note "Try: ${SCRIPT_NAME} test -D plughw:0,0   (plughw converts for you)" ;;
            2) note "Device busy or permission denied on /dev/snd." ;;
            *) note "Run '${SCRIPT_NAME} diagnose' for a broader check." ;;
        esac
        note "Current device string was: ${dev}"
        note "List valid names with: ${SCRIPT_NAME} devices -b ${BACKEND}"
    fi
}

cmd_record() {
    title "Microphone loopback test" "record ${DURATION}s, then play it back"
    local tmp="${TMPDIR:-/tmp}/audio-helper-rec-$$.wav"
    kv "Backend"     "$BACKEND"
    kv "Duration"    "${DURATION}s"
    kv "Channels"    "$CHANNELS"
    kv "Sample rate" "${RATE} Hz"
    kv "Temp file"   "$tmp"
    note "Speak into the microphone while it records; playback follows immediately."
    echo

    local rec_ok=false
    case "$BACKEND" in
        alsa)
            need_tool arecord || return 1
            local rdev="${DEVICE:-default}"
            if run_live arecord -D "$rdev" -f S16_LE -c "$CHANNELS" -r "$RATE" -d "$DURATION" "$tmp"; then
                [[ $RUN_RC -eq 0 ]] && rec_ok=true
            fi ;;
        pulse)
            need_tool parecord || return 1
            if run_live parecord --channels="$CHANNELS" --rate="$RATE" --file-format=wav "$tmp" --latency-msec=50; then
                [[ $RUN_RC -eq 0 ]] && rec_ok=true
            fi
            write_dim "   (parecord runs until interrupted - press Ctrl+C after speaking)" ;;
        pipewire)
            if have pw-record; then
                write_dim "   (press Ctrl+C after ${DURATION}s to stop)"
                if run_live pw-record "$tmp"; then rec_ok=true; fi
            else
                need_tool arecord || return 1
                if run_live arecord -D pipewire -f S16_LE -c "$CHANNELS" -r "$RATE" -d "$DURATION" "$tmp"; then
                    [[ $RUN_RC -eq 0 ]] && rec_ok=true
                fi
            fi ;;
    esac

    if $DEBUG; then
        echo
        write_info "Then play it back with:"
        case "$BACKEND" in
            alsa)     show_cmd aplay -D "$(default_device)" "$tmp" ;;
            pulse)    show_cmd paplay "$tmp" ;;
            pipewire) show_cmd pw-play "$tmp" ;;
        esac
        return 0
    fi

    if ! $rec_ok || [[ ! -s "$tmp" ]]; then
        echo
        write_err "Recording failed or produced an empty file."
        note "Check that the source is not muted: ${SCRIPT_NAME} mixer"
        note "and that a capture device exists: ${SCRIPT_NAME} devices"
        rm -f "$tmp"
        return 1
    fi

    echo
    write_ok "Recorded $(du -h "$tmp" 2>/dev/null | cut -f1) - playing it back now."
    case "$BACKEND" in
        alsa)     run_live aplay -D "$(default_device)" "$tmp" ;;
        pulse)    run_live paplay "$tmp" ;;
        pipewire) if have pw-play; then run_live pw-play "$tmp"; else run_live paplay "$tmp"; fi ;;
    esac
    rm -f "$tmp"
    echo
    write_dim "Temp file removed."
}

cmd_diagnose() {
    title "Audio diagnostics" "checking the usual reasons for silence"
    local problems=0 warnings=0

    section "1. Kernel sees a sound card"
    if $DEBUG; then
        show_cmd cat /proc/asound/cards
    elif [[ -r /proc/asound/cards ]] && grep -q '^ *[0-9]' /proc/asound/cards 2>/dev/null; then
        write_ok "   OK - at least one card is registered."
        sed 's/^/       /' /proc/asound/cards
    else
        write_err "   FAIL - no sound card registered with the kernel."
        note "No driver is bound. Check 'lspci -k | grep -A3 -i audio' and dmesg for"
        note "firmware errors. On modern Intel laptops install the SOF firmware package."
        ((problems++))
    fi

    section "2. Required tools are present"
    local t missing_here=0
    for t in aplay speaker-test amixer; do
        have "$t" || { write_warn "   missing: $t"; remember_missing "$(pkg_for "$t")"; ((missing_here++)); }
    done
    if [[ "$BACKEND" != "alsa" ]]; then
        have pactl || { write_warn "   missing: pactl"; remember_missing "$(pkg_for pactl)"; ((missing_here++)); }
    fi
    if ((missing_here == 0)); then
        write_ok "   OK - the essential command line tools are installed."
    else
        ((warnings++))
    fi

    section "3. A sound server is reachable"
    if [[ "$BACKEND" == "alsa" ]]; then
        write_warn "   No sound server detected - applications will fight over the card."
        note "Most desktops need PipeWire (or PulseAudio) for per-app volume and mixing."
        note "Enable it with: systemctl --user enable --now pipewire pipewire-pulse wireplumber"
        ((warnings++))
    elif $DEBUG; then
        show_cmd pactl info
    elif have pactl && pactl info >/dev/null 2>&1; then
        write_ok "   OK - ${BACKEND} is running and answering."
    else
        write_err "   FAIL - no server answered on the pulse socket."
        note "${BACKEND_HOW}"
        ((problems++))
    fi

    section "4. Default output is real hardware"
    if $DEBUG; then
        show_cmd pactl info
    elif have pactl; then
        local sink
        sink="$(pactl info 2>/dev/null | sed -n 's/^Default Sink: //p')"
        if [[ -z "$sink" ]]; then
            write_warn "   Could not read the default sink."
            ((warnings++))
        elif [[ "$sink" == *auto_null* || "$sink" == *dummy* ]]; then
            write_err "   FAIL - default sink is '${sink}' (a dummy device)."
            note "The server started before any card was available, or the card profile is"
            note "set to 'off'. Try: pactl set-card-profile <card> output:analog-stereo"
            note "or restart the audio stack: systemctl --user restart wireplumber pipewire"
            ((problems++))
        else
            write_ok "   OK - default sink: ${sink}"
        fi
    else
        write_dim "   skipped (pactl not installed)"
    fi

    section "5. Nothing is muted"
    if $DEBUG; then
        show_cmd amixer
        show_cmd pactl get-sink-mute @DEFAULT_SINK@
    else
        local muted=0
        if have amixer; then
            while IFS= read -r line; do
                [[ "$line" =~ ^Simple\ mixer\ control\ \'([^\']+)\' ]] && ctl="${BASH_REMATCH[1]}"
                if [[ "$line" =~ Playback.*\[off\] ]]; then
                    write_err "   MUTED: ALSA control '${ctl:-?}'"
                    note "Unmute: amixer set '${ctl:-Master}' unmute"
                    ((muted++))
                fi
            done <<< "$(amixer 2>/dev/null)"
        fi
        if have pactl; then
            local m; m="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)"
            if [[ "$m" == *yes* ]]; then
                write_err "   MUTED: the default sink"
                note "Unmute: pactl set-sink-mute @DEFAULT_SINK@ 0"
                ((muted++))
            fi
        fi
        if ((muted == 0)); then
            write_ok "   OK - no muted playback control found."
        else
            ((problems++))
        fi
    fi

    section "6. Permissions on the audio devices"
    if [[ -d /dev/snd ]]; then
        if id -nG 2>/dev/null | tr ' ' '\n' | grep -qx audio; then
            write_ok "   OK - your user is in the 'audio' group."
        else
            write_warn "   Your user is not in the 'audio' group."
            note "On a normal desktop this is fine (logind grants access via the seat)."
            note "For bare ALSA or headless use: sudo usermod -aG audio \$USER, then re-login."
            ((warnings++))
        fi
    else
        write_err "   FAIL - /dev/snd does not exist."
        note "No ALSA device nodes at all: no driver loaded, or you are in a container"
        note "without /dev/snd passed through."
        ((problems++))
    fi

    section "7. Conflicting servers"
    if $DEBUG; then
        show_cmd_raw "pgrep -x pulseaudio; pgrep -x pipewire"
    elif have pgrep; then
        if pgrep -x pulseaudio >/dev/null 2>&1 && pgrep -x pipewire >/dev/null 2>&1; then
            write_err "   Both pulseaudio and pipewire are running."
            note "They will fight over the ALSA card. Pick one:"
            note "  systemctl --user disable --now pulseaudio.service pulseaudio.socket"
            ((problems++))
        else
            write_ok "   OK - only one sound server is running."
        fi
    fi

    section "8. Custom ALSA config"
    if [[ -r /etc/asound.conf || -r "$HOME/.asoundrc" ]]; then
        write_warn "   A custom ALSA config exists:"
        [[ -r /etc/asound.conf ]] && write_dim "       /etc/asound.conf"
        [[ -r "$HOME/.asoundrc" ]] && write_dim "       ${HOME}/.asoundrc"
        note "These redefine 'default'. A stale one is a classic cause of 'speaker-test"
        note "works but nothing else does'. Rename it to test: mv ~/.asoundrc ~/.asoundrc.bak"
        ((warnings++))
    else
        write_ok "   OK - no custom ALSA config overriding the defaults."
    fi

    echo
    hr
    if ((problems == 0 && warnings == 0)); then
        write_ok "No problems found. If audio is still silent, run: ${SCRIPT_NAME} test -v"
    else
        ((problems > 0)) && write_err "${problems} problem(s) found."
        ((warnings > 0)) && write_warn "${warnings} warning(s) found."
        write_dim "Next step: ${SCRIPT_NAME} test -b ${BACKEND} -v"
    fi
    print_missing_summary
    ((problems > 0)) && return 1
    return 0
}

# =============================================================================
#  ARGUMENT PARSING
# =============================================================================

# Pre-scan for color flags so --help is colored correctly too
_prev=""
for _a in "$@"; do
    case "${_a,,}" in
        --no-color) COLOR_MODE="never" ;;
        auto|always|never) [[ "${_prev,,}" == "--color" ]] && COLOR_MODE="${_a,,}" ;;
    esac
    _prev="$_a"
done
unset _a _prev
setup_colors

# Early, case-insensitive help check anywhere in the arguments
for _a in "$@"; do
    case "${_a,,}" in
        help|--help|-h|-\?|/\?|--usage)
            detect_distro
            usage
            exit 0 ;;
    esac
done
unset _a

if [[ $# -eq 0 ]]; then
    detect_distro
    usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--backend)   BACKEND="${2:?--backend needs a value}"; shift 2 ;;
        -D|--device)    DEVICE="${2:?--device needs a value}";  shift 2 ;;
        -c|--channels)  CHANNELS="${2:?--channels needs a value}"; shift 2 ;;
        -r|--rate)      RATE="${2:?--rate needs a value}";      shift 2 ;;
        -t|--type)      TEST_TYPE="${2:?--type needs a value}"; shift 2 ;;
        -f|--freq)      FREQ="${2:?--freq needs a value}";      shift 2 ;;
        -d|--duration)  DURATION="${2:?--duration needs a value}"; shift 2 ;;
        -l|--loops)     LOOPS="${2:?--loops needs a value}";    shift 2 ;;
        -v|--verbose)   VERBOSE=true; shift ;;
        -a|--all)       SHOW_ALL=true; shift ;;
        --raw)          RAW_MODE="only"; shift ;;
        --raw-also)     RAW_MODE="both"; shift ;;
        --debug|--dry-run) DEBUG=true; shift ;;
        --color)        COLOR_MODE="${2:?--color needs a value}"; shift 2 ;;
        --no-color)     COLOR_MODE="never"; shift ;;
        --version)      echo "${SCRIPT_NAME} ${VERSION}"; exit 0 ;;
        -*)
            write_err "Unknown option: $1"
            write_dim "Run '${SCRIPT_NAME} --help' for usage."
            exit 2 ;;
        *)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="${1,,}"
            else
                write_err "Unexpected argument: $1"
                exit 2
            fi
            shift ;;
    esac
done

setup_colors

case "${BACKEND,,}" in
    auto|alsa|pulse|pulseaudio|pipewire|pw) : ;;
    *)  write_err "Invalid backend: ${BACKEND}"
        write_dim "Valid: auto, alsa, pulse, pipewire"
        exit 2 ;;
esac
BACKEND="${BACKEND,,}"
[[ "$BACKEND" == "pulseaudio" ]] && BACKEND="pulse"
[[ "$BACKEND" == "pw" ]] && BACKEND="pipewire"

case "${COLOR_MODE}" in
    auto|always|never) : ;;
    *) write_err "Invalid --color value: ${COLOR_MODE} (auto|always|never)"; exit 2 ;;
esac

for _n in CHANNELS RATE FREQ DURATION LOOPS; do
    if [[ ! "${!_n}" =~ ^[0-9]+$ ]]; then
        write_err "--${_n,,} must be a positive integer (got '${!_n}')"
        exit 2
    fi
done
unset _n

# =============================================================================
#  MAIN
# =============================================================================
detect_distro
REQUESTED_BACKEND="$BACKEND"
resolve_backend

if $DEBUG; then
    echo
    write_info_alt "DEBUG MODE - commands are printed, not executed."
    write_dim "Copy any '\$ ...' line into your terminal to run it yourself."
    write_dim "(Backend detection still probes the system; it is read-only.)"
fi

RC=0
case "$COMMAND" in
    info)                cmd_info ;;
    devices|list|ls)     cmd_devices ;;
    test|play)           cmd_test ;;
    record|rec|mic)      cmd_record ;;
    mixer|volume|vol)    cmd_mixer ;;
    streams|apps)        cmd_streams ;;
    config|conf)         cmd_config ;;
    modules|kernel)      cmd_modules ;;
    diagnose|doctor|check) cmd_diagnose ;;
    deps|check-deps|tools) cmd_deps ;;
    "")                  usage ;;
    *)
        write_err "Unknown command: ${COMMAND}"
        write_dim "Run '${SCRIPT_NAME} --help' to see the available commands."
        exit 2 ;;
esac
RC=$?

echo
exit "$RC"
