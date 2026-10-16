#!/usr/bin/env bash
# ioq3rs.sh - the bash / Linux version of ioq3rs.ps1: builds (when missing) and starts the
# ioq3-rs client (the Rust port of ioquake3) from target/dist/release.
#
# Usage examples (nothing runs without `run` as the first arg; the args after it in any order,
# case insensitive; `.ioq3rs help` lists them all):
# cd into the repo and print how to run it, through this script and by hand (runs nothing):
# .ioq3rs
#
# start like before (the device / renderer last used are remembered in q3config.cfg; the window
# is the platform's, win32 / x11, unless named):
# .ioq3rs run
#
# pick the gfx device and / or window (ignored by a build without gfx):
# .ioq3rs run vk glfw
# .ioq3rs run gles3 x11
#
# dev map (q3dm0) in a window:
# .ioq3rs run dev win
#
# another map with bots, on a fresh config, writing qconsole.log:
# .ioq3rs run map=q3dm17 bots fresh log
#
# timedemo benchmark on vk:
# .ioq3rs run bench vk
#
# the QVMs instead of the Rust modules, raw game args after them (from the first + arg on):
# .ioq3rs run qvm dev +set r_mode 6
#
# print the bash lines for this run instead of running it:
# .ioq3rs run vk dev print

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

# When true, missing pk3 files are linked / copied without asking first
AUTO_COPY_DATA=false
# When true, a pk3 found on the same filesystem is hard-linked instead of copied (no extra disk
# space; falls back to a copy when linking fails)
LINK_SAME_VOLUME=true

# The Rust port; `cargo xtask dist --release` puts ioquake3, the renderer .so files and the Rust
# modules (baseq3/, missionpack/) in target/dist/release - built when the exe is missing
REPO_ROOT="$code_root_dir/Code2/Rust/ioq3-rs"
DIST_SUBPATH="target/dist/release"
CLIENT_EXE_NAME="ioquake3"
BUILD_COMMAND="cargo"
BUILD_ARGS=(xtask dist --release)
BUILD_TIME_FORMAT="%Y-%m-%d %H:%M:%S"
CLIENT_ARGS=(+set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0)

# A bare call cds into the repo and prints how to run it (show_usage), running nothing. The cd
# only reaches the calling shell when the script is sourced (the .zshrc alias sources it for a
# bare call), so a sourced script prints through a bash run of itself and returns here, before
# the bash-only code below
if (( $# == 0 )) && (return 0 2>/dev/null); then
    cd -- "$REPO_ROOT" || return 1
    bash "${BASH_SOURCE[0]:-$0}"
    return 0
fi

# Game data: <exe dir>/baseq3 needs these. They are reused from another build's baseq3 first (a
# C ioq3 build or another dist dir of this port), then from <any mounted drive>/2024/baseq3
BASEQ3_DIR_NAME="baseq3"
HDD_BASEQ3_SUBPATH="2024/$BASEQ3_DIR_NAME"
# The Linux stand-ins for the drive roots of the ps1 (/media/2024, /media2/2024, /mnt/new, ...)
HDD_ROOT_GLOBS=(/media /media2 /mnt/* /media/* "/run/media/${USER:-}"/*)
PK3_PATTERN="*.pk3"
REQUIRED_PK3S=(pak{0..8}.pk3)
C_REPO_ROOT="$code_root_dir/Code2/C/ioq3"
C_BUILD_DIR_PATTERN="build*"
C_BASEQ3_SEARCH_DEPTH=3
DIST_ROOT="$REPO_ROOT/$(dirname -- "$DIST_SUBPATH")"

# The game's own console log (its default fs_homepath on Linux)
DEFAULT_HOME_DIR="$HOME/.q3a"
# Exit code of a process the loader could not start (e.g. a missing shared library)
EXIT_LOADER_FAILED=127

# Launch options (show_help). The gfx backends only reach a client built with use_gfx: one that
# links libgfx.so and has renderer_gfx.so next to it (a dist dir keeps a renderer_gfx.so from an
# earlier gfx build, so that file alone says nothing). The branch only decides it for `print`
# when nothing is built yet.
ALIAS_NAME=".ioq3rs"
RUN_COMMAND="run"
HELP_TOKENS=(help h)
PRINT_TOKENS=(print onlyprint showcmd)
GFX_DEVICES=(gl4 gl3 gles3 vk d3d11 d3d12)
declare -A GFX_DEVICE_ALIASES=([vulkan]=vk [dx11]=d3d11 [dx12]=d3d12)
GFX_WINDOWS=(sdl glfw x11 win32)
# The window when none is named (a window option or a raw +set r_gfxWindow): the platform's own,
# win32 on Windows (Git Bash / MSYS / Cygwin) and x11 on Linux, even over the r_gfxWindow
# q3config.cfg remembers; elsewhere the game's (q3config.cfg's, else sdl). It does not pick
# renderer_gfx. A d3d device opens only in a win32 window: the game switches to win32 itself.
# Q3_HOME_DIR is the game's own fs_homepath, whose baseq3/q3config.cfg holds the remembered cvars.
case "${OSTYPE:-}" in
    msys* | cygwin* | win32*) DEFAULT_GFX_WINDOW="win32"; Q3_HOME_DIR="${APPDATA:-$HOME/AppData/Roaming}/Quake3" ;;
    linux*) DEFAULT_GFX_WINDOW="x11"; Q3_HOME_DIR="$HOME/.q3a" ;;
    darwin*) DEFAULT_GFX_WINDOW=""; Q3_HOME_DIR="$HOME/Library/Application Support/Quake3" ;;
    *) DEFAULT_GFX_WINDOW=""; Q3_HOME_DIR="$HOME/.q3a" ;;
esac
D3D_DEVICES=(d3d11 d3d12)
D3D_WINDOW="win32"
Q3CONFIG_NAME="q3config.cfg"
GFX_RENDERER="gfx"
RENDERERS=("$GFX_RENDERER" opengl1 opengl2)
GFX_RENDERER_LIB_NAME="renderer_gfx.so"
GFX_LIB_NAME="libgfx.so"
GFX_BRANCH="gfx"
OPTION_VALUE_SEPARATOR="="
PASSTHROUGH_PREFIX="+"
DEV_MAP="q3dm0"
BOTS=(sarge doom)
BOT_SKILL="2"
BOT_WAIT_FRAMES="200"
WINDOWED_ARGS=(+set r_fullscreen 0 +set r_mode 4)
QVM_ARGS=(+set vm_game 2 +set vm_cgame 2 +set vm_ui 2)
LOG_ARGS=(+set logfile 2)
NO_BOTS_ARGS=(+set bot_enable 0)
TEAM_ARENA_ARGS=(+set fs_game missionpack)
BENCH_ARGS=(+set r_mode -1 +set r_customwidth 1920 +set r_customheight 1080
    +set r_swapInterval 0 +set com_maxfps 0 +timedemo 1 +demo four)
FRESH_HOME_DIR="${TMPDIR:-/tmp}/ioq3rs-fresh"

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
    write_alt "ioq3rs - build (when missing) and start the ioq3-rs client from $REPO_ROOT/$DIST_SUBPATH"
    cat <<EOF

Usage: $ALIAS_NAME $RUN_COMMAND [options] [+game args...]
Nothing runs without $RUN_COMMAND as the first arg; a bare $ALIAS_NAME cds into the repo and prints how to run it.
Options are case insensitive, in any order, with or without leading dashes.

gfx backends (used only when the built client supports gfx, ignored otherwise):
  $(join_by ' | ' "${GFX_DEVICES[@]}")   r_gfxDevice (vulkan = vk, dx11 / dx12 = d3d11 / d3d12)
  $(join_by ' | ' "${GFX_WINDOWS[@]}")         r_gfxWindow
  d3d11 / d3d12 / win32 are Windows only: the game falls back to gl4 / sdl here.
  Either one also sets cl_renderer $GFX_RENDERER. r_gfxDevice is remembered in q3config.cfg, so a
  start without one uses the last; the window is the platform's (win32 / x11) unless named, even
  over the remembered one (it does not pick renderer_gfx). vk can hang the GPU driver - keep runs
  short.

Renderer:
  $(join_by ' | ' "${RENDERERS[@]}")     cl_renderer ($GFX_RENDERER only on a gfx build)

Starting:
  dev                    +devmap $DEV_MAP (skips the menu)
  dev=<map>, map=<map>   +devmap <map>
  bots                   +addbot $(join_by ', ' "${BOTS[@]}") (skill $BOT_SKILL) on the map (dev map if none given)
  nobots                 bot_enable 0
  connect=<address>      +connect <address> (instead of a map)
  bench                  timedemo 1 of demo four at 1920x1080, vsync / fps cap off, logfile on
  win                    windowed 800x600 (r_fullscreen 0, r_mode 4)
  qvm                    run the QVMs from the paks instead of the Rust game modules
  ta                     Team Arena (fs_game missionpack; needs its paks in missionpack/)
  fresh                  empty fs_homepath at $FRESH_HOME_DIR (cleared each run)
  log                    logfile 2 (qconsole.log in <home>/baseq3)

Other:
  +...                   this arg and all after it go to the game as they are
  $(join_by ' | ' "${PRINT_TOKENS[@]}")  print the bash lines for this run instead of running it
  $(join_by ' | ' "${HELP_TOKENS[@]}") (also -help, --help)  this help

Examples:
  $ALIAS_NAME $RUN_COMMAND vk glfw dev win
  $ALIAS_NAME $RUN_COMMAND map=q3dm17 bots fresh log
  $ALIAS_NAME $RUN_COMMAND bench gles3
  $ALIAS_NAME $RUN_COMMAND opengl1 dev +set r_mode 6
EOF
}

show_usage() {
    # A bare call: how to run ioq3-rs from the repo, through this script and by hand
    write_alt "ioq3-rs - $REPO_ROOT"
    write_label "Run it through this script (the options after $RUN_COMMAND; '$ALIAS_NAME help' lists them):"
    write_extra "$ALIAS_NAME $RUN_COMMAND"
    show_manual_run
}

show_manual_run() {
    # Prints how to build and start the client by hand, without this script (the pk3 check left out)
    write_label "Or run it manually (from $REPO_ROOT; the build only when $DIST_SUBPATH/$CLIENT_EXE_NAME is missing or old):"
    write_extra "$BUILD_COMMAND ${BUILD_ARGS[*]} && (cd $DIST_SUBPATH && ./$CLIENT_EXE_NAME $(format_args "${CLIENT_ARGS[@]}"))"
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
    write_err "Nothing runs without $RUN_COMMAND as the first arg (got: $1)."
    show_usage
    exit 1
}

read_options() {
    # Sets the opt_* launch options from the script args; exits on an unknown one
    opt_help=false; opt_print_only=false; opt_device=""; opt_window=""; opt_renderer=""
    opt_map=""; opt_bots=false; opt_no_bots=false; opt_connect=""; opt_bench=false
    opt_windowed=false; opt_qvm=false; opt_team_arena=false; opt_fresh=false; opt_log=false
    opt_extra=()

    local raw name value
    while (( $# > 0 )); do
        raw="$1"
        if [[ "$raw" == "$PASSTHROUGH_PREFIX"* ]]; then
            opt_extra=("$@")
            break
        fi

        name="${raw#"${raw%%[!-]*}"}"
        value=""
        if [[ "$name" == *"$OPTION_VALUE_SEPARATOR"* ]]; then
            value="${name#*"$OPTION_VALUE_SEPARATOR"}"
            name="${name%%"$OPTION_VALUE_SEPARATOR"*}"
        fi
        name="${name,,}"
        if [[ -n "$name" && -n "${GFX_DEVICE_ALIASES[$name]:-}" ]]; then name="${GFX_DEVICE_ALIASES[$name]}"; fi

        if in_list "$name" "${HELP_TOKENS[@]}"; then opt_help=true
        elif in_list "$name" "${PRINT_TOKENS[@]}"; then opt_print_only=true
        elif in_list "$name" "${GFX_DEVICES[@]}"; then opt_device="$name"
        elif in_list "$name" "${GFX_WINDOWS[@]}"; then opt_window="$name"
        elif in_list "$name" "${RENDERERS[@]}"; then opt_renderer="$name"
        elif [[ "$name" == "dev" ]]; then opt_map="${value:-$DEV_MAP}"
        elif [[ "$name" == "map" && -n "$value" ]]; then opt_map="$value"
        elif [[ "$name" == "connect" && -n "$value" ]]; then opt_connect="$value"
        elif [[ "$name" == "bots" ]]; then opt_bots=true
        elif [[ "$name" == "nobots" ]]; then opt_no_bots=true
        elif [[ "$name" == "bench" ]]; then opt_bench=true
        elif [[ "$name" == "win" ]]; then opt_windowed=true
        elif [[ "$name" == "qvm" ]]; then opt_qvm=true
        elif [[ "$name" == "ta" ]]; then opt_team_arena=true
        elif [[ "$name" == "fresh" ]]; then opt_fresh=true
        elif [[ "$name" == "log" ]]; then opt_log=true
        else
            write_err "Unknown arg: $raw (map= / dev= / connect= need a value) - see '$ALIAS_NAME help'."
            exit 1
        fi
        shift
    done

    if $opt_bots && [[ -z "$opt_map" ]]; then opt_map="$DEV_MAP"; fi
}

test_gfx_build() {
    # True when the client was built with use_gfx (see the launch options above)
    local exe="$1"
    [[ -f "$(dirname -- "$exe")/$GFX_RENDERER_LIB_NAME" ]] || return 1
    if command -v readelf >/dev/null 2>&1; then
        readelf -d -- "$exe" 2>/dev/null | grep -qF "Shared library: [$GFX_LIB_NAME"
    else
        LC_ALL=C grep -qaF -- "$GFX_LIB_NAME" "$exe"
    fi
}

raw_cvar() {
    # raw_cvar <name> - the value the last raw `+set <name> <value>` (or seta / set) among the game
    # args gives, else empty
    local i value=""
    for (( i = 1; i + 1 < ${#opt_extra[@]}; i++ )); do
        if [[ "${opt_extra[i],,}" == "${1,,}" && "${opt_extra[i-1],,}" =~ ^\+?seta?$ ]]; then
            value="${opt_extra[i+1]}"
        fi
    done
    printf '%s' "$value"
}

remembered_cvar() {
    # remembered_cvar <name> - the value q3config.cfg in the game's home remembers
    # (seta <name> "<value>"), else empty; a `fresh` home has none
    local path="$Q3_HOME_DIR/$BASEQ3_DIR_NAME/$Q3CONFIG_NAME"
    if $opt_fresh || [[ ! -f "$path" ]]; then return 0; fi
    sed -n "s/^[[:space:]]*seta[[:space:]][[:space:]]*$1[[:space:]][[:space:]]*\"\{0,1\}\([^\"]*\)\"\{0,1\}.*/\1/p" "$path" | tail -n 1
}

resolve_gfx_options() {
    # Drops the gfx options on a build without gfx; on a gfx build a backend also picks renderer_gfx
    local gfx_build="$1"
    local -a ignored=()

    if ! $gfx_build; then
        [[ -n "$opt_device" ]] && ignored+=("$opt_device")
        [[ -n "$opt_window" ]] && ignored+=("$opt_window")
        if [[ "$opt_renderer" == "$GFX_RENDERER" ]]; then ignored+=("$opt_renderer"); opt_renderer=""; fi
        write_label "The client is built without gfx."
        if (( ${#ignored[@]} > 0 )); then write_warn "Ignoring the gfx arg(s): $(join_by ', ' "${ignored[@]}")"; fi
        opt_device=""
        opt_window=""
        return
    fi

    write_label "The client is built with gfx."
    if [[ -n "$opt_device" || -n "$opt_window" ]]; then
        if [[ -z "$opt_renderer" ]]; then
            opt_renderer="$GFX_RENDERER"
        elif [[ "$opt_renderer" != "$GFX_RENDERER" ]]; then
            write_warn "cl_renderer $opt_renderer ignores r_gfxDevice / r_gfxWindow."
        fi
    fi

    # The platform's window unless one is named, over the one q3config.cfg remembers
    local raw_window remembered window device
    raw_window="$(raw_cvar r_gfxWindow)"
    if [[ -z "$opt_window" && -z "$raw_window" && -n "$DEFAULT_GFX_WINDOW" ]]; then
        opt_window="$DEFAULT_GFX_WINDOW"
    fi
    window="${raw_window:-$opt_window}"
    remembered="$(remembered_cvar r_gfxWindow)"
    if [[ -n "$window" && -n "$remembered" && "${remembered,,}" != "${window,,}" ]]; then
        write_label "r_gfxWindow $remembered in $Q3CONFIG_NAME is not used: the window is $window."
    fi
    window="${window:-$remembered}"

    device="$(raw_cvar r_gfxDevice)"
    device="${device:-$opt_device}"
    if [[ -z "$device" ]]; then device="$(remembered_cvar r_gfxDevice)"; fi
    if in_list "${device,,}" "${D3D_DEVICES[@]}"; then
        if [[ "$DEFAULT_GFX_WINDOW" != "$D3D_WINDOW" ]]; then
            write_warn "$device is Windows only: the game falls back to its default device here."
        elif [[ -n "$window" && "${window,,}" != "$D3D_WINDOW" ]]; then
            write_warn "$device opens only in a $D3D_WINDOW window, not $window: the game uses $D3D_WINDOW instead."
        fi
    fi
}

get_launch_args() {
    # Sets launch_args: the defaults, then the cvars of the options, then the commands
    launch_args=("${CLIENT_ARGS[@]}")
    if $opt_qvm; then launch_args+=("${QVM_ARGS[@]}"); fi
    if $opt_team_arena; then launch_args+=("${TEAM_ARENA_ARGS[@]}"); fi
    if $opt_fresh; then launch_args+=(+set fs_homepath "$FRESH_HOME_DIR"); fi
    if [[ -n "$opt_renderer" ]]; then launch_args+=(+set cl_renderer "$opt_renderer"); fi
    if [[ -n "$opt_device" ]]; then launch_args+=(+set r_gfxDevice "$opt_device"); fi
    if [[ -n "$opt_window" ]]; then launch_args+=(+set r_gfxWindow "$opt_window"); fi
    if $opt_windowed; then launch_args+=("${WINDOWED_ARGS[@]}"); fi
    if $opt_log || $opt_bench; then launch_args+=("${LOG_ARGS[@]}"); fi
    if $opt_no_bots; then launch_args+=("${NO_BOTS_ARGS[@]}"); fi

    local bot
    if $opt_bench; then
        if [[ -n "$opt_map" || -n "$opt_connect" ]]; then write_warn "bench plays a demo - ignoring the map / connect."; fi
        launch_args+=("${BENCH_ARGS[@]}")
    elif [[ -n "$opt_connect" ]]; then
        if [[ -n "$opt_map" ]]; then write_warn "connect joins a server - ignoring the map."; fi
        launch_args+=(+connect "$opt_connect")
    elif [[ -n "$opt_map" ]]; then
        launch_args+=(+devmap "$opt_map")
        if $opt_bots; then
            launch_args+=(+wait "$BOT_WAIT_FRAMES")
            for bot in "${BOTS[@]}"; do launch_args+=(+addbot "$bot" "$BOT_SKILL"); done
        fi
    fi

    launch_args+=("${opt_extra[@]}")
}

reset_fresh_home() {
    # The `fresh` fs_homepath is emptied first, so no q3config.cfg or *.pid carries over
    rm -rf -- "$FRESH_HOME_DIR"
    write_label "Fresh home: $FRESH_HOME_DIR"
}

format_shell_arg() {
    # Single-quotes an arg bash would split or expand
    if [[ "$1" =~ ^[A-Za-z0-9_./:=+-]+$ ]]; then
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

show_launch_command() {
    # Prints the bash lines reproducing this run (the pk3 check is left out)
    local dist_dir="$REPO_ROOT/$DIST_SUBPATH"
    local exe="$dist_dir/$CLIENT_EXE_NAME" gfx_build=false branch line
    local -a lines=("# $ALIAS_NAME $(format_args "${script_args[@]}")")

    if [[ -f "$exe" ]]; then
        test_gfx_build "$exe" && gfx_build=true
    else
        lines+=("(cd $(format_shell_arg "$REPO_ROOT") && $BUILD_COMMAND ${BUILD_ARGS[*]})")
        branch="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null)"
        [[ "$branch" == "$GFX_BRANCH" ]] && gfx_build=true
        write_label "No $CLIENT_EXE_NAME yet - going by the branch ($branch) for gfx support."
    fi

    resolve_gfx_options "$gfx_build"
    get_launch_args
    if $opt_fresh; then lines+=("rm -rf -- $(format_shell_arg "$FRESH_HOME_DIR")"); fi
    lines+=("(cd $(format_shell_arg "$dist_dir") && ./$CLIENT_EXE_NAME $(format_args "${launch_args[@]}"))")

    echo
    for line in "${lines[@]}"; do write_extra "$line"; done
}

build_client() {
    local repo_root="$1" exit_code=0
    if ! command -v "$BUILD_COMMAND" >/dev/null 2>&1; then
        write_err "$BUILD_COMMAND not found on PATH - install the Rust toolchain (rustup) first."
        exit 1
    fi

    write_warn "No $CLIENT_EXE_NAME in $repo_root/$DIST_SUBPATH - building it."
    write_extra "$BUILD_COMMAND ${BUILD_ARGS[*]}"

    (cd "$repo_root" && "$BUILD_COMMAND" "${BUILD_ARGS[@]}") || exit_code=$?

    if (( exit_code != 0 )); then
        write_err "Build failed (exit code $exit_code)."
        exit 1
    fi
    write_ok "Build done."
}

resolve_client_exe() {
    # Sets exe_path, building the client when it is missing
    local repo_root="$1"
    if [[ ! -d "$repo_root" ]]; then
        write_err "ioq3-rs repo not found: $repo_root"
        exit 1
    fi

    exe_path="$repo_root/$DIST_SUBPATH/$CLIENT_EXE_NAME"
    if [[ ! -f "$exe_path" ]]; then
        build_client "$repo_root"
        if [[ ! -f "$exe_path" ]]; then
            write_err "The build finished but $exe_path is still missing."
            exit 1
        fi
    fi

    exe_path="$(realpath -- "$exe_path")"
    write_label "Using build: $exe_path"
    write_label "  built $(date -r "$exe_path" +"$BUILD_TIME_FORMAT")"
}

get_missing_files() {
    # get_missing_files <dir> <file names...> - prints the names not found in dir
    local dir="$1" name
    shift
    for name in "$@"; do
        [[ -f "$dir/$name" ]] || printf '%s\n' "$name"
    done
}

find_c_baseq3_dirs() {
    # Every <C repo>/build*/**/baseq3 and <this repo>/target/dist/**/baseq3 (a build's game
    # data), newest first
    local search_root
    for search_root in "$C_REPO_ROOT"/$C_BUILD_DIR_PATTERN "$DIST_ROOT"; do
        [[ -d "$search_root" ]] || continue
        find "$search_root" -mindepth 1 -maxdepth $((C_BASEQ3_SEARCH_DEPTH + 1)) -type d \
            -iname "$BASEQ3_DIR_NAME" -printf '%T@ %p\n' 2>/dev/null
    done | sort -rn | cut -d' ' -f2-
}

find_hdd_baseq3_dirs() {
    # Every <mounted drive>/2024/baseq3
    local root candidate
    local -A seen=()
    for root in "${HDD_ROOT_GLOBS[@]}"; do
        candidate="$root/$HDD_BASEQ3_SUBPATH"
        [[ -d "$candidate" ]] || continue
        candidate="$(realpath -- "$candidate")"
        [[ -n "${seen[$candidate]:-}" ]] && continue
        seen[$candidate]=1
        printf '%s\n' "$candidate"
    done
}

find_source_baseq3() {
    # Sets source_baseq3: the first baseq3 (builds first, then the drives) that holds every
    # required pk3
    local target_full candidate
    local -a candidates missing
    target_full="$(realpath -m -- "$1")"
    source_baseq3=""

    mapfile -t candidates < <(find_c_baseq3_dirs; find_hdd_baseq3_dirs)
    for candidate in "${candidates[@]}"; do
        [[ "$(realpath -m -- "$candidate")" == "$target_full" ]] && continue

        mapfile -t missing < <(get_missing_files "$candidate" "${REQUIRED_PK3S[@]}")
        if (( ${#missing[@]} == 0 )); then
            write_ok "Found baseq3 data: $candidate"
            source_baseq3="$candidate"
            return
        fi
        write_warn "$candidate is missing $(join_by ', ' "${missing[@]}") - skipping it."
    done
}

confirm_copy() {
    if [[ "$AUTO_COPY_DATA" == true ]]; then
        write_label "AUTO_COPY_DATA is set - going ahead without asking."
        return 0
    fi
    local answer
    read -r -p "$1 [y/N] " answer
    answer="${answer,,}"
    [[ "$answer" == "y" || "$answer" == "yes" ]]
}

add_data_file() {
    # Hard-links the file when source and destination share a filesystem (and LINK_SAME_VOLUME
    # is set), copies it otherwise or when linking fails
    local source="$1" dest_dir="$2"
    local dest="$dest_dir/$(basename -- "$source")"

    if [[ "$LINK_SAME_VOLUME" == true && "$(stat -c %d -- "$source")" == "$(stat -c %d -- "$dest_dir")" ]]; then
        if ln -- "$source" "$dest" 2>/dev/null; then
            write_ok "Linked $source -> $dest"
            return
        fi
        write_warn "Could not link $source - copying instead."
    fi

    if cp -- "$source" "$dest_dir/"; then
        write_ok "Copied $source -> $dest_dir"
    else
        write_err "Could not copy $source -> $dest_dir"
    fi
}

sync_baseq3() {
    # Links / copies the source's missing pk3 files into baseq3 (after one confirmation), then
    # checks the required ones. Exits when a required pk3 is still missing.
    local baseq3_dir="$1" name
    local -a missing_required source_names to_copy still_missing
    source_baseq3=""

    mapfile -t missing_required < <(get_missing_files "$baseq3_dir" "${REQUIRED_PK3S[@]}")
    if (( ${#missing_required[@]} > 0 )); then
        find_source_baseq3 "$baseq3_dir"
    fi

    if [[ -n "$source_baseq3" ]]; then
        mapfile -t source_names < <(find "$source_baseq3" -maxdepth 1 -type f -iname "$PK3_PATTERN" -printf '%f\n' | sort)
        mapfile -t to_copy < <(get_missing_files "$baseq3_dir" "${source_names[@]}")

        for name in "${source_names[@]}"; do
            [[ -f "$baseq3_dir/$name" ]] && write_ok "$name already exists in $baseq3_dir, skipping."
        done

        if (( ${#to_copy[@]} > 0 )); then
            write_warn "${#to_copy[@]} pk3 file(s) missing from $baseq3_dir: $(join_by ', ' "${to_copy[@]}")"

            if confirm_copy "Link / copy them from $source_baseq3?"; then
                mkdir -p -- "$baseq3_dir"
                for name in "${to_copy[@]}"; do
                    add_data_file "$source_baseq3/$name" "$baseq3_dir"
                done
            else
                write_warn "Skipped copying."
            fi
        fi
    elif (( ${#missing_required[@]} > 0 )); then
        write_warn "No build baseq3 under $C_REPO_ROOT/$C_BUILD_DIR_PATTERN or $DIST_ROOT and no mounted drive's $HDD_BASEQ3_SUBPATH holds $(join_by ', ' "${REQUIRED_PK3S[@]}")."
    fi

    mapfile -t still_missing < <(get_missing_files "$baseq3_dir" "${REQUIRED_PK3S[@]}")
    if (( ${#still_missing[@]} > 0 )); then
        write_err "Required file(s) missing from $baseq3_dir: $(join_by ', ' "${still_missing[@]}")"
        if [[ -z "$source_baseq3" ]]; then
            write_err "Build the C ioq3 with its data, mount a drive with $HDD_BASEQ3_SUBPATH (under $(join_by ', ' /media /media2 /mnt/'<name>' /media/'<name>')), or copy them in by hand."
        fi
        exit 1
    fi

    write_ok "All ${#REQUIRED_PK3S[@]} required pk3 files found in $baseq3_dir."
}

# The ps1's SDL2.dll architecture check is Windows only: on Linux the system SDL2 is linked.

start_client() {
    # Runs the game from its dir in the foreground (the ps1 starts it detached and checks that
    # it did not exit at once; here its output and exit code show up in the terminal)
    local exit_code=0
    (cd "$(dirname -- "$exe_path")" && "./$CLIENT_EXE_NAME" "$@") || exit_code=$?

    if (( exit_code == 0 )); then
        write_label "The game exited (exit code 0)."
        return
    fi

    write_err "The game exited with exit code $exit_code."
    if (( exit_code == EXIT_LOADER_FAILED )); then
        write_err "$EXIT_LOADER_FAILED: it could not be started - a shared library may be missing (ldd $exe_path)."
    fi
    write_err "See the console log: $DEFAULT_HOME_DIR/$BASEQ3_DIR_NAME/qconsole.log (start with +set logfile 2)."
    exit 1
}

script_args=("$@")
if (( $# == 0 )); then
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

write_alt "ioq3-rs..."

if $opt_print_only; then
    show_launch_command
    exit 0
fi

resolve_client_exe "$REPO_ROOT"
baseq3_dir="$(dirname -- "$exe_path")/$BASEQ3_DIR_NAME"

echo

sync_baseq3 "$baseq3_dir"

gfx_build=false
test_gfx_build "$exe_path" && gfx_build=true
resolve_gfx_options "$gfx_build"
get_launch_args
if $opt_fresh; then reset_fresh_home; fi

echo

write_extra "$exe_path ${launch_args[*]}"
start_client "${launch_args[@]}"
