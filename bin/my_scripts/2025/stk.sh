#!/usr/bin/env bash
# stk.sh - starts the newest SuperTuxKart build of the stk-code checkout (build*/**/supertuxkart),
# from the repo root, where it finds data/ (and ../stk-assets through it).
#
# Usage examples (nothing runs without `run` as the first arg; the args after it in any order,
# case insensitive; `.stk help` lists them all):
# cd into the repo and print how to run it, through this script and by hand (runs nothing):
# .stk
#
# the newest build, at the menu:
# .stk run
#
# a race right away on lighthouse as tux, 3 laps, windowed at 1600x900:
# .stk run now track=lighthouse kart=tux laps=3 win size=1600x900
#
# a time trial on expert, skipping ready-set-go and the music:
# .stk run race mode=tt difficulty=expert track=zengarden
#
# the benchmark on graphics preset 7, from build-debug, built first:
# .stk run bench preset=7 tree=build-debug build
#
# any supertuxkart arg as it is (a dashed arg the script does not know, or all after --):
# .stk run --enable-ssao --seed=42 -- --server-password=secret
#
# print the bash line for this run instead of running it:
# .stk run now track=lighthouse print

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

# The checkout: the first of these that exists (stk/stk-code is the Windows layout)
REPO_ROOT_CANDIDATES=("$code_root_dir/Code2/C++/stk-code" "$code_root_dir/Code2/C++/stk/stk-code")
REPO_ROOT="${REPO_ROOT_CANDIDATES[0]}"
for repo_candidate in "${REPO_ROOT_CANDIDATES[@]}"; do
    if [[ -d "$repo_candidate" ]]; then REPO_ROOT="$repo_candidate"; break; fi
done
# Build dirs are searched this deep for the exe (build/bin/supertuxkart, a multi-config
# generator's build/bin/<Config>/supertuxkart); the newest one wins
BUILD_DIR_PATTERN="build*"
EXE_SEARCH_DEPTH=3
CLIENT_EXE_NAME="supertuxkart"
BUILD_TIME_FORMAT="%Y-%m-%d %H:%M:%S"

# A bare call cds into the repo and prints how to run it (show_usage), running nothing. The cd
# only reaches the calling shell when the script is sourced (the .zshrc alias sources it for a
# bare call), so a sourced script prints through a bash run of itself and returns here, before
# the bash-only code below
if (( $# == 0 )) && (return 0 2>/dev/null); then
    cd -- "$REPO_ROOT" || return 1
    bash "${BASH_SOURCE[0]:-$0}"
    return 0
fi

# `build` builds the exe's build dir (tree= when given, else build/, configured when missing)
DEFAULT_BUILD_DIR="build"
CMAKE_CACHE_NAME="CMakeCache.txt"
CONFIGURE_ARGS=(-DCMAKE_BUILD_TYPE=Release)
BUILD_JOBS="$(nproc 2>/dev/null || echo 4)"

# stk takes data/ from the current dir first and its assets from data/../../<one of these>,
# unless SUPERTUXKART_DATADIR / SUPERTUXKART_ASSETS_DIR say otherwise
ASSETS_DIR_NAMES=(stk-assets supertuxkart-assets)
ASSETS_SVN_URL="https://svn.code.sf.net/p/supertuxkart/code/stk-assets"
# Where stk writes its config and stdout.log
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/supertuxkart/config-0.10"
# Exit code of a process the loader could not start (e.g. a missing shared library)
EXIT_LOADER_FAILED=127

# Launch options (show_help)
ALIAS_NAME=".stk"
RUN_COMMAND="run"
HELP_TOKENS=(help h)
PRINT_TOKENS=(print onlyprint showcmd)
OPTION_VALUE_SEPARATOR="="
PASSTHROUGH_PREFIX="-"
PASSTHROUGH_ALL="--"
# --mode= / --difficulty= take the index of these names
MODE_NAMES=(normal tt battle soccer ftl ctf)
DIFFICULTY_NAMES=(beginner intermediate expert supertux)

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

format_named_indexes() {
    # format_named_indexes <names...> - "name (0) | name (1) | ..."
    local i
    local -a items=() names=("$@")
    for i in "${!names[@]}"; do items+=("${names[$i]} ($i)"); done
    join_by ' | ' "${items[@]}"
}

show_help() {
    write_alt "stk - start the newest SuperTuxKart build under $REPO_ROOT/$BUILD_DIR_PATTERN"
    cat <<EOF

Usage: $ALIAS_NAME $RUN_COMMAND [options] [-supertuxkart args...] [$PASSTHROUGH_ALL supertuxkart args...]
Nothing runs without $RUN_COMMAND as the first arg; a bare $ALIAS_NAME cds into the repo and prints how to run it.
Options are case insensitive, in any order, with or without leading dashes.

Build (default: the newest $CLIENT_EXE_NAME under $BUILD_DIR_PATTERN/, $EXE_SEARCH_DEPTH levels deep):
  tree=<dir>             the newest one in this build dir instead (relative to the repo, or absolute)
  build                  build that dir first (cmake --build; $DEFAULT_BUILD_DIR/ is configured when missing)

Window:
  win, windowed          --windowed
  full, fullscreen       --fullscreen
  size=<W>x<H>           --screensize=<W>x<H>
  preset=<1-7>           --gfx-preset=<n> (the graphics settings preset)

Race:
  now                    -N: start a race right away, no menu
  race                   -R: like now, also skipping ready-set-go and the music
  track=<name>           --track=<name> (a dir name in stk-assets/tracks)
  gp=<name>              --gp=<name> (a Grand Prix)
  kart=<name>            --kart=<name> (a dir name in stk-assets/karts)
  karts=<n>              --numkarts=<n>
  laps=<n>               --laps=<n>
  reverse                --reverse
  mode=<name|n>          --mode: $(format_named_indexes "${MODE_NAMES[@]}")
  difficulty=<name|n>    --difficulty: $(format_named_indexes "${DIFFICULTY_NAMES[@]}")
  unlock                 --unlock-all (saved in the config)

Network:
  connect=<ip[:port]>    --connect-now=<ip[:port]>
  lan=<name>             --lan-server=<name> (hosts a LAN server instead of playing)

Other:
  bench                  --benchmark (saves the results and exits)
  log=<0-5>              --log=<n> (0 debug .. 5 only fatal)
  version                -v
  -...                   any other dashed arg goes to supertuxkart as it is ($ALIAS_NAME $RUN_COMMAND $PASSTHROUGH_ALL --help lists them)
  $PASSTHROUGH_ALL                     all args after it go to supertuxkart as they are
  $(join_by ' | ' "${PRINT_TOKENS[@]}")  print the bash line for this run instead of running it
  $(join_by ' | ' "${HELP_TOKENS[@]}") (also -help, --help)  this help

It runs from the repo root (data/ there, the assets in ../$(join_by ' or ../' "${ASSETS_DIR_NAMES[@]}"));
its config and stdout.log are in $CONFIG_DIR.

Examples:
  $ALIAS_NAME $RUN_COMMAND now track=lighthouse kart=tux laps=3 win
  $ALIAS_NAME $RUN_COMMAND race mode=tt difficulty=expert track=zengarden
  $ALIAS_NAME $RUN_COMMAND bench preset=7 build
  $ALIAS_NAME $RUN_COMMAND --enable-ssao $PASSTHROUGH_ALL --seed=42

EOF
    show_manual_run
}

show_usage() {
    # A bare call: how to run stk from the repo, through this script and by hand
    write_alt "stk - $REPO_ROOT"
    write_label "Run it through this script (the options after $RUN_COMMAND; '$ALIAS_NAME help' lists them):"
    write_extra "$ALIAS_NAME $RUN_COMMAND"
    show_manual_run
}

show_manual_run() {
    # Prints how to start the newest build by hand, without this script
    local exe
    exe="$(find_client_builds "$REPO_ROOT"/$BUILD_DIR_PATTERN | head -n 1)"
    if [[ -z "$exe" ]]; then
        write_warn "No $CLIENT_EXE_NAME built under $REPO_ROOT/$BUILD_DIR_PATTERN yet - build it (from $REPO_ROOT):"
        write_extra "cmake -B $DEFAULT_BUILD_DIR ${CONFIGURE_ARGS[*]} && cmake --build $DEFAULT_BUILD_DIR --target $CLIENT_EXE_NAME --parallel \$(nproc)"
        return
    fi
    write_label "Or run it manually (from $REPO_ROOT, the newest build; it finds data/ from there):"
    write_extra "./${exe#"$REPO_ROOT/"}"
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

resolve_named_index() {
    # resolve_named_index <arg> <value> <names...> - sets named_index: the index of the value in the
    # names (a name, any case, or the index itself); exits on any other value
    local raw="$1" value="${2,,}" i
    shift 2
    local -a names=("$@")
    if [[ "$value" =~ ^[0-9]+$ ]] && (( 10#$value < ${#names[@]} )); then
        named_index=$((10#$value))
        return
    fi
    for i in "${!names[@]}"; do
        if [[ "${names[$i]}" == "$value" ]]; then
            named_index="$i"
            return
        fi
    done
    write_err "Unknown value: $raw (one of $(join_by ' / ' "${names[@]}"), or 0-$(( ${#names[@]} - 1 )))."
    exit 1
}

read_options() {
    # Sets the opt_* launch options from the script args; exits on an unknown one. opt_stk holds
    # the supertuxkart args of the options, opt_extra the ones passed as they are (after them)
    opt_help=false; opt_print_only=false; opt_tree=""; opt_build=false
    opt_stk=(); opt_extra=()

    local raw name value
    while (( $# > 0 )); do
        raw="$1"
        if [[ "$raw" == "$PASSTHROUGH_ALL" ]]; then
            shift
            opt_extra+=("$@")
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
        elif [[ "$name" == "tree" && -n "$value" ]]; then opt_tree="$value"
        elif [[ "$name" == "build" ]]; then opt_build=true
        elif [[ "$name" == "win" || "$name" == "windowed" ]]; then opt_stk+=(--windowed)
        elif [[ "$name" == "full" || "$name" == "fullscreen" ]]; then opt_stk+=(--fullscreen)
        elif [[ "$name" == "size" && -n "$value" ]]; then opt_stk+=("--screensize=$value")
        elif [[ "$name" == "preset" && -n "$value" ]]; then opt_stk+=("--gfx-preset=$value")
        elif [[ "$name" == "now" ]]; then opt_stk+=(-N)
        elif [[ "$name" == "race" ]]; then opt_stk+=(-R)
        elif [[ "$name" == "track" && -n "$value" ]]; then opt_stk+=("--track=$value")
        elif [[ "$name" == "gp" && -n "$value" ]]; then opt_stk+=("--gp=$value")
        elif [[ "$name" == "kart" && -n "$value" ]]; then opt_stk+=("--kart=$value")
        elif [[ "$name" == "karts" && -n "$value" ]]; then opt_stk+=("--numkarts=$value")
        elif [[ "$name" == "laps" && -n "$value" ]]; then opt_stk+=("--laps=$value")
        elif [[ "$name" == "reverse" ]]; then opt_stk+=(--reverse)
        elif [[ "$name" == "mode" && -n "$value" ]]; then
            resolve_named_index "$raw" "$value" "${MODE_NAMES[@]}"
            opt_stk+=("--mode=$named_index")
        elif [[ "$name" == "difficulty" && -n "$value" ]]; then
            resolve_named_index "$raw" "$value" "${DIFFICULTY_NAMES[@]}"
            opt_stk+=("--difficulty=$named_index")
        elif [[ "$name" == "unlock" ]]; then opt_stk+=(--unlock-all)
        elif [[ "$name" == "connect" && -n "$value" ]]; then opt_stk+=("--connect-now=$value")
        elif [[ "$name" == "lan" && -n "$value" ]]; then opt_stk+=("--lan-server=$value")
        elif [[ "$name" == "bench" ]]; then opt_stk+=(--benchmark)
        elif [[ "$name" == "log" && -n "$value" ]]; then opt_stk+=("--log=$value")
        elif [[ "$name" == "version" ]]; then opt_stk+=(-v)
        elif [[ "$raw" == "$PASSTHROUGH_PREFIX"* ]]; then opt_extra+=("$raw")
        else
            write_err "Unknown arg: $raw (tree= / size= / preset= / track= / gp= / kart= / karts= / laps= / mode= / difficulty= / connect= / lan= / log= need a value) - see '$ALIAS_NAME help'."
            exit 1
        fi
        shift
    done
}

find_client_builds() {
    # find_client_builds <dirs...> - every <dir>/**/supertuxkart, newest first
    local search_root
    for search_root in "$@"; do
        [[ -d "$search_root" ]] || continue
        find "$search_root" -mindepth 1 -maxdepth "$EXE_SEARCH_DEPTH" -type f -name "$CLIENT_EXE_NAME" \
            -perm -u+x -printf '%T@ %p\n' 2>/dev/null
    done | sort -rn | cut -d' ' -f2-
}

resolve_client_exe() {
    # Sets builds (newest first), exe_path (the newest, empty when none) and build_dir (tree=, else
    # the newest one's build dir, else build/)
    local relative
    local -a roots
    if [[ -n "$opt_tree" ]]; then
        if [[ "$opt_tree" == /* ]]; then build_dir="$opt_tree"; else build_dir="$REPO_ROOT/$opt_tree"; fi
        roots=("$build_dir")
    else
        build_dir="$REPO_ROOT/$DEFAULT_BUILD_DIR"
        roots=("$REPO_ROOT"/$BUILD_DIR_PATTERN)
    fi

    mapfile -t builds < <(find_client_builds "${roots[@]}")
    exe_path="${builds[0]:-}"
    if [[ -n "$exe_path" && -z "$opt_tree" ]]; then
        relative="${exe_path#"$REPO_ROOT/"}"
        build_dir="$REPO_ROOT/${relative%%/*}"
    fi
}

build_client() {
    # Configures the build dir (Release) when it has no CMake cache, then builds supertuxkart in it
    if [[ ! -f "$build_dir/$CMAKE_CACHE_NAME" ]]; then
        write_warn "No configured $build_dir yet - configuring it."
        write_extra "cmake -S $REPO_ROOT -B $build_dir ${CONFIGURE_ARGS[*]}"
        if ! cmake -S "$REPO_ROOT" -B "$build_dir" "${CONFIGURE_ARGS[@]}"; then
            write_err "Configure failed."
            exit 1
        fi
    fi
    write_extra "cmake --build $build_dir --target $CLIENT_EXE_NAME --parallel $BUILD_JOBS"
    if ! cmake --build "$build_dir" --target "$CLIENT_EXE_NAME" --parallel "$BUILD_JOBS"; then
        write_err "Build failed."
        exit 1
    fi
    write_ok "Build done."
}

check_assets() {
    # Warns when stk finds no assets (karts, tracks, music) beside the repo
    local name
    if [[ -n "${SUPERTUXKART_ASSETS_DIR:-}" || -n "${SUPERTUXKART_DATADIR:-}" ]]; then
        write_label "Data / assets from SUPERTUXKART_DATADIR / SUPERTUXKART_ASSETS_DIR."
        return
    fi
    for name in "${ASSETS_DIR_NAMES[@]}"; do
        if [[ -d "$REPO_ROOT/../$name" ]]; then
            write_label "Assets: $(realpath -- "$REPO_ROOT/../$name")"
            return
        fi
    done
    write_warn "No $(join_by ' / ' "${ASSETS_DIR_NAMES[@]}") beside $REPO_ROOT - stk has no karts and tracks without it:"
    write_extra "svn checkout $ASSETS_SVN_URL $(dirname -- "$REPO_ROOT")/${ASSETS_DIR_NAMES[0]}"
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

show_launch_command() {
    # Prints the bash lines reproducing this run
    local exe="$exe_path"
    echo
    write_extra "# $ALIAS_NAME $(format_args "${script_args[@]}")"
    if $opt_build; then
        if [[ ! -f "$build_dir/$CMAKE_CACHE_NAME" ]]; then
            write_extra "cmake -S $(format_shell_arg "$REPO_ROOT") -B $(format_shell_arg "$build_dir") ${CONFIGURE_ARGS[*]}"
        fi
        write_extra "cmake --build $(format_shell_arg "$build_dir") --target $CLIENT_EXE_NAME --parallel $BUILD_JOBS"
    fi
    if [[ -z "$exe" ]]; then exe="$build_dir/bin/$CLIENT_EXE_NAME"; fi
    write_extra "(cd $(format_shell_arg "$REPO_ROOT") && $(format_shell_arg "$exe") $(format_args "${launch_args[@]}"))"
}

start_client() {
    # Runs the game from the repo root in the foreground (data/ is found from there)
    local exit_code=0
    (cd "$REPO_ROOT" && "$exe_path" "$@") || exit_code=$?

    if (( exit_code == 0 )); then
        write_label "$CLIENT_EXE_NAME exited (exit code 0)."
        return
    fi

    write_err "$CLIENT_EXE_NAME exited with exit code $exit_code."
    if (( exit_code == EXIT_LOADER_FAILED )); then
        write_err "$EXIT_LOADER_FAILED: it could not be started - a shared library may be missing (ldd $exe_path)."
    fi
    write_err "See its log: $CONFIG_DIR/stdout.log"
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

write_alt "stk..."

if [[ ! -d "$REPO_ROOT" ]]; then
    write_err "stk-code repo not found: $(join_by ' or ' "${REPO_ROOT_CANDIDATES[@]}")"
    exit 1
fi

resolve_client_exe
launch_args=("${opt_stk[@]}" "${opt_extra[@]}")

if $opt_print_only; then
    show_launch_command
    exit 0
fi

if $opt_build; then
    build_client
    resolve_client_exe
fi
if [[ -z "$exe_path" ]]; then
    if [[ -n "$opt_tree" ]]; then
        write_err "No $CLIENT_EXE_NAME under $build_dir - add 'build' to build it there."
    else
        write_err "No $CLIENT_EXE_NAME under $REPO_ROOT/$BUILD_DIR_PATTERN - add 'build' to build $DEFAULT_BUILD_DIR/ (configured when missing)."
    fi
    exit 1
fi

write_label "Using newest build: $exe_path"
write_label "  built $(date -r "$exe_path" +"$BUILD_TIME_FORMAT")"
for older in "${builds[@]:1}"; do
    write_label "  (older: $older - $(date -r "$older" +"$BUILD_TIME_FORMAT"))"
done
check_assets

echo

write_extra "(cd $REPO_ROOT && $exe_path ${launch_args[*]})"
start_client "${launch_args[@]}"
