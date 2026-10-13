#!/usr/bin/env bash
# ioq3.sh - the bash / Linux version of ioq3.ps1: starts the newest C ioq3 build.
#
# Usage examples (args in any order, case insensitive; `.ioq3 help` lists them all):
# start like before:
# .ioq3
#
# dev map (q3dm0) in a window:
# .ioq3 dev win
#
# another map with bots, on a fresh config, writing qconsole.log:
# .ioq3 map=q3dm17 bots fresh log
#
# timedemo benchmark on renderer_opengl1:
# .ioq3 bench opengl1
#
# the QVMs instead of the game libraries, raw game args after them (from the first + arg on):
# .ioq3 qvm dev +set r_mode 6
#
# print the bash line for this run instead of running it:
# .ioq3 dev print
#
# the gfx backend args of .ioq3rs (vk, glfw, ...) are accepted but ignored: C ioq3 has no gfx

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

# When true, missing pk3 files are copied from the HDD without asking first
AUTO_COPY_DATA=false

# Build dirs are searched for these config folders; the newest ioquake3 exe wins
# (old builds: ioquake3.x86_64 in release-linux-x86_64, CMake builds: ioquake3 in Release)
REPO_ROOT="$code_root_dir/Code2/C/ioq3"
BUILD_DIR_PATTERN="build*"
CONFIG_DIR_PATTERNS=("*release*" "*relwithdebinfo*" "*debug*")
CONFIG_SEARCH_DEPTH=3
CLIENT_EXE_PATTERN="ioquake3*"
LIBRARY_PATTERN="*.so"
BUILD_TIME_FORMAT="%Y-%m-%d %H:%M:%S"
CLIENT_ARGS=(+set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0)

# Game data: <exe dir>/baseq3 needs these, copied from <any mounted drive>/2024/baseq3 when missing
BASEQ3_DIR_NAME="baseq3"
HDD_BASEQ3_SUBPATH="2024/$BASEQ3_DIR_NAME"
# The Linux stand-ins for the drive roots of the ps1 (/media/2024, /media2/2024, /mnt/new, ...)
HDD_ROOT_GLOBS=(/media /media2 /mnt/* /media/* "/run/media/${USER:-}"/*)
PK3_PATTERN="*.pk3"
REQUIRED_PK3S=(pak{0..8}.pk3)

# Launch options (show_help). The gfx ones are those of ioq3rs.sh, accepted so the same args
# work for both scripts, but ignored: the C ioq3 has no gfx renderer.
ALIAS_NAME=".ioq3"
HELP_TOKENS=(help h)
PRINT_TOKENS=(print onlyprint showcmd)
GFX_DEVICES=(gl4 gl3 gles3 vk d3d11 d3d12)
declare -A GFX_DEVICE_ALIASES=([vulkan]=vk [dx11]=d3d11 [dx12]=d3d12)
GFX_WINDOWS=(sdl glfw x11 win32)
GFX_RENDERER="gfx"
RENDERERS=(opengl1 opengl2)
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
FRESH_HOME_DIR="${TMPDIR:-/tmp}/ioq3-fresh"

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
    write_alt "ioq3 - start the newest C ioq3 build under $REPO_ROOT/$BUILD_DIR_PATTERN"
    cat <<EOF

Usage: $ALIAS_NAME [options] [+game args...]
Options are case insensitive, in any order, with or without leading dashes.

Renderer:
  $(join_by ' | ' "${RENDERERS[@]}")      cl_renderer

Starting:
  dev                    +devmap $DEV_MAP (skips the menu)
  dev=<map>, map=<map>   +devmap <map>
  bots                   +addbot $(join_by ', ' "${BOTS[@]}") (skill $BOT_SKILL) on the map (dev map if none given)
  nobots                 bot_enable 0
  connect=<address>      +connect <address> (instead of a map)
  bench                  timedemo 1 of demo four at 1920x1080, vsync / fps cap off, logfile on
  win                    windowed 800x600 (r_fullscreen 0, r_mode 4)
  qvm                    run the QVMs from the paks instead of the game libraries
  ta                     Team Arena (fs_game missionpack; needs its paks in missionpack/)
  fresh                  empty fs_homepath at $FRESH_HOME_DIR (cleared each run)
  log                    logfile 2 (qconsole.log in <home>/baseq3)

Other:
  +...                   this arg and all after it go to the game as they are
  $(join_by ' | ' "${PRINT_TOKENS[@]}")  print the bash line for this run instead of running it
  $(join_by ' | ' "${HELP_TOKENS[@]}") (also -help, --help)  this help

The gfx backend args of .ioq3rs ($(join_by ', ' "${GFX_DEVICES[@]}" "${GFX_WINDOWS[@]}" "$GFX_RENDERER")) are
accepted and ignored: the C ioq3 has no gfx renderer.

Examples:
  $ALIAS_NAME dev win
  $ALIAS_NAME map=q3dm17 bots fresh log
  $ALIAS_NAME bench opengl1
  $ALIAS_NAME qvm dev +set r_mode 6
EOF
}

read_options() {
    # Sets the opt_* launch options from the script args; exits on an unknown one. The gfx ones
    # are only collected, to be reported as ignored.
    opt_help=false; opt_print_only=false; opt_ignored_gfx=(); opt_renderer=""
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

        if in_list "$name" "${HELP_TOKENS[@]}"; then opt_help=true
        elif in_list "$name" "${PRINT_TOKENS[@]}"; then opt_print_only=true
        elif [[ -n "$name" && -n "${GFX_DEVICE_ALIASES[$name]:-}" ]] || in_list "$name" "${GFX_DEVICES[@]}" \
            || in_list "$name" "${GFX_WINDOWS[@]}" || [[ "$name" == "$GFX_RENDERER" ]]; then opt_ignored_gfx+=("$raw")
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

get_launch_args() {
    # Sets launch_args: the defaults, then the cvars of the options, then the commands
    if (( ${#opt_ignored_gfx[@]} > 0 )); then
        write_warn "C ioq3 has no gfx - ignoring the gfx arg(s): $(join_by ', ' "${opt_ignored_gfx[@]}")"
    fi

    launch_args=("${CLIENT_ARGS[@]}")
    if $opt_qvm; then launch_args+=("${QVM_ARGS[@]}"); fi
    if $opt_team_arena; then launch_args+=("${TEAM_ARENA_ARGS[@]}"); fi
    if $opt_fresh; then launch_args+=(+set fs_homepath "$FRESH_HOME_DIR"); fi
    if [[ -n "$opt_renderer" ]]; then launch_args+=(+set cl_renderer "$opt_renderer"); fi
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

find_client_builds() {
    # Every <root>/build*/**/<config>/ioquake3*, newest build first
    local search_root dir pattern
    local -a config_dir_tests=()
    for pattern in "${CONFIG_DIR_PATTERNS[@]}"; do
        (( ${#config_dir_tests[@]} > 0 )) && config_dir_tests+=(-o)
        config_dir_tests+=(-iname "$pattern")
    done

    for search_root in "$REPO_ROOT"/$BUILD_DIR_PATTERN; do
        [[ -d "$search_root" ]] || continue
        find "$search_root" -mindepth 1 -maxdepth $((CONFIG_SEARCH_DEPTH + 1)) -type d \
            \( "${config_dir_tests[@]}" \) -print0 2>/dev/null |
            while IFS= read -r -d '' dir; do
                find "$dir" -maxdepth 1 -type f -name "$CLIENT_EXE_PATTERN" ! -name "$LIBRARY_PATTERN" \
                    -perm -u+x -printf '%T@ %p\n' 2>/dev/null
            done
    done | sort -rn | cut -d' ' -f2-
}

resolve_client_exe() {
    # Sets exe_path to the newest build
    local repo_root="$1" older
    local -a builds
    if [[ ! -d "$repo_root" ]]; then
        write_err "ioq3 repo not found: $repo_root"
        exit 1
    fi

    mapfile -t builds < <(find_client_builds)
    if (( ${#builds[@]} == 0 )); then
        write_err "No $CLIENT_EXE_PATTERN was found under $repo_root/$BUILD_DIR_PATTERN in a $(join_by ' / ' "${CONFIG_DIR_PATTERNS[@]}") dir."
        exit 1
    fi

    exe_path="${builds[0]}"
    write_label "Using newest build: $exe_path"
    write_label "  built $(date -r "$exe_path" +"$BUILD_TIME_FORMAT")"

    for older in "${builds[@]:1}"; do
        write_label "  (older: $older - $(date -r "$older" +"$BUILD_TIME_FORMAT"))"
    done
}

get_missing_files() {
    # get_missing_files <dir> <file names...> - prints the names not found in dir
    local dir="$1" name
    shift
    for name in "$@"; do
        [[ -f "$dir/$name" ]] || printf '%s\n' "$name"
    done
}

find_hdd_baseq3() {
    # Sets hdd_baseq3: the first <mounted drive>/2024/baseq3 that holds every required pk3
    local root candidate
    local -a missing
    hdd_baseq3=""

    for root in "${HDD_ROOT_GLOBS[@]}"; do
        candidate="$root/$HDD_BASEQ3_SUBPATH"
        [[ -d "$candidate" ]] || continue

        mapfile -t missing < <(get_missing_files "$candidate" "${REQUIRED_PK3S[@]}")
        if (( ${#missing[@]} == 0 )); then
            write_ok "Found baseq3 data on drive: $candidate"
            hdd_baseq3="$candidate"
            return
        fi
        write_warn "$candidate is missing $(join_by ', ' "${missing[@]}") - skipping it."
    done
}

confirm_copy() {
    if [[ "$AUTO_COPY_DATA" == true ]]; then
        write_label "AUTO_COPY_DATA is set - copying without asking."
        return 0
    fi
    local answer
    read -r -p "$1 [y/N] " answer
    answer="${answer,,}"
    [[ "$answer" == "y" || "$answer" == "yes" ]]
}

sync_baseq3() {
    # Copies the HDD's missing pk3 files into baseq3 (after one confirmation), then checks
    # the required ones. Exits when a required pk3 is still missing.
    local baseq3_dir="$1" name
    local -a source_names to_copy still_missing
    find_hdd_baseq3

    if [[ -n "$hdd_baseq3" ]]; then
        mapfile -t source_names < <(find "$hdd_baseq3" -maxdepth 1 -type f -iname "$PK3_PATTERN" -printf '%f\n' | sort)
        mapfile -t to_copy < <(get_missing_files "$baseq3_dir" "${source_names[@]}")

        for name in "${source_names[@]}"; do
            [[ -f "$baseq3_dir/$name" ]] && write_ok "$name already exists in $baseq3_dir, skipping."
        done

        if (( ${#to_copy[@]} > 0 )); then
            write_warn "${#to_copy[@]} pk3 file(s) missing from $baseq3_dir: $(join_by ', ' "${to_copy[@]}")"

            if confirm_copy "Copy them from $hdd_baseq3?"; then
                mkdir -p -- "$baseq3_dir"

                for name in "${to_copy[@]}"; do
                    if cp -- "$hdd_baseq3/$name" "$baseq3_dir/"; then
                        write_ok "Copied $name -> $baseq3_dir"
                    else
                        write_err "Could not copy $hdd_baseq3/$name -> $baseq3_dir"
                    fi
                done
            else
                write_warn "Skipped copying."
            fi
        fi
    else
        write_warn "No mounted drive has a valid $HDD_BASEQ3_SUBPATH (needs $(join_by ', ' "${REQUIRED_PK3S[@]}"))."
    fi

    mapfile -t still_missing < <(get_missing_files "$baseq3_dir" "${REQUIRED_PK3S[@]}")
    if (( ${#still_missing[@]} > 0 )); then
        write_err "Required file(s) missing from $baseq3_dir: $(join_by ', ' "${still_missing[@]}")"
        if [[ -z "$hdd_baseq3" ]]; then
            write_err "Mount a drive with $HDD_BASEQ3_SUBPATH (under $(join_by ', ' /media /media2 /mnt/'<name>' /media/'<name>')) holding them, or copy them in by hand."
        fi
        exit 1
    fi

    write_ok "All ${#REQUIRED_PK3S[@]} required pk3 files found in $baseq3_dir."
}

script_args=("$@")
read_options "$@"
if $opt_help; then
    show_help
    exit 0
fi

write_alt "ioq3..."

resolve_client_exe "$REPO_ROOT"
baseq3_dir="$(dirname -- "$exe_path")/$BASEQ3_DIR_NAME"
get_launch_args

if $opt_print_only; then
    # The bash lines reproducing this run (the pk3 check is left out)
    echo
    write_extra "# $ALIAS_NAME $(format_args "${script_args[@]}")"
    if $opt_fresh; then write_extra "rm -rf -- $(format_shell_arg "$FRESH_HOME_DIR")"; fi
    write_extra "$(format_shell_arg "$exe_path") $(format_args "${launch_args[@]}")"
    exit 0
fi

echo

sync_baseq3 "$baseq3_dir"
if $opt_fresh; then reset_fresh_home; fi

echo

write_extra "$exe_path ${launch_args[*]}"
"$exe_path" "${launch_args[@]}"
