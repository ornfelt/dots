#!/usr/bin/env bash
# benilla.sh - starts benilla (the Rust WoW 1.12.1 client) from one of its checkouts under
# Code2/Wow/tools - plain (main), the gfx dll branch or trimmed-bevy, told apart by what is checked
# out - and one of its cargo profiles; a profile without the client is built with cargo first.
#
# Usage examples (nothing runs without `run` as the first arg, after an optional checkout; the
# args after it in any order, case insensitive; `.benilla help` lists them all):
# cd into a benilla checkout (a menu when there are several, Enter = the last one used) and print
# how to run it, through this script and by hand (runs nothing):
# .benilla
#
# a checkout by its dir name (with or without benilla-), its branch or its kind (plain / gfxdll /
# trimmed), as the first arg or dir= (a checkout alone prints how to run it; only a bare
# .benilla, which the alias sources, cds):
# .benilla benilla-gfx
# .benilla trimmed run vk glfw
# .benilla run dir=benilla-gfx gl4
#
# Quake 3 movement (any checkout, --features q3_movement), and a gfx dll checkout without gfx:
# .benilla run q3
# .benilla gfxdll run nogfx q3
#
# the release build (target/release) on the platform's window (win32 / x11) and the gfx
# library's default device:
# .benilla run
#
# pick the gfx device and / or window:
# .benilla run vk sdl
# .benilla run gl3 glfw
#
# the play profile (release + incremental), rebuilt first, with the debug panel open:
# .benilla run play build panel
#
# log in as the checkout's .probe-identity, on another server and realm:
# .benilla run probe host=192.168.1.10 realm=Elysium
#
# a server-less capture on lavapipe, and the list of capture scenarios:
# .benilla run capture=water-noon vk soft
# .benilla run capture=list
#
# the engine viewer over Goldshire:
# .benilla run at=-9460,62
#
# windowed for this run, at the client's default 1600x900 or a size of your own:
# .benilla run win
# .benilla run size=1280x720
#
# any other env var (an upper-case name with an underscore) as it is:
# .benilla run WOW_MSAA=4 WOW_FARCLIP=800
#
# print the bash line for this run instead of running it:
# .benilla run vk debug print

write_label() { printf '\033[90m%s\033[0m\n' "$1"; } # Dark gray
write_alt()   { printf '\033[35m%s\033[0m\n' "$1"; } # Magenta
write_extra() { printf '\033[34m%s\033[0m\n' "$1"; } # Blue
write_warn()  { printf '\033[33m%s\033[0m\n' "$1"; } # Dark yellow
write_ok()    { printf '\033[32m%s\033[0m\n' "$1"; } # Green
write_err()   { printf '\033[31m%s\033[0m\n' "$1"; } # Red

if [[ -z "${code_root_dir:-}" ]]; then
    code_root_dir="$HOME"
    write_label "code_root_dir is not set - using $code_root_dir"
fi

# The first arg of a bash run of this script that prints the checkout's path (see below)
CHECKOUT_DIR_COMMAND="--checkout-dir"

# A bare call cds into a checkout and prints how to run it (show_usage), running nothing. The cd
# only reaches the calling shell when the script is sourced (the .zshrc alias sources it for a
# bare call), so a sourced script asks a bash run of itself for the checkout (the menu, when
# there are several), cds there, prints through another bash run and returns here, before the
# bash-only code below
if (( $# == 0 )) && (return 0 2>/dev/null); then
    _benilla_bare() {
        local script="$1" dir
        dir="$(bash "$script" "$CHECKOUT_DIR_COMMAND")" || return 1
        cd -- "$dir" || return 1
        bash "$script" "$dir"
    }
    _benilla_bare "${BASH_SOURCE[0]:-$0}" || { unset -f _benilla_bare; return 1; }
    unset -f _benilla_bare
    return 0
fi

# The benilla checkouts: every CHECKOUT_PATTERN dir under TOOLS_ROOT holding the client crate
# (CLIENT_MANIFEST; other benilla-named projects are skipped). The kind comes from what is checked
# out, not from the dir or branch name: no GFX_CRATE_DIR is plain benilla (main), GFX_CRATE_DIR
# with a gfx feature on the client is the gfx dll branch (gfx opt-in, --features gfx), and
# GFX_CRATE_DIR without one is trimmed-bevy (gfx always). The checkout of a run is dir= (or a
# checkout as the first arg), else $BENILLA_DIR, else the only one, else picked from a menu
# (Enter = the last one used, kept in LAST_DIR_FILE).
TOOLS_ROOT="$code_root_dir/Code2/Wow/tools"
CHECKOUT_PATTERN="benilla*"
CHECKOUT_PREFIX="benilla-"
CLIENT_MANIFEST="crates/benilla/Cargo.toml"
GFX_CRATE_DIR="crates/benilla-gfx"
GFX_FEATURE="gfx"
GFX_FEATURE_PATTERN="^[[:space:]]*$GFX_FEATURE[[:space:]]*="
Q3_FEATURE="q3_movement"
Q3_TOKENS=(q3 "$Q3_FEATURE")
KIND_PLAIN="plain"
KIND_GFX_DLL="gfxdll"
KIND_TRIMMED="trimmed"
KIND_NAMES=("$KIND_PLAIN" "$KIND_GFX_DLL" "$KIND_TRIMMED")
declare -A KIND_INFO=([$KIND_PLAIN]="no gfx" [$KIND_GFX_DLL]="gfx opt-in (--features $GFX_FEATURE)" [$KIND_TRIMMED]="gfx always")
# What a selector is matched against, in order (the first that matches any checkout wins)
SELECTOR_ARRAYS=(checkout_names checkout_shorts checkout_branches checkout_kinds)
DETACHED_PREFIX="detached@"
UNKNOWN_BRANCH="?"
DIR_ENV_VAR="BENILLA_DIR"
LAST_DIR_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/benilla/last-dir"
# The cargo features a client was built with, in a file beside it (other features rebuild it)
FEATURES_STAMP_EXT=".features"
FEATURE_SEPARATOR=","
NO_FEATURES="none"
REPO_ROOT=""
BUILD_TIME_FORMAT="%Y-%m-%d %H:%M:%S"

# The cargo profiles (RUNNING.md), picked by name. The player build has no `dev` feature, so it
# gets its own target dir instead of replacing target/release's client. The names shared with
# cenilla.sh mean the same there: release / rel the default optimized build, debug, player, and
# ship the fastest one.
DEFAULT_PROFILE="release"
PROFILE_NAMES=(release debug play ship player)
declare -A PROFILE_DIRS=([release]=target/release [debug]=target/debug [play]=target/play [ship]=target/ship [player]=target/player/release)
declare -A PROFILE_ALIASES=([rel]=release [dev]=debug [lto]=ship)
declare -A PROFILE_INFO=(
    [release]="optimized: the measured build (also: rel)"
    [debug]="dev profile: the frozen reference cenilla is compared against (also: dev)"
    [play]="release + incremental compilation: the edit-and-run loop"
    [ship]="fat LTO, one codegen unit: the shipped binary (also: lto)"
    [player]="release without the dev feature: no dev tools"
)
declare -A PROFILE_BUILD_ARGS=(
    [release]="--release"
    [debug]=""
    [play]="--profile play"
    [ship]="--profile ship"
    [player]="--release --no-default-features --target-dir target/player"
)
BUILD_COMMAND="cargo"
CLIENT_EXE_NAME="benilla"
WORLDVIEW_EXE_NAME="benilla-worldview"

# The gfx library (crates/benilla-gfx/build.rs): $GFX_DIR, else gfx_benilla when it exists, else
# gfx; GFX_CONFIGURATION, else Release when built, else Debug. The build copies it beside the
# client (a cargo build after the library changed copies it again).
GFX_DLL_ROOT="$code_root_dir/Code2/General/gfx/gfx_dll"
GFX_DIR_NAMES=(gfx_benilla gfx)
GFX_CONFIGURATIONS=(Release Debug)
GFX_LIB_NAME="libgfx.so"

# The install's Data dir, always passed as WOW_DATA: data= (or a WOW_DATA= arg), else $WOW_DATA,
# else $wow_classic_dir/Data; the run stops when it does not exist (an empty WOW_DATA is "no
# install", as the client reads it)
WOW_DATA_VAR="WOW_DATA"
WOW_DATA_SUBDIR="Data"
# A scripted login only as this account (WOW_USER=, WOW_PASS=, WOW_CHAR=, one per line)
PROBE_IDENTITY_NAME=".probe-identity"
PROBE_FIELDS=(WOW_USER WOW_PASS WOW_CHAR)
SECRET_VARS=(WOW_PASS)
SECRET_MASK="***"
# A capture writes into the repo; target/ is gitignored there (captures hold Blizzard imagery)
CAPTURE_OUT_SUBDIR="target/visual"
CAPTURE_LIST="list"
SOFT_ENV=(LIBGL_ALWAYS_SOFTWARE=1 VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json)
VALIDATE_ENV=(VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation)
# Exit code of a process the loader could not start (e.g. a missing shared library)
EXIT_LOADER_FAILED=127

# Launch options (show_help)
ALIAS_NAME=".benilla"
RUN_COMMAND="run"
HELP_TOKENS=(help h)
PRINT_TOKENS=(print onlyprint showcmd)
GFX_DEVICES=(gl4 gl3 gles3 vk d3d11 d3d12)
# A d3d device opens only in a win32 window; with any other the window is never created
D3D_DEVICES=(d3d11 d3d12)
D3D_WINDOW="win32"
declare -A GFX_DEVICE_ALIASES=([vulkan]=vk [dx11]=d3d11 [dx12]=d3d12)
GFX_WINDOWS=(x11 sdl glfw win32)
# The window when none is named as an arg (a window option or a WOW_GFX_WINDOW= arg), even over
# a WOW_GFX_WINDOW left in the environment: the platform's own, win32 on
# Windows (Git Bash / MSYS / Cygwin) and x11 on Linux; elsewhere the library's first.
case "${OSTYPE:-}" in
    msys* | cygwin* | win32*) DEFAULT_GFX_WINDOW="win32" ;;
    linux*) DEFAULT_GFX_WINDOW="x11" ;;
    *) DEFAULT_GFX_WINDOW="" ;;
esac
DEFAULT_GFX_WINDOW_INFO="$DEFAULT_GFX_WINDOW"
if [[ -z "$DEFAULT_GFX_WINDOW_INFO" ]]; then DEFAULT_GFX_WINDOW_INFO="the library's first"; fi
OPTION_VALUE_SEPARATOR="="
ENV_ARG_PATTERN='^[A-Z][A-Z0-9]*_[A-Z0-9_]*='
# win / size=: WOW_WIN=<W>x<H> runs the client windowed at that size for this run only (never
# saved; the in-game Windowed Mode, gxWindow 1, is what persists); win alone takes the client's
# default windowed size (DEFAULT_WINDOWED, gxResolution's default)
WINDOWED_DEFAULT_SIZE="1600x900"
WINDOW_SIZE_PATTERN='^[0-9]+x[0-9]+$'

join_by() {
    # join_by <separator> <items...>
    local separator="$1" first=true item
    shift
    for item in "$@"; do
        if $first; then first=false; else printf '%s' "$separator"; fi
        printf '%s' "$item"
    done
}

in_list() {
    # in_list <needle> <items...> - true when needle is one of the items
    local needle="$1" item
    shift
    for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
    return 1
}

show_help() {
    local name kind i
    write_alt "benilla - start benilla from a checkout under $TOOLS_ROOT and a cargo profile (built when missing)"
    cat <<EOF

Usage: $ALIAS_NAME [<checkout>] $RUN_COMMAND [options] [VAR_NAME=value...]
Nothing runs without $RUN_COMMAND as the first arg (after an optional checkout); a bare $ALIAS_NAME cds into a checkout and prints how to run it.
Options are case insensitive, in any order, with or without leading dashes.

Checkout (a $CHECKOUT_PATTERN dir holding $CLIENT_MANIFEST; its kind comes from what is checked out, not its name):
  <checkout> first, or dir=<checkout>   a path, the dir name (with or without $CHECKOUT_PREFIX), the branch or the kind
  none named             \$$DIR_ENV_VAR, else the only checkout, else a menu (Enter = the last one used)
EOF
    for kind in "${KIND_NAMES[@]}"; do
        printf '  %-22s %s\n' "$kind" "${KIND_INFO[$kind]}"
    done
    echo "Found:"
    list_checkouts "${!checkout_paths[@]}"
    cat <<EOF

Features (a client built with other features is built again):
  q3                     Quake 3 movement for a local server (--features $Q3_FEATURE; also: $Q3_FEATURE)
  nogfx                  a $KIND_GFX_DLL checkout without gfx (no --features $GFX_FEATURE)

Profile (default $DEFAULT_PROFILE):
EOF
    for name in "${PROFILE_NAMES[@]}"; do
        printf '  %-8s %-22s %s\n' "$name" "${PROFILE_DIRS[$name]}/" "${PROFILE_INFO[$name]}"
    done
    cat <<EOF
  build                  cargo build first (copies a newer gfx library beside the client too)

gfx backends ($KIND_GFX_DLL / $KIND_TRIMMED checkouts; WOW_GFX_DEVICE / WOW_GFX_WINDOW; the device unset is the library's first, the
window $DEFAULT_GFX_WINDOW_INFO unless named as an arg, even over a WOW_GFX_WINDOW in the environment):
  $(join_by ' | ' "${GFX_DEVICES[@]}")   (vulkan = vk, dx11 / dx12 = d3d11 / d3d12)
  $(join_by ' | ' "${GFX_WINDOWS[@]}")
  d3d11 / d3d12 / win32 are Windows only; a name the library lacks stops the boot, listing its names.

Window (this run only; the in-game Windowed Mode / gxWindow 1 is what is saved):
  win                    windowed at $WINDOWED_DEFAULT_SIZE (WOW_WIN; also: windowed)
  size=<W>x<H>           windowed at that size (WOW_WIN=<W>x<H>)

Dev tools:
  panel                  the debug panel open at boot (WOW_PANEL=1)
  hud                    the perf HUD at boot (WOW_PERF_HUD=1)
  worldview              the engine viewer ($WORLDVIEW_EXE_NAME) instead of the client
  at=<x>,<y>[,<z>]       the engine viewer at raw WoW coordinates (WOW_WORLDVIEW_AT)

Server / login:
  host=<host[:port]>     the server (WOW_HOST, default localhost:3724)
  realm=<name>           the realm (WOW_REALM)
  char=<name>            the character (WOW_CHAR)
  probe                  log in as the checkout's $PROBE_IDENTITY_NAME (WOW_USER / WOW_PASS / WOW_CHAR)
  nosound                WOW_NOSOUND=1
  unattended             WOW_UNATTENDED=1 (reconnect, exit non-zero on a failed login)

Testing:
  capture=<scenario>     a server-less capture (WOW_CAPTURE); capture=$CAPTURE_LIST lists the scenarios
  out=<png>              where the capture goes (default $CAPTURE_OUT_SUBDIR/<scenario>.png)
  fps=<frames>           the live frame-time probe: samples that many frames, reports, exits
  exit=<seconds>         exit after that many seconds (WOW_PROBE_EXIT_AT)
  soft                   off the GPU: llvmpipe for GL, lavapipe for vk
  validate               the Vulkan validation layer

Other:
  data=<dir>             the WoW install's Data dir (WOW_DATA; default \$wow_classic_dir/Data, or \$WOW_DATA when set)
  VAR_NAME=value         any env var with an upper-case name holding an underscore, as it is
  $(join_by ' | ' "${PRINT_TOKENS[@]}")  print the bash line for this run instead of running it
  $(join_by ' | ' "${HELP_TOKENS[@]}") (also -help, --help)  this help

A gfx run needs the gfx library built first: $GFX_DLL_ROOT/${GFX_DIR_NAMES[0]}/bin/<Release|Debug>_x64/$GFX_LIB_NAME.

Examples:
  $ALIAS_NAME $RUN_COMMAND vk sdl panel
  $ALIAS_NAME $RUN_COMMAND play build probe
  $ALIAS_NAME $RUN_COMMAND capture=felwood-night gl4 soft
  $ALIAS_NAME $RUN_COMMAND worldview at=-9460,62 vk
  $ALIAS_NAME $KIND_TRIMMED $RUN_COMMAND q3 vk glfw
  $ALIAS_NAME $RUN_COMMAND dir=benilla-gfx nogfx

EOF
    for i in "${!checkout_paths[@]}"; do show_manual_run "$i"; done
}

show_usage() {
    # A bare call: how to run benilla from the checkout, through this script and by hand
    local name_arg=""
    (( ${#checkout_paths[@]} > 1 )) && name_arg="${checkout_names[$checkout]} "
    write_alt "benilla - $REPO_ROOT (${checkout_branches[$checkout]}, ${checkout_kinds[$checkout]}: ${KIND_INFO[${checkout_kinds[$checkout]}]})"
    write_label "Run it through this script (the options after $RUN_COMMAND; '$ALIAS_NAME help' lists them):"
    write_extra "$ALIAS_NAME $name_arg$RUN_COMMAND"
    show_manual_run "$checkout"
}

show_manual_run() {
    # show_manual_run <checkout index> - prints how to start the checkout's default-profile client
    # by hand, without this script
    local features=() feature_arg="" cargo_run
    kind_features "${checkout_kinds[$1]}"
    features=("${kind_feature_list[@]}")
    (( ${#features[@]} > 0 )) && feature_arg=" --features $(join_by "$FEATURE_SEPARATOR" "${features[@]}")"
    cargo_run="$BUILD_COMMAND run ${PROFILE_BUILD_ARGS[$DEFAULT_PROFILE]} -p $CLIENT_EXE_NAME"
    write_label "Or run it manually (from ${checkout_paths[$1]}, ${checkout_kinds[$1]}):"
    write_extra "export $WOW_DATA_VAR=\"\$wow_classic_dir/$WOW_DATA_SUBDIR\" && $cargo_run$feature_arg"
    write_label "  with Quake 3 movement: $cargo_run --features $(join_by "$FEATURE_SEPARATOR" "${features[@]}" "$Q3_FEATURE")"
}

kind_features() {
    # kind_features <kind> - sets kind_feature_list: the cargo features a gfx run of a checkout of
    # that kind builds with
    kind_feature_list=()
    if [[ "$1" == "$KIND_GFX_DLL" ]]; then kind_feature_list=("$GFX_FEATURE"); fi
    return 0
}

checkout_kind() {
    # checkout_kind <dir> - prints the kind from what is checked out (see TOOLS_ROOT above)
    if [[ ! -d "$1/$GFX_CRATE_DIR" ]]; then echo "$KIND_PLAIN"
    elif grep -qE "$GFX_FEATURE_PATTERN" -- "$1/$CLIENT_MANIFEST"; then echo "$KIND_GFX_DLL"
    else echo "$KIND_TRIMMED"; fi
}

checkout_branch() {
    # checkout_branch <dir> - prints the checked-out branch, detached@<commit> without one
    local branch
    branch="$(git -C "$1" branch --show-current 2>/dev/null)"
    if [[ -z "$branch" ]]; then
        branch="$(git -C "$1" rev-parse --short HEAD 2>/dev/null)"
        [[ -n "$branch" ]] && branch="$DETACHED_PREFIX$branch"
    fi
    echo "${branch:-$UNKNOWN_BRANCH}"
}

add_checkout() {
    # add_checkout <dir> - appends the checkout to the checkout_* arrays
    local path name
    path="$(cd -- "$1" && pwd)"
    name="$(basename -- "$path")"
    checkout_paths+=("$path")
    checkout_names+=("$name")
    checkout_shorts+=("${name#"$CHECKOUT_PREFIX"}")
    checkout_branches+=("$(checkout_branch "$path")")
    checkout_kinds+=("$(checkout_kind "$path")")
}

find_checkouts() {
    # Fills the checkout_* arrays with every checkout under TOOLS_ROOT, by name
    local dir
    checkout_paths=(); checkout_names=(); checkout_shorts=(); checkout_branches=(); checkout_kinds=()
    for dir in "$TOOLS_ROOT"/$CHECKOUT_PATTERN; do
        [[ -f "$dir/$CLIENT_MANIFEST" ]] && add_checkout "$dir"
    done
    return 0
}

find_checkout_matches() {
    # find_checkout_matches <selector> - sets matches (checkout indices): a path to a checkout,
    # else the SELECTOR_ARRAYS in order (case insensitive), the first that matches any
    local token="$1" lower i path array
    matches=()
    [[ -z "$token" ]] && return 0
    if [[ -d "$token" && -f "$token/$CLIENT_MANIFEST" ]]; then
        path="$(cd -- "$token" && pwd)"
        for i in "${!checkout_paths[@]}"; do
            if [[ "${checkout_paths[$i]}" == "$path" ]]; then matches=("$i"); return 0; fi
        done
        add_checkout "$path"
        matches=($(( ${#checkout_paths[@]} - 1 )))
        return 0
    fi
    lower="${token,,}"
    for array in "${SELECTOR_ARRAYS[@]}"; do
        local -n values="$array"
        for i in "${!values[@]}"; do
            [[ "${values[$i],,}" == "$lower" ]] && matches+=("$i")
        done
        unset -n values
        (( ${#matches[@]} > 0 )) && return 0
    done
    return 0
}

format_checkout() {
    # format_checkout <index> - one line naming a checkout
    printf '%-22s %-18s %-8s %s' "${checkout_names[$1]}" "${checkout_branches[$1]}" "${checkout_kinds[$1]}" "${KIND_INFO[${checkout_kinds[$1]}]}"
}

list_checkouts() {
    # list_checkouts <indices...> - the checkouts, one per line
    local i
    if (( $# == 0 )); then write_label "  none under $TOOLS_ROOT"; return; fi
    for i in "$@"; do write_label "  $(format_checkout "$i")"; done
}

pick_checkout() {
    # Several checkouts and none named: sets picked (an index) from a numbered menu, Enter = the
    # last one used (a number or a selector picks one). The menu goes to stderr and the answer
    # comes from /dev/tty, so a sourced bare call can read the picked path from stdout
    local last="" default="" i mark answer prompt count=${#checkout_paths[@]}
    [[ -f "$LAST_DIR_FILE" ]] && last="$(head -n 1 -- "$LAST_DIR_FILE" 2>/dev/null)"
    write_alt "benilla checkouts under $TOOLS_ROOT:" >&2
    for i in "${!checkout_paths[@]}"; do
        mark=" "
        if [[ -n "$last" && "${checkout_paths[$i]}" == "$last" ]]; then default="$i"; mark="*"; fi
        printf '%s %2d) %s\n' "$mark" "$((i + 1))" "$(format_checkout "$i")" >&2
    done
    if [[ ! -t 0 ]] || ! { : </dev/tty; } 2>/dev/null; then
        write_err "Several checkouts and no terminal to pick one - name one first or as dir=<checkout> (or set $DIR_ENV_VAR)." >&2
        exit 1
    fi

    prompt="Pick 1-$count"
    [[ -n "$default" ]] && prompt+=" (Enter = ${checkout_names[$default]})"
    read -r -p "$prompt: " answer </dev/tty || answer=""
    answer="${answer//[[:space:]]/}"
    if [[ -z "$answer" && -n "$default" ]]; then picked="$default"; return 0; fi
    if [[ "$answer" =~ ^[0-9]+$ ]] && (( 10#$answer >= 1 && 10#$answer <= count )); then picked=$((10#$answer - 1)); return 0; fi
    find_checkout_matches "$answer"
    if (( ${#matches[@]} == 1 )); then picked="${matches[0]}"; return 0; fi
    write_err "No such checkout: $answer" >&2
    exit 1
}

resolve_checkout() {
    # resolve_checkout <selector> - sets checkout (an index) and REPO_ROOT: the selector (dir= or a
    # checkout as the first arg), else $BENILLA_DIR, else the only one, else the menu; remembered
    # as the last one used. Its messages go to stderr (see pick_checkout)
    local selector="$1" source="the args"
    if [[ -z "$selector" && -n "${!DIR_ENV_VAR:-}" ]]; then selector="${!DIR_ENV_VAR}"; source="\$$DIR_ENV_VAR"; fi

    if [[ -n "$selector" ]]; then
        find_checkout_matches "$selector"
        if (( ${#matches[@]} == 0 )); then
            write_err "No benilla checkout matches $selector (from $source):" >&2
            list_checkouts "${!checkout_paths[@]}" >&2
            exit 1
        fi
        if (( ${#matches[@]} > 1 )); then
            write_err "$selector (from $source) matches several checkouts - name one by its dir:" >&2
            list_checkouts "${matches[@]}" >&2
            exit 1
        fi
        checkout="${matches[0]}"
    elif (( ${#checkout_paths[@]} == 0 )); then
        write_err "No benilla checkout (a $CHECKOUT_PATTERN dir holding $CLIENT_MANIFEST) under $TOOLS_ROOT." >&2
        exit 1
    elif (( ${#checkout_paths[@]} == 1 )); then
        checkout=0
    else
        pick_checkout
        checkout="$picked"
    fi

    REPO_ROOT="${checkout_paths[$checkout]}"
    { mkdir -p -- "$(dirname -- "$LAST_DIR_FILE")" && printf '%s\n' "$REPO_ROOT" >"$LAST_DIR_FILE"; } 2>/dev/null
    return 0
}

apply_checkout_kind() {
    # What the checkout's kind makes of the options: sets use_gfx, features and wanted_features
    # (the build's)
    local kind="${checkout_kinds[$checkout]}" name="${checkout_names[$checkout]}"
    use_gfx=false
    if [[ "$kind" == "$KIND_TRIMMED" ]] || { [[ "$kind" == "$KIND_GFX_DLL" ]] && ! $opt_nogfx; }; then use_gfx=true; fi
    if $opt_nogfx && [[ "$kind" != "$KIND_GFX_DLL" ]]; then
        write_warn "nogfx is for a $KIND_GFX_DLL checkout ($name is $kind) - ignoring it."
    fi
    if ! $use_gfx && [[ -n "$opt_device$opt_window" ]]; then
        write_warn "$name runs without gfx ($kind) - ignoring the gfx device / window."
        opt_device=""; opt_window=""
    fi
    if $opt_q3 && $opt_worldview; then
        write_warn "q3 is for the client, not the engine viewer - ignoring it."
        opt_q3=false
    fi

    features=()
    if $use_gfx; then kind_features "$kind"; features+=("${kind_feature_list[@]}"); fi
    if $opt_q3; then features+=("$Q3_FEATURE"); fi
    wanted_features="$(join_by "$FEATURE_SEPARATOR" "${features[@]}")"
}

read_command() {
    # read_command <first arg> - returns on run; help shows the help, anything else the usage, and exits
    local name="${1#"${1%%[!-]*}"}"
    name="${name,,}"
    [[ "$name" == "$RUN_COMMAND" ]] && return
    if in_list "$name" "${HELP_TOKENS[@]}"; then
        show_help
        exit 0
    fi
    write_err "Nothing runs without $RUN_COMMAND as the first arg, after an optional checkout (got: $1)."
    write_label "The checkouts ('$ALIAS_NAME help' lists the options):"
    list_checkouts "${!checkout_paths[@]}"
    exit 1
}

read_options() {
    # Sets the opt_* launch options from the script args; exits on an unknown one
    opt_help=false; opt_print_only=false; opt_profile="$DEFAULT_PROFILE"; opt_build=false
    opt_device=""; opt_window=""; opt_win=false; opt_size=""; opt_panel=false; opt_hud=false; opt_worldview=false; opt_at=""
    opt_host=""; opt_realm=""; opt_char=""; opt_probe=false; opt_nosound=false; opt_unattended=false
    opt_capture=""; opt_out=""; opt_fps=""; opt_exit=""; opt_soft=false; opt_validate=false
    opt_data=""; opt_data_set=false; opt_env=()
    opt_dir=""; opt_q3=false; opt_nogfx=false

    local raw name value
    for raw in "$@"; do
        if [[ "$raw" == "$WOW_DATA_VAR="* ]]; then
            opt_data="${raw#*=}"; opt_data_set=true
            continue
        fi
        if [[ "$raw" =~ $ENV_ARG_PATTERN ]]; then
            opt_env+=("$raw")
            continue
        fi

        name="${raw#"${raw%%[!-]*}"}"
        value=""
        if [[ "$name" == *"$OPTION_VALUE_SEPARATOR"* ]]; then
            value="${name#*"$OPTION_VALUE_SEPARATOR"}"
            name="${name%%"$OPTION_VALUE_SEPARATOR"*}"
        fi
        name="${name,,}"
        if [[ -n "$name" && -n "${GFX_DEVICE_ALIASES[$name]:-}" ]]; then name="${GFX_DEVICE_ALIASES[$name]}"; fi
        if [[ -n "$name" && -n "${PROFILE_ALIASES[$name]:-}" ]]; then name="${PROFILE_ALIASES[$name]}"; fi

        if in_list "$name" "${HELP_TOKENS[@]}"; then opt_help=true
        elif in_list "$name" "${PRINT_TOKENS[@]}"; then opt_print_only=true
        elif in_list "$name" "${GFX_DEVICES[@]}"; then opt_device="$name"
        elif in_list "$name" "${GFX_WINDOWS[@]}"; then opt_window="$name"
        elif in_list "$name" "${PROFILE_NAMES[@]}"; then opt_profile="$name"
        elif [[ "$name" == "build" ]]; then opt_build=true
        elif [[ "$name" == "panel" ]]; then opt_panel=true
        elif [[ "$name" == "win" || "$name" == "windowed" ]]; then opt_win=true
        elif [[ "$name" == "size" && -n "$value" ]]; then opt_size="${value,,}"
        elif [[ "$name" == "hud" ]]; then opt_hud=true
        elif [[ "$name" == "worldview" ]]; then opt_worldview=true
        elif [[ "$name" == "at" && -n "$value" ]]; then opt_at="$value"; opt_worldview=true
        elif [[ "$name" == "host" && -n "$value" ]]; then opt_host="$value"
        elif [[ "$name" == "realm" && -n "$value" ]]; then opt_realm="$value"
        elif [[ "$name" == "char" && -n "$value" ]]; then opt_char="$value"
        elif [[ "$name" == "probe" ]]; then opt_probe=true
        elif [[ "$name" == "nosound" ]]; then opt_nosound=true
        elif [[ "$name" == "unattended" ]]; then opt_unattended=true
        elif [[ "$name" == "capture" && -n "$value" ]]; then opt_capture="$value"
        elif [[ "$name" == "out" && -n "$value" ]]; then opt_out="$value"
        elif [[ "$name" == "fps" && -n "$value" ]]; then opt_fps="$value"
        elif [[ "$name" == "exit" && -n "$value" ]]; then opt_exit="$value"
        elif [[ "$name" == "soft" ]]; then opt_soft=true
        elif [[ "$name" == "validate" ]]; then opt_validate=true
        elif [[ "$name" == "dir" && -n "$value" ]]; then opt_dir="$value"
        elif in_list "$name" "${Q3_TOKENS[@]}"; then opt_q3=true
        elif [[ "$name" == "nogfx" ]]; then opt_nogfx=true
        elif [[ "$name" == "data" && -n "$value" ]]; then opt_data="$(realpath -m -- "$value")"; opt_data_set=true
        else
            write_err "Unknown arg: $raw (dir= / size= / at= / host= / realm= / char= / capture= / out= / fps= / exit= need a value) - see '$ALIAS_NAME help'."
            exit 1
        fi
    done

    if [[ -n "$opt_out" && -z "$opt_capture" ]]; then write_warn "out= is for a capture - ignoring it."; fi
    if [[ -n "$opt_size" && ! "$opt_size" =~ $WINDOW_SIZE_PATTERN ]]; then
        write_err "size= takes <W>x<H>, e.g. size=$WINDOWED_DEFAULT_SIZE (got: $opt_size)."
        exit 1
    fi
    if $opt_worldview && [[ -n "$opt_capture" ]]; then
        write_warn "A capture runs in the client - ignoring worldview / at=."
        opt_worldview=false; opt_at=""
    fi
}

resolve_exe() {
    # Sets package (the cargo package of the binary) and exe_path from the options
    package="$CLIENT_EXE_NAME"
    if $opt_worldview; then package="$WORLDVIEW_EXE_NAME"; fi
    exe_path="$REPO_ROOT/${PROFILE_DIRS[$opt_profile]}/$package"
}

resolve_gfx_library() {
    # Sets gfx_lib: the library the build links (see GFX_DLL_ROOT above)
    local gfx_dir config name
    gfx_dir="${GFX_DIR:-}"
    if [[ -z "$gfx_dir" ]]; then
        for name in "${GFX_DIR_NAMES[@]}"; do
            gfx_dir="$GFX_DLL_ROOT/$name"
            [[ -d "$gfx_dir" ]] && break
        done
    fi

    config="${GFX_CONFIGURATION:-}"
    if [[ -z "$config" ]]; then
        for config in "${GFX_CONFIGURATIONS[@]}"; do
            [[ -d "$gfx_dir/bin/${config}_x64" ]] && break
        done
    fi

    gfx_dir_resolved="$gfx_dir"
    gfx_lib="$gfx_dir/bin/${config}_x64/$GFX_LIB_NAME"
}

check_gfx_library() {
    # Exits when the gfx library is not built
    if [[ ! -f "$gfx_lib" ]]; then
        write_err "The gfx library is not built: $gfx_lib"
        write_err "Build it first (or set GFX_DIR / GFX_CONFIGURATION):"
        write_extra "(cd $(format_shell_arg "$gfx_dir_resolved") && mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make -j\$(nproc))"
        exit 1
    fi
    write_ok "gfx library: $gfx_lib"
    write_label "  built $(date -r "$gfx_lib" +"$BUILD_TIME_FORMAT")"
}

check_gfx_copy() {
    # Exits when the client has no copy of the gfx library beside it; warns when it differs
    local copy
    copy="$(dirname -- "$exe_path")/$GFX_LIB_NAME"
    if [[ ! -f "$copy" ]]; then
        write_err "No $GFX_LIB_NAME beside $exe_path - run with 'build' (the build copies it there)."
        exit 1
    fi
    if cmp -s -- "$gfx_lib" "$copy"; then
        write_label "  the copy beside the client is the same"
    elif [[ "$gfx_lib" -nt "$copy" ]]; then
        write_warn "The gfx library is newer than the copy beside the client - add 'build' to copy it again."
    else
        write_warn "The copy beside the client differs from $gfx_lib (another GFX_DIR / configuration?)."
    fi
}

get_build_args() {
    # Sets build_args: cargo's args building the binary of the profile, with the run's features
    local -a profile_args
    read -r -a profile_args <<<"${PROFILE_BUILD_ARGS[$opt_profile]}"
    build_args=(build "${profile_args[@]}" -p "$package")
    if [[ -n "$wanted_features" ]]; then build_args+=(--features "$wanted_features"); fi
}

built_features() {
    # Prints the features the binary was built with (its stamp; none without one)
    local stamp="$exe_path$FEATURES_STAMP_EXT" line=""
    [[ -f "$stamp" ]] && line="$(head -n 1 -- "$stamp")"
    printf '%s' "${line%$'\r'}"
}

features_changed() {
    # True when the binary exists but was built with other features than this run takes
    [[ -f "$exe_path" && "$(built_features)" != "$wanted_features" ]]
}

format_features() {
    printf '%s' "${1:-$NO_FEATURES}"
}

build_client() {
    if ! command -v "$BUILD_COMMAND" >/dev/null 2>&1; then
        write_err "$BUILD_COMMAND not found on PATH - install the Rust toolchain (rustup) first."
        exit 1
    fi

    get_build_args
    write_extra "(cd $REPO_ROOT && $BUILD_COMMAND ${build_args[*]})"
    if ! (cd "$REPO_ROOT" && "$BUILD_COMMAND" "${build_args[@]}"); then
        write_err "Build failed."
        exit 1
    fi
    printf '%s\n' "$wanted_features" >"$exe_path$FEATURES_STAMP_EXT"
    write_ok "Build done."
}

resolve_wow_data() {
    # Sets wow_data: data= / a WOW_DATA= arg, else $WOW_DATA, else $wow_classic_dir/Data; exits
    # when that dir does not exist
    local source
    if $opt_data_set; then
        wow_data="$opt_data"; source="the args"
    elif [[ -n "${WOW_DATA+set}" ]]; then
        wow_data="$WOW_DATA"; source="\$WOW_DATA"
    elif [[ -n "${wow_classic_dir:-}" ]]; then
        wow_data="$wow_classic_dir/$WOW_DATA_SUBDIR"; source="\$wow_classic_dir"
    else
        write_warn "wow_classic_dir is not set - set it to the WoW install, or pass data=<WoW Data dir>."
        exit 1
    fi

    if [[ -z "$wow_data" ]]; then
        write_label "WoW data: none ($WOW_DATA_VAR is empty, from $source)"
        return
    fi
    if [[ ! -d "$wow_data" ]]; then
        write_warn "The WoW Data dir does not exist: $wow_data (from $source) - pass data=<WoW Data dir>."
        exit 1
    fi
    write_label "WoW data: $wow_data (from $source)"
}

read_probe_field() {
    # read_probe_field <name> - one field of .probe-identity (quotes stripped), as the smoke scripts read it
    sed -n "s/^[[:space:]]*$1=[\"]*\\([^\"]*\\)[\"]*[[:space:]]*\$/\\1/p" "$REPO_ROOT/$PROBE_IDENTITY_NAME" | head -1
}

get_run_env() {
    # Sets run_env: the env vars of the options, as NAME=value
    local field value
    run_env=()
    probe_env_start=-1
    run_env+=("$WOW_DATA_VAR=$wow_data")

    if $opt_probe; then
        if [[ ! -f "$REPO_ROOT/$PROBE_IDENTITY_NAME" ]]; then
            write_err "probe needs $REPO_ROOT/$PROBE_IDENTITY_NAME ($(join_by '=, ' "${PROBE_FIELDS[@]}")=, one per line)."
            exit 1
        fi
        probe_env_start=${#run_env[@]}
        for field in "${PROBE_FIELDS[@]}"; do
            value="$(read_probe_field "$field")"
            if [[ -z "$value" ]]; then
                write_err "$PROBE_IDENTITY_NAME has no $field."
                exit 1
            fi
            run_env+=("$field=$value")
        done
    fi

    [[ -n "$opt_device" ]] && run_env+=("WOW_GFX_DEVICE=$opt_device")
    if [[ -n "$opt_window" ]]; then run_env+=("WOW_GFX_WINDOW=$opt_window")
    elif $use_gfx && [[ -n "$DEFAULT_GFX_WINDOW" && " ${opt_env[*]} " != *" WOW_GFX_WINDOW="* ]]; then
        run_env+=("WOW_GFX_WINDOW=$DEFAULT_GFX_WINDOW")
    fi
    if [[ -n "$opt_size" ]]; then run_env+=("WOW_WIN=$opt_size")
    elif $opt_win; then run_env+=("WOW_WIN=$WINDOWED_DEFAULT_SIZE"); fi
    $opt_panel && run_env+=("WOW_PANEL=1")
    $opt_hud && run_env+=("WOW_PERF_HUD=1")
    [[ -n "$opt_at" ]] && run_env+=("WOW_WORLDVIEW_AT=$opt_at")
    [[ -n "$opt_host" ]] && run_env+=("WOW_HOST=$opt_host")
    [[ -n "$opt_realm" ]] && run_env+=("WOW_REALM=$opt_realm")
    [[ -n "$opt_char" ]] && run_env+=("WOW_CHAR=$opt_char")
    $opt_nosound && run_env+=("WOW_NOSOUND=1")
    $opt_unattended && run_env+=("WOW_UNATTENDED=1")
    if [[ -n "$opt_capture" ]]; then
        run_env+=("WOW_CAPTURE=$opt_capture")
        if [[ "$opt_capture" != "$CAPTURE_LIST" ]]; then
            capture_out="${opt_out:-$REPO_ROOT/$CAPTURE_OUT_SUBDIR/$opt_capture.png}"
            run_env+=("WOW_CAPTURE_OUT=$capture_out")
        fi
    fi
    [[ -n "$opt_fps" ]] && run_env+=("WOW_LIVE_FPS=$opt_fps")
    [[ -n "$opt_exit" ]] && run_env+=("WOW_PROBE_EXIT_AT=$opt_exit")
    $opt_soft && run_env+=("${SOFT_ENV[@]}")
    $opt_validate && run_env+=("${VALIDATE_ENV[@]}")
    run_env+=("${opt_env[@]}")
    return 0
}

format_shell_arg() {
    # Single-quotes an arg bash would split or expand
    if [[ "$1" =~ ^[A-Za-z0-9_./:=+,-]+$ ]]; then
        printf '%s' "$1"
    else
        printf "'%s'" "${1//\'/\'\\\'\'}"
    fi
}

format_args() {
    # The args as one bash-quoted string
    local arg first=true
    for arg in "$@"; do
        if $first; then first=false; else printf ' '; fi
        format_shell_arg "$arg"
    done
}

format_env_args() {
    # The env vars as one bash-quoted string; the probe's fields are read from its file (in
    # their place, so a later char= still wins) and secrets are masked, so the printed line holds
    # no password
    local item name index=0 first=true probe_file
    probe_file="$(format_shell_arg "$REPO_ROOT/$PROBE_IDENTITY_NAME")"
    for item in "$@"; do
        name="${item%%=*}"
        if (( probe_env_start >= 0 && index >= probe_env_start && index < probe_env_start + ${#PROBE_FIELDS[@]} )); then
            if (( index == probe_env_start )); then
                if $first; then first=false; else printf ' '; fi
                printf '$(grep -E %s %s)' "'^($(join_by '|' "${PROBE_FIELDS[@]}"))='" "$probe_file"
            fi
        else
            if $first; then first=false; else printf ' '; fi
            if in_list "$name" "${SECRET_VARS[@]}"; then
                printf '%s=%s' "$name" "$SECRET_MASK"
            else
                format_shell_arg "$item"
            fi
        fi
        index=$((index + 1))
    done
}

show_launch_command() {
    # Prints the bash line(s) reproducing this run
    echo
    write_extra "# $ALIAS_NAME $(format_args "${script_args[@]}")"
    write_extra "# checkout: ${checkout_names[$checkout]} (${checkout_branches[$checkout]}, ${checkout_kinds[$checkout]}), features: $(format_features "$wanted_features")"
    if $opt_build || [[ ! -f "$exe_path" ]] || features_changed; then
        get_build_args
        write_extra "(cd $(format_shell_arg "$REPO_ROOT") && $BUILD_COMMAND ${build_args[*]})"
    fi
    write_extra "(cd $(format_shell_arg "$REPO_ROOT") && env $(format_env_args "${run_env[@]}") $(format_shell_arg "$exe_path"))"
}

start_client() {
    # Runs the client from the repo root in the foreground (the dev build's state and the
    # default capture paths are relative to it)
    local exit_code=0
    (cd "$REPO_ROOT" && env "${run_env[@]}" "$exe_path") || exit_code=$?

    if [[ -n "$capture_out" && -f "$capture_out" ]]; then write_ok "Capture: $capture_out"; fi
    if (( exit_code == 0 )); then
        write_label "$(basename -- "$exe_path") exited (exit code 0)."
        return
    fi

    write_err "$(basename -- "$exe_path") exited with exit code $exit_code."
    if (( exit_code == EXIT_LOADER_FAILED )); then
        write_err "$EXIT_LOADER_FAILED: it could not be started - a shared library may be missing (ldd $exe_path)."
    fi
    exit 1
}

script_args=("$@")
find_checkouts
if [[ "${1:-}" == "$CHECKOUT_DIR_COMMAND" ]]; then
    # The sourced bare call's question: the checkout's path, alone on stdout
    resolve_checkout ""
    printf '%s\n' "$REPO_ROOT"
    exit 0
fi

# A checkout as the first arg (anything but run / help that names one)
selector=""
if (( $# > 0 )); then
    first="${1#"${1%%[!-]*}"}"
    if [[ "${first,,}" != "$RUN_COMMAND" ]] && ! in_list "${first,,}" "${HELP_TOKENS[@]}"; then
        find_checkout_matches "$first"
        if (( ${#matches[@]} > 0 )); then selector="$first"; shift; fi
    fi
fi

if (( $# == 0 )); then
    resolve_checkout "$selector"
    show_usage
    exit 0
fi
read_command "$1"
shift
read_options "$@"
if $opt_help; then
    show_help
    exit 0
fi
if [[ -n "$opt_dir" ]]; then selector="$opt_dir"; fi
resolve_checkout "$selector"
apply_checkout_kind

write_alt "benilla... ${checkout_names[$checkout]} (${checkout_branches[$checkout]}, ${checkout_kinds[$checkout]}: ${KIND_INFO[${checkout_kinds[$checkout]}]}), features: $(format_features "$wanted_features")"
if (( $# == 0 )); then show_manual_run "$checkout"; fi

if [[ ! -d "$REPO_ROOT" ]]; then
    write_err "benilla repo not found: $REPO_ROOT"
    exit 1
fi

check_gfx_pair() {
    # Names a WOW_GFX_WINDOW / WOW_GFX_DEVICE the run takes from the environment (the launch line
    # lists only what this script sets) or a WOW_GFX_WINDOW there it overrides, and warns about a
    # d3d device in a window other than win32
    local entry window="" device="" hint=""
    for entry in "${run_env[@]}"; do
        case "$entry" in
            WOW_GFX_WINDOW=*) window="${entry#*=}" ;;
            WOW_GFX_DEVICE=*) device="${entry#*=}" ;;
        esac
    done
    if [[ -n "$window" && -n "${WOW_GFX_WINDOW:-}" && "${WOW_GFX_WINDOW,,}" != "${window,,}" ]]; then
        write_label "WOW_GFX_WINDOW=$WOW_GFX_WINDOW in the environment is not used: the window is $window."
    elif [[ -z "$window" && -n "${WOW_GFX_WINDOW:-}" ]]; then
        window="$WOW_GFX_WINDOW"
        hint=", or unset WOW_GFX_WINDOW"
        write_label "WOW_GFX_WINDOW=$window (from the environment)"
    fi
    if [[ -z "$device" && -n "${WOW_GFX_DEVICE:-}" ]]; then
        device="$WOW_GFX_DEVICE"
        write_label "WOW_GFX_DEVICE=$device (from the environment)"
    fi
    if in_list "${device,,}" "${D3D_DEVICES[@]}" && [[ -n "$window" && "${window,,}" != "$D3D_WINDOW" ]]; then
        write_warn "$device opens only in a $D3D_WINDOW window, not $window: its window will not be created - name $D3D_WINDOW$hint."
    fi
}

capture_out=""
resolve_wow_data
resolve_exe
resolve_gfx_library
get_run_env
if $use_gfx; then check_gfx_pair; fi

if $opt_print_only; then
    show_launch_command
    exit 0
fi

if $use_gfx; then check_gfx_library; fi
if $opt_build || [[ ! -f "$exe_path" ]] || features_changed; then
    if [[ ! -f "$exe_path" ]]; then write_warn "No $exe_path yet - building it."
    elif features_changed; then write_warn "$exe_path was built with features: $(format_features "$(built_features)"), this run takes: $(format_features "$wanted_features") - building it."; fi
    build_client
fi
if [[ ! -f "$exe_path" ]]; then
    write_err "The build finished but $exe_path is still missing."
    exit 1
fi

write_label "Using: $exe_path"
write_label "  built $(date -r "$exe_path" +"$BUILD_TIME_FORMAT"), features: $(format_features "$(built_features)")"
if $use_gfx; then check_gfx_copy; fi

echo

write_extra "env $(format_env_args "${run_env[@]}") $exe_path"
start_client
