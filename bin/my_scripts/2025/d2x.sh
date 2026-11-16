#!/usr/bin/env bash
# d2x.sh - runs d2x ($code_root_dir/Code2/C/d2x: OpenDiablo2 ported to C) with the game's MPQs,
# as opend2.sh does for OpenDiablo2, and runs d2x's tools (tools/*.sh - gameplay, showcase,
# playthrough, netplay, smoke, ... - and extract_mpq), by name or from a menu.
#
# Usage examples (`.d2x help` lists every option):
# play: the main menu, from the newest Release build (the Debug build when there is none):
# .d2x
#
# start on a screen and / or a window:device pair (positional), the Debug build:
# .d2x game
# .d2x charselect glfw:vk --debug
# .d2x game:inventory -x vk
#
# heroes from another save dir, join a host, raw d2x flags after --:
# .d2x --saves ~/d2heroes
# .d2x --join 127.0.0.1
# .d2x -- -l 5 -screen mapengine:12,301
# .d2x -- -dedicated -players 4
#
# the menu - play with options, run a tool from its usage examples, build:
# .d2x menu
# .d2x -m
#
# the tools: list them, run one (a unique prefix of its name is enough, its args after it):
# .d2x tools
# .d2x tool gameplay bar --gear breath --build whirlwind --zone coldplains
# .d2x tool show nec --order random
# .d2x tool smoke -h
#
# build d2x (Release into build_release by default, Debug into build):
# .d2x build
# .d2x build debug
#
# print the command instead of running it:
# .d2x game -n
#
# The MPQ dir is --data, else D2X_DATA, else the config's MpqPath, else $HOME/Downloads/d2/d2video;
# when that one holds no MPQs, the d2 dir is looked up as opend2.sh does ($HOME/Downloads/d2,
# /mnt/new/d2, else copied from a mounted HDD's 2024/d2) and passed with -p (D2X_DATA for tools).

write_label() { printf '\033[90m%s\033[0m\n' "$1"; } # Dark gray
write_info()  { printf '\033[36m%s\033[0m\n' "$1"; } # Cyan
write_alt()   { printf '\033[35m%s\033[0m\n' "$1"; } # Magenta
write_warn()  { printf '\033[33m%s\033[0m\n' "$1"; } # Dark yellow
write_ok()    { printf '\033[32m%s\033[0m\n' "$1"; } # Green
write_err()   { printf '\033[31m%s\033[0m\n' "$1" >&2; } # Red

if [ -z "${code_root_dir:-}" ]; then
    code_root_dir="$HOME"
fi

REPO_ROOT="$code_root_dir/Code2/C/d2x"
D2X_EXE="d2x"
TOOLS_DIR="tools"
# Build dirs holding bin/d2x, by kind; the newest d2x of a kind is run
RELEASE_BUILD_DIRS=(build_release build_rel_nt)
DEBUG_BUILD_DIRS=(build build_notests)
DEFAULT_RELEASE_BUILD_DIR="build_release"
DEFAULT_DEBUG_BUILD_DIR="build"
# Sources whose change makes a build stale (warned about, not rebuilt)
SOURCE_DIRS=(src shaders)
# Command-line tools built next to d2x that the tool menu offers too
BIN_TOOLS=(extract_mpq)
# Known gfx backends, to tell a window:device pair from a screen like game:inventory
KNOWN_WINDOWS=(x11 win32 glfw sdl)
KNOWN_DEVICES=(gl3 gl4 gles3 vk d3d11 d3d12)
FALLBACK_DISPLAY=":0"

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/d2x/config.json"
DEFAULT_MPQ_DIR="$HOME/Downloads/d2/d2video"
D2_DIR_NAME="d2"
MPQ_SUBDIR="d2video"
DOWNLOADS_DIR="$HOME/Downloads"
HDD_D2_SUBPATH="2024/$D2_DIR_NAME"
SPACE_MARGIN_BYTES=$((5 * 1024 * 1024 * 1024))
# Local d2 dirs, checked in this order
DIABLO_DIRS=("$DOWNLOADS_DIR/$D2_DIR_NAME" "/mnt/new/$D2_DIR_NAME")
# HDD mount points holding 2024/d2: the roots themselves, then one level below them
HDD_ROOTS=("/media" "/media2")

usage() {
    sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed '/^$/d; s/^# \{0,1\}//'
    cat <<'EOF'

Commands (the first arg; none = play):
  menu, -m, --menu         the menu: play (with options), run a tool, build
  tools                    list the tools
  tool <name> [args]       run tools/<name>.sh (or a command-line tool: extract_mpq) with its args
  build [release|debug]    configure (once) and build d2x (default: release)
  help, -h, --help         this text

Play options:
  [screen]                 the -screen to start on (positional): game, charselect, game:inventory, ...
  [window:device]          the gfx pair (positional), e.g. glfw:vk
  -r, --release            the newest Release build (default; the Debug build when there is none)
  -D, --debug              the newest Debug build
  -b, --build-dir <dir>    this build dir instead (relative to the repo or absolute)
  -s, --screen <name>      the screen, named
  -w, --window <name>      gfx window backend
  -x, --device <name>      gfx device backend
  -d, --data <dir>         the MPQ dir (passed with -p)
  -S, --saves <dir>        heroes saved in / read from this dir (D2X_SAVES)
  -j, --join <host>        join a TCP/IP host with the first hero (D2X_JOIN, -screen game unless named)
  -l, --log-level <n>      d2x's log level (0 none .. 5 debug)
  -n, --show-cmd           print the command instead of running it
  -- <flags>               the rest goes to d2x as it is
EOF
}

human_size() { numfmt --to=iec --suffix=B "$1"; }

# Prints a command (env assignments first) the way it can be pasted into a shell
print_cmd() {
    local out="" arg
    for arg in "$@"; do out+="$(printf '%q' "$arg") "; done
    write_alt "${out% }"
}

in_list() { # in_list <value> <items...>
    local value=$1 item; shift
    for item in "$@"; do [[ $item == "$value" ]] && return 0; done
    return 1
}

ensure_display() {
    if [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]]; then
        export DISPLAY="$FALLBACK_DISPLAY"
        write_label "DISPLAY is not set - using $DISPLAY"
    fi
}

ensure_repo() {
    if [[ ! -d $REPO_ROOT ]]; then
        write_err "$REPO_ROOT does not exist (code_root_dir: $code_root_dir)."
        exit 1
    fi
    cd -- "$REPO_ROOT" || exit 1
}

# ---- builds --------------------------------------------------------------------------------

newest_exe() { # newest_exe <build dirs...> -> the newest <dir>/bin/d2x (relative to the repo)
    local best="" dir exe
    for dir in "$@"; do
        exe="$dir/bin/$D2X_EXE"
        [[ -x $exe ]] || continue
        if [[ -z $best || $exe -nt $best ]]; then best=$exe; fi
    done
    printf '%s' "$best"
}

build_type_of() { # build_type_of <build dir> -> its CMAKE_BUILD_TYPE (or "?")
    local type
    type=$(sed -n 's/^CMAKE_BUILD_TYPE:STRING=//p' "$1/CMakeCache.txt" 2>/dev/null)
    printf '%s' "${type:-?}"
}

exe_time() { date -r "$1" '+%Y-%m-%d %H:%M'; }

# Picks the d2x to run (relative path on stdout): kind release / debug, or a build dir
resolve_exe() {
    local kind=$1 build_dir=$2 exe
    if [[ -n $build_dir ]]; then
        exe="${build_dir%/}/bin/$D2X_EXE"
        [[ -x $exe ]] || { write_err "$exe does not exist. Build it first (.d2x build)."; return 1; }
    elif [[ $kind == debug ]]; then
        exe=$(newest_exe "${DEBUG_BUILD_DIRS[@]}")
        [[ -n $exe ]] || { write_err "No Debug build of d2x (${DEBUG_BUILD_DIRS[*]}). Build it first: .d2x build debug"; return 1; }
    else
        exe=$(newest_exe "${RELEASE_BUILD_DIRS[@]}")
        if [[ -z $exe ]]; then
            exe=$(newest_exe "${DEBUG_BUILD_DIRS[@]}")
            [[ -n $exe ]] || { write_err "No build of d2x yet. Build it first: .d2x build"; return 1; }
            write_warn "No Release build (${RELEASE_BUILD_DIRS[*]}) - running the Debug build. .d2x build makes one." >&2
        fi
    fi
    local changed
    changed=$(find "${SOURCE_DIRS[@]}" -type f -newer "$exe" -print -quit 2>/dev/null)
    if [[ -n $changed ]]; then
        write_warn "$exe is older than $changed - rebuild with: .d2x build $( [[ $(build_type_of "${exe%/bin/*}") == Release ]] && echo release || echo debug)" >&2
    fi
    printf '%s' "$exe"
}

build_d2x() { # build_d2x [release|debug|<build dir>]
    local which=${1:-release} dir type
    case ${which,,} in
        release|r) dir=$DEFAULT_RELEASE_BUILD_DIR; type=Release ;;
        debug|d)   dir=$DEFAULT_DEBUG_BUILD_DIR;   type=Debug ;;
        *)         dir=${which%/}; type=$(build_type_of "$dir"); [[ $type == "?" ]] && type=Debug ;;
    esac
    if [[ ! -f $dir/CMakeCache.txt ]]; then
        write_info "Configuring $dir ($type)..."
        print_cmd cmake -S . -B "$dir" -DCMAKE_BUILD_TYPE="$type"
        cmake -S . -B "$dir" -DCMAKE_BUILD_TYPE="$type" || { write_err "Configuring $dir failed."; return 1; }
    fi
    write_info "Building $D2X_EXE in $dir ($type)..."
    print_cmd cmake --build "$dir" -j"$(nproc)" --target "$D2X_EXE"
    if cmake --build "$dir" -j"$(nproc)" --target "$D2X_EXE"; then
        write_ok "Built $dir/bin/$D2X_EXE"
    else
        write_err "Building $dir failed."
        return 1
    fi
}

# ---- game data -----------------------------------------------------------------------------

has_mpqs() { compgen -G "$1/*.[mM][pP][qQ]" >/dev/null 2>&1; }

config_mpq_path() { # the MpqPath of a config.json (the exe dir's wins over the user's)
    local file
    for file in "$@" "$CONFIG_FILE"; do
        [[ -f $file ]] || continue
        sed -n 's/.*"MpqPath": *"\([^"]*\)".*/\1/p' "$file" | head -n 1
        return 0
    done
}

# Finds the d2 dir as opend2.sh does - a local one, else a copy from a mounted HDD - and prints
# its MPQ dir
find_d2_mpq_dir() {
    local dir d2_dir=""
    for dir in "${DIABLO_DIRS[@]}"; do
        if has_mpqs "$dir/$MPQ_SUBDIR"; then d2_dir=$dir; break; fi
    done

    if [[ -z $d2_dir ]]; then
        write_warn "No local Diablo 2 directory found (checked: ${DIABLO_DIRS[*]}). Looking on mounted HDDs..." >&2
        local hdd_candidates=() root hdd_d2_dir=""
        shopt -s nullglob
        for root in "${HDD_ROOTS[@]}"; do
            hdd_candidates+=("$root/$HDD_D2_SUBPATH" "$root"/*/"$HDD_D2_SUBPATH")
        done
        hdd_candidates+=("/media/$USER"/*/"$HDD_D2_SUBPATH")
        shopt -u nullglob
        for dir in "${hdd_candidates[@]}"; do
            if [[ -d $dir ]]; then hdd_d2_dir=$dir; break; fi
        done
        if [[ -z $hdd_d2_dir ]]; then
            write_err "No Diablo 2 directory found locally (${DIABLO_DIRS[*]}) or on a mounted HDD (${HDD_ROOTS[*]} [/<drive>]/$HDD_D2_SUBPATH)."
            return 1
        fi

        mkdir -p "$DOWNLOADS_DIR"
        local d2_size free_space needed_space
        d2_size=$(du -sb "$hdd_d2_dir" | cut -f1)
        free_space=$(df -B1 --output=avail "$DOWNLOADS_DIR" | tail -n 1 | tr -d ' ')
        needed_space=$((d2_size + SPACE_MARGIN_BYTES))
        write_label "Found $hdd_d2_dir ($(human_size "$d2_size")). Free in $DOWNLOADS_DIR: $(human_size "$free_space"), needed (+$(human_size "$SPACE_MARGIN_BYTES") margin): $(human_size "$needed_space")" >&2
        if (( free_space < needed_space )); then
            write_err "Not enough disk space to copy $hdd_d2_dir into $DOWNLOADS_DIR."
            return 1
        fi

        # Copy into a temporary dir first, so an interrupted copy never looks like a complete d2 dir
        d2_dir="$DOWNLOADS_DIR/$D2_DIR_NAME"
        local partial_dir="$d2_dir.partial"
        if [[ -e $d2_dir ]]; then
            write_err "$d2_dir exists but holds no MPQs in $MPQ_SUBDIR - not overwriting it."
            return 1
        fi
        if [[ -d $partial_dir ]]; then
            write_warn "Removing the leftover $partial_dir of an interrupted copy" >&2
            rm -rf "$partial_dir"
        fi
        write_info "Copying $hdd_d2_dir into $d2_dir..." >&2
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --info=progress2 "$hdd_d2_dir/" "$partial_dir/" >&2 || return 1
        else
            cp -a "$hdd_d2_dir" "$partial_dir" || return 1
        fi
        mv "$partial_dir" "$d2_dir" || return 1
        write_ok "Copied $hdd_d2_dir into $d2_dir" >&2
    fi
    printf '%s' "$d2_dir/$MPQ_SUBDIR"
}

# Sets MPQ_DIR to the MPQ dir to use and MPQ_DIR_FOUND=true when d2x / the tools would not find
# it on their own. Args: the dir asked for (or empty), the exe (for its config.json), the mode
# (play: d2x reads the config too; tools: D2X_DATA or the default only)
resolve_mpq_dir() {
    local asked=$1 exe=$2 mode=$3 effective
    MPQ_DIR_FOUND=false
    if [[ -n $asked ]]; then
        MPQ_DIR=$asked; MPQ_DIR_FOUND=true
        has_mpqs "$MPQ_DIR" || write_warn "$MPQ_DIR holds no MPQs."
        return 0
    fi
    if [[ -n ${D2X_DATA:-} ]]; then
        effective=$D2X_DATA
    elif [[ $mode == play ]]; then
        effective=$(config_mpq_path "${exe:+$(dirname "$exe")/config.json}")
        effective=${effective:-$DEFAULT_MPQ_DIR}
    else
        effective=$DEFAULT_MPQ_DIR
    fi
    effective=${effective%/}
    if has_mpqs "$effective"; then
        MPQ_DIR=$effective
        return 0
    fi
    write_warn "No MPQs in $effective - looking for the Diablo 2 directory..."
    MPQ_DIR=$(find_d2_mpq_dir) || return 1
    MPQ_DIR_FOUND=true
    write_label "Using the MPQs in $MPQ_DIR"
}

# ---- play ----------------------------------------------------------------------------------

is_pair() { # is_pair <window:device>
    [[ $1 == *:* ]] || return 1
    in_list "${1%%:*}" "${KNOWN_WINDOWS[@]}" && in_list "${1#*:}" "${KNOWN_DEVICES[@]}"
}

# Builds the play command into PLAY_ENV / PLAY_CMD from the play options
build_play_cmd() {
    local kind=release build_dir="" screen="" window="" device="" data="" saves="" join="" log_level=""
    local extra=()
    while (( $# )); do
        case $1 in
            -r|--release)   kind=release ;;
            -D|--debug)     kind=debug ;;
            -b|--build-dir) build_dir=$2; shift ;;
            -s|--screen)    screen=$2; shift ;;
            -w|--window)    window=$2; shift ;;
            -x|--device)    device=$2; shift ;;
            -d|--data)      data=$2; shift ;;
            -S|--saves)     saves=$2; shift ;;
            -j|--join)      join=$2; shift ;;
            -l|--log-level) log_level=$2; shift ;;
            -n|--show-cmd)  SHOW_CMD=true ;;
            --)             shift; extra=("$@"); break ;;
            -*)             write_err "unknown option: $1 (.d2x help lists them)"; return 2 ;;
            *)
                if is_pair "$1"; then
                    window=${1%%:*}; device=${1#*:}
                elif [[ -z $screen ]]; then
                    screen=$1
                else
                    write_err "unexpected arg: $1 (the screen is $screen already)"; return 2
                fi ;;
        esac
        shift
    done

    local exe
    exe=$(resolve_exe "$kind" "$build_dir") || return 1
    resolve_mpq_dir "$data" "$exe" play || return 1

    PLAY_ENV=()
    [[ -n $saves ]] && PLAY_ENV+=("D2X_SAVES=$saves")
    if [[ -n $join ]]; then
        PLAY_ENV+=("D2X_JOIN=$join")
        screen=${screen:-game}
    fi
    PLAY_CMD=("./$exe")
    [[ $MPQ_DIR_FOUND == true ]] && PLAY_CMD+=(-p "$MPQ_DIR")
    [[ -n $window ]] && PLAY_CMD+=(-w "$window")
    [[ -n $device ]] && PLAY_CMD+=(-x "$device")
    [[ -n $log_level ]] && PLAY_CMD+=(-l "$log_level")
    [[ -n $screen ]] && PLAY_CMD+=(-screen "$screen")
    PLAY_CMD+=("${extra[@]}")
}

play() {
    SHOW_CMD=false
    build_play_cmd "$@" || return $?
    if [[ $SHOW_CMD == true ]]; then
        print_cmd "${PLAY_ENV[@]}" "${PLAY_CMD[@]}"
        return 0
    fi
    ensure_display
    write_label "Running: $(print_cmd "${PLAY_ENV[@]}" "${PLAY_CMD[@]}")"
    env "${PLAY_ENV[@]}" "${PLAY_CMD[@]}"
}

# ---- tools ---------------------------------------------------------------------------------

tool_names() { # the tools: tools/*.sh, then the command-line tools built
    local file name
    for file in "$TOOLS_DIR"/*.sh; do
        name=${file##*/}; printf '%s\n' "${name%.sh}"
    done
    for name in "${BIN_TOOLS[@]}"; do
        [[ -n $(bin_tool_path "$name") ]] && printf '%s\n' "$name"
    done
}

bin_tool_path() { # the newest build's <dir>/bin/<name>
    newest_exe_named "$1" "${DEBUG_BUILD_DIRS[@]}" "${RELEASE_BUILD_DIRS[@]}"
}

newest_exe_named() { # newest_exe_named <name> <build dirs...>
    local name=$1 best="" dir exe; shift
    for dir in "$@"; do
        exe="$dir/bin/$name"
        [[ -x $exe ]] || continue
        if [[ -z $best || $exe -nt $best ]]; then best=$exe; fi
    done
    printf '%s' "$best"
}

tool_summary() { # one line about a tool: its header's first line
    local name=$1 line
    if [[ -f $TOOLS_DIR/$name.sh ]]; then
        line=$(sed -n '2s/^# *\(d2x: *\)\{0,1\}//p' "$TOOLS_DIR/$name.sh")
    else
        line="extracts or lists an MPQ archive (build/bin)"
    fi
    (( ${#line} > 90 )) && line="${line:0:87}..."
    printf '%s' "$line"
}

resolve_tool() { # resolve_tool <name or unique prefix> -> the tool's name
    local want=${1,,} name matches=()
    while read -r name; do
        [[ ${name,,} == "$want" ]] && { printf '%s' "$name"; return 0; }
        [[ ${name,,} == "$want"* ]] && matches+=("$name")
    done < <(tool_names)
    if (( ${#matches[@]} == 1 )); then
        printf '%s' "${matches[0]}"
        return 0
    fi
    if (( ${#matches[@]} > 1 )); then
        write_err "\"$1\" names several tools: ${matches[*]}"
    else
        write_err "No tool \"$1\". The tools: $(tool_names | tr '\n' ' ')"
    fi
    return 1
}

tool_cmd_prefix() { # how a tool is run, relative to the repo
    if [[ -f $TOOLS_DIR/$1.sh ]]; then
        printf '%s' "$TOOLS_DIR/$1.sh"
    else
        bin_tool_path "$1"
    fi
}

list_tools() {
    write_info "d2x tools (.d2x tool <name> [args]; <name> -h for its options):"
    local name
    while read -r name; do
        printf '  \033[32m%-18s\033[0m %s\n' "$name" "$(tool_summary "$name")"
    done < <(tool_names)
}

# Exports what the tools need: a display, and D2X_DATA when the MPQs are not where they look
prepare_tool_env() {
    ensure_display
    resolve_mpq_dir "" "" tools || return 1
    if [[ $MPQ_DIR_FOUND == true && -z ${D2X_DATA:-} ]]; then
        export D2X_DATA="$MPQ_DIR"
        write_label "D2X_DATA=$D2X_DATA"
    fi
}

run_tool() { # run_tool <name> [args...]
    local name
    name=$(resolve_tool "$1") || return 1
    shift
    local prefix
    prefix=$(tool_cmd_prefix "$name")
    # Help and --show-cmd need no game data or display
    local arg needs_env=true
    for arg in "$@"; do
        case $arg in -h|--help|-n|--show-cmd|list) needs_env=false ;; esac
    done
    if [[ $needs_env == true ]]; then
        prepare_tool_env || return 1
    fi
    write_label "Running: $(print_cmd "$prefix" "$@")"
    if [[ $prefix == *.sh ]]; then
        bash "$prefix" "$@"
    else
        "./$prefix" "$@"
    fi
}

# A tool's usage examples as "<command><TAB><what it does>" lines: from the comment block at the
# top of a tools/*.sh (the "Usage examples:" part), from the -h text's "Examples:" of a binary
tool_examples() {
    local name=$1 desc="" line in_examples=false
    if [[ -f $TOOLS_DIR/$name.sh ]]; then
        while IFS= read -r line; do
            [[ $line == "#!"* ]] && continue
            [[ $line == "#"* ]] || break
            line=${line#\#}; line=${line# }
            if [[ $line == "Usage examples:"* ]]; then in_examples=true; continue; fi
            [[ $in_examples == true ]] || continue
            if [[ $line =~ ^[[:space:]]+(tools/[^[:space:]]+\.sh.*)$ ]]; then
                printf '%s\t%s\n' "${BASH_REMATCH[1]}" "$desc"
            elif [[ $line =~ ^[[:space:]]+[A-Z0-9_]+=.* ]]; then
                printf '%s\t%s\n' "${line#"${line%%[![:space:]]*}"}" "$desc"
            elif [[ -n $line && $line != [[:space:]]* ]]; then
                desc=${line%:}
            fi
        done < "$TOOLS_DIR/$name.sh"
    else
        # The examples name a bare archive: point them at the MPQ dir
        local exe mpq_dir=${D2X_DATA:-$DEFAULT_MPQ_DIR} cmd
        exe=$(bin_tool_path "$name")
        "./$exe" -h 2>&1 | while IFS= read -r line; do
            if [[ $line == "Examples:"* ]]; then in_examples=true; continue; fi
            [[ $in_examples == true && $line =~ ^[[:space:]]+(.+)$ ]] || continue
            cmd=$(sed -E "s# ([A-Za-z0-9_]+\.mpq)# $(printf '%q' "$mpq_dir")/\1#" <<<"${BASH_REMATCH[1]}")
            printf '%s\t%s\n' "$cmd" "example"
        done
    fi
}

# ---- menu ----------------------------------------------------------------------------------

USE_FZF=false
command -v fzf >/dev/null 2>&1 && USE_FZF=true

# pick <prompt> <items...> -> the chosen item on stdout; status 1 when cancelled (Esc / q).
# Items may hold a TAB: the part after it is shown dimmed (fzf) or in parentheses
pick() {
    local prompt=$1; shift
    (( $# )) || return 1
    if [[ $USE_FZF == true ]]; then
        local item shown=()
        for item in "$@"; do
            if [[ $item == *$'\t'* ]]; then
                shown+=("${item%%$'\t'*}"$'\t'$'\033[90m'"${item#*$'\t'}"$'\033[0m')
            else
                shown+=("$item")
            fi
        done
        printf '%s\n' "${shown[@]}" | fzf --ansi --prompt="$prompt> " --height=60% --reverse \
            --no-multi --tiebreak=index --delimiter=$'\t' --tabstop=4 "${PICK_FZF_ARGS[@]}" \
            | sed $'s/\033\\[[0-9;]*m//g' | sed $'s/\t.*$//' | grep . || return 1
    else
        local item labels=() i choice
        for item in "$@"; do
            if [[ $item == *$'\t'* ]]; then labels+=("${item%%$'\t'*}  (${item#*$'\t'})"); else labels+=("$item"); fi
        done
        while true; do
            printf '\033[36m%s\033[0m\n' "$prompt:" >&2
            for i in "${!labels[@]}"; do printf '  %2d) %s\n' "$((i + 1))" "${labels[$i]}" >&2; done
            read -r -p "number (q to go back): " choice || return 1
            [[ $choice == q || -z $choice ]] && return 1
            if [[ $choice =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= $# )); then
                item=${!choice}
                printf '%s\n' "${item%%$'\t'*}"
                return 0
            fi
        done
    fi
}
PICK_FZF_ARGS=()

# Shows a command line to edit (Enter runs it, an empty line goes back), then runs it in the repo
edit_and_run() {
    local line=$1
    write_info "Edit the command - Enter runs it, an empty line goes back:"
    read -e -r -i "$line" -p "$ " line || return 1
    [[ -z ${line//[[:space:]]/} ]] && return 1
    write_label "Running: $line"
    ( cd -- "$REPO_ROOT" && eval "$line" )
    local status=$?
    if (( status == 0 )); then write_ok "Done."; else write_warn "Exited with status $status."; fi
    return 0
}

screens_of() { # the -screen / capture scene names a d2x lists
    "$1" -C list 2>/dev/null | sed -n 's/^  \([a-z_][a-z_0-9]*\) .*/\1/p'
}

pairs_of() { # the window:device pairs a d2x was built with
    local help windows devices w d
    help=$("$1" -h 2>&1)
    windows=$(sed -n 's/^ *windows: *//p' <<<"$help")
    devices=$(sed -n 's/^ *devices: *//p' <<<"$help")
    for w in $windows; do for d in $devices; do printf '%s:%s\n' "$w" "$d"; done; done
}

menu_play_options() {
    local items=() dir exe type choice
    for dir in "${RELEASE_BUILD_DIRS[@]}" "${DEBUG_BUILD_DIRS[@]}"; do
        exe="$dir/bin/$D2X_EXE"
        [[ -x $exe ]] || continue
        items+=("$dir"$'\t'"$(build_type_of "$dir"), built $(exe_time "$exe")")
    done
    (( ${#items[@]} )) || { write_err "No build of d2x yet - build it first."; return 1; }
    local build_dir
    build_dir=$(pick "Build" "${items[@]}") || return 1
    exe="$build_dir/bin/$D2X_EXE"

    local pair
    mapfile -t items < <(pairs_of "./$exe")
    pair=$(pick "Window:device" "default"$'\t'"D2X_GFX_WINDOW / D2X_GFX_DEVICE, else x11:gl4" "${items[@]}") || return 1

    local screen
    mapfile -t items < <(screens_of "./$exe")
    screen=$(pick "Screen (game:<panel> and more: edit the command)" "mainmenu"$'\t'"the default: the trademark screen, then the main menu" "${items[@]}") || return 1

    local saves
    choice=$(pick "Heroes" "default"$'\t'"${CONFIG_FILE%/config.json}/Saves" "another directory"$'\t'"D2X_SAVES") || return 1
    if [[ $choice == "another directory" ]]; then
        read -e -r -p "save directory: " saves || return 1
    fi

    local args=(-b "$build_dir")
    [[ $pair != default ]] && args+=("$pair")
    [[ $screen != mainmenu ]] && args+=(-s "$screen")
    [[ -n $saves ]] && args+=(-S "$saves")
    SHOW_CMD=false
    build_play_cmd "${args[@]}" || return 1
    ensure_display
    edit_and_run "$(print_cmd "${PLAY_ENV[@]}" "${PLAY_CMD[@]}" | sed $'s/\033\\[[0-9;]*m//g')"
}

menu_quick_play() { # menu_quick_play [play args...]: the default build, the command shown to edit
    SHOW_CMD=false
    build_play_cmd "$@" || return 1
    ensure_display
    edit_and_run "$(print_cmd "${PLAY_ENV[@]}" "${PLAY_CMD[@]}" | sed $'s/\033\\[[0-9;]*m//g')"
}

menu_tool() {
    local items=() name
    while read -r name; do items+=("$name"$'\t'"$(tool_summary "$name")"); done < <(tool_names)
    PICK_FZF_ARGS=(--preview "f=$(printf '%q' "$REPO_ROOT/$TOOLS_DIR")/{1}.sh; [ -f \"\$f\" ] && sed -n '2,/^[^#]/p' \"\$f\" | sed 's/^# \\{0,1\\}//' | head -n 200" --preview-window=right,55%,wrap)
    name=$(pick "Tool" "${items[@]}")
    local status=$?
    PICK_FZF_ARGS=()
    (( status == 0 )) || return 1

    local prefix
    prefix=$(tool_cmd_prefix "$name")
    while true; do
        local examples=() choice
        mapfile -t examples < <(tool_examples "$name")
        choice=$(pick "$name" "(your own args)"$'\t'"$prefix ..." "(help)"$'\t'"$prefix -h" "${examples[@]}") || return 0
        case $choice in
            "(help)")
                if [[ $prefix == *.sh ]]; then bash "$prefix" -h; else "./$prefix" -h; fi 2>&1 | less -RFX
                continue ;;
            "(your own args)")
                choice="$prefix " ;;
        esac
        prepare_tool_env || return 1
        edit_and_run "$choice"
    done
}

menu_build() {
    local choice
    choice=$(pick "Build" \
        "release"$'\t'"Release into $DEFAULT_RELEASE_BUILD_DIR (fast, for playing)" \
        "debug"$'\t'"Debug into $DEFAULT_DEBUG_BUILD_DIR (what the tools use by default)") || return 1
    build_d2x "$choice"
}

menu() {
    if [[ ! -t 0 ]]; then
        write_err "The menu needs a terminal."
        return 1
    fi
    [[ $USE_FZF == true ]] || write_label "fzf is not installed - a numbered menu instead."
    local choice
    while true; do
        choice=$(pick "d2x" \
            "Play"$'\t'"the main menu, the newest Release build" \
            "Play: the first hero"$'\t'"-screen game" \
            "Play: character select"$'\t'"-screen charselect" \
            "Play with options"$'\t'"build, window:device, screen, save directory" \
            "Dedicated server"$'\t'"-dedicated, no window (TCP/IP port 6669)" \
            "Run a tool"$'\t'"gameplay, showcase, playthrough, netplay, smoke, capture, tests, ... from their usage examples" \
            "Build d2x"$'\t'"Release or Debug" \
            "Quit") || return 0
        case $choice in
            "Play")                   menu_quick_play ;;
            "Play: the first hero")   menu_quick_play -s game ;;
            "Play: character select") menu_quick_play -s charselect ;;
            "Play with options")      menu_play_options ;;
            "Dedicated server")       menu_quick_play -- -dedicated -players 8 ;;
            "Run a tool")             menu_tool ;;
            "Build d2x")              menu_build ;;
            "Quit")                   return 0 ;;
        esac
        echo
    done
}

# ---- main ----------------------------------------------------------------------------------

ensure_repo

case ${1:-} in
    menu|-m|--menu)  menu ;;
    tools)           list_tools ;;
    tool|t)
        shift
        if (( $# == 0 )); then list_tools; exit 0; fi
        run_tool "$@" ;;
    build)           shift; build_d2x "$@" ;;
    help|-h|--help)  usage ;;
    *)               play "$@" ;;
esac
