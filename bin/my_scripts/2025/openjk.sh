#!/usr/bin/env bash
# openjk.sh - starts OpenJK (Jedi Academy multiplayer / single player, Jedi Outcast single player,
# the dedicated server) from the install its build tree puts in CMAKE_INSTALL_PREFIX.
#
# Usage examples (nothing runs without `run` as the first arg; the args after it in any order,
# case insensitive; `.openjk help` lists them all):
# cd into the repo and print how to run it, through this script and by hand (runs nothing):
# .openjk
#
# Jedi Academy multiplayer (the default), single player, Jedi Outcast:
# .openjk run
# .openjk run sp
# .openjk run jo
#
# the JA+ mod, on the rend2 renderer, windowed at 1600x900:
# .openjk run japp rend2 win size=1600x900
#
# a multiplayer map with bots, on a fresh config, writing qconsole.log:
# .openjk run map=mp/ffa3 bots fresh log
#
# a single player level with cheats (devmap), rebuilt and installed first:
# .openjk run sp dev=t1_sour build
#
# a dedicated server, raw game args after the options (from the first + arg on):
# .openjk run ded map=mp/duel1 +set g_gametype 3
#
# print the bash line for this run instead of running it:
# .openjk run jo dev print

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

# The checkout: the first of these that exists
REPO_ROOT_CANDIDATES=("$code_root_dir/Code/c++/OpenJK" "$code_root_dir/Code2/C++/OpenJK")
REPO_ROOT="${REPO_ROOT_CANDIDATES[0]}"
for repo_candidate in "${REPO_ROOT_CANDIDATES[@]}"; do
    if [[ -d "$repo_candidate" ]]; then REPO_ROOT="$repo_candidate"; break; fi
done
# Build trees: the build*/ dirs holding a CMake cache; the one with the newest exe of the game
# wins, and its CMAKE_INSTALL_PREFIX is where the game runs from
BUILD_DIR_PATTERN="build*"
CMAKE_CACHE_NAME="CMakeCache.txt"
INSTALL_PREFIX_VAR="CMAKE_INSTALL_PREFIX"
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

# The install prefix when no build tree names one; `build` configures build/ with it when no
# tree exists yet
DEFAULT_INSTALL_PREFIX="$HOME/.local/share/openjk"
DEFAULT_BUILD_DIR="build"
CONFIGURE_ARGS=(-DCMAKE_BUILD_TYPE=RelWithDebInfo "-D$INSTALL_PREFIX_VAR=$DEFAULT_INSTALL_PREFIX")
BUILD_JOBS="$(nproc 2>/dev/null || echo 4)"
ARCH="$(uname -m)"

# The games: <install prefix>/<dir>/<exe>.<arch>, with the game data in <dir>/base/assets*.pk3
GAME_NAMES=(mp sp jo ded)
DEFAULT_GAME="mp"
declare -A GAME_ALIASES=([ja]=mp [multiplayer]=mp [jasp]=sp [singleplayer]=sp [jk2]=jo [josp]=jo [outcast]=jo [server]=ded [dedicated]=ded)
declare -A GAME_EXES=([mp]=openjk [sp]=openjk_sp [jo]=openjo_sp [ded]=openjkded)
declare -A GAME_DIRS=([mp]=JediAcademy [sp]=JediAcademy [jo]=JediOutcast [ded]=JediAcademy)
declare -A GAME_INFO=(
    [mp]="Jedi Academy multiplayer (also: ja, multiplayer)"
    [sp]="Jedi Academy single player (also: jasp, singleplayer)"
    [jo]="Jedi Outcast single player (also: jk2, josp, outcast)"
    [ded]="Jedi Academy dedicated server (also: server, dedicated)"
)
# dev / bots load this map; the server starts it with map (no cheats), the others with devmap
declare -A GAME_DEV_MAPS=([mp]=mp/ffa1 [sp]=yavin1 [jo]=kejim_post [ded]=mp/ffa1)
declare -A GAME_MAP_COMMANDS=([mp]=+devmap [sp]=+devmap [jo]=+devmap [ded]=+map)
MP_GAMES=(mp ded)
GAME_DATA_DIR_NAME="base"
GAME_DATA_PATTERN="assets*.pk3"

# Launch options (show_help)
ALIAS_NAME=".openjk"
RUN_COMMAND="run"
HELP_TOKENS=(help h)
PRINT_TOKENS=(print onlyprint showcmd)
OPTION_VALUE_SEPARATOR="="
PASSTHROUGH_PREFIX="+"
# cl_renderer is archived in the config, so vanilla is needed to leave rend2 again (mp only)
RENDERER_NAMES=(rend2 vanilla)
declare -A RENDERERS=([rend2]=rd-rend2 [vanilla]=rd-vanilla)
JAPLUS_MOD="japlus"
JAPLUS_TOKENS=(japp japlus)
BOTS=(Tavion Desann Alora)
BOT_SKILL="3"
BOT_WAIT_FRAMES="200"
WINDOWED_ARGS=(+set r_fullscreen 0)
FULLSCREEN_ARGS=(+set r_fullscreen 1)
LOG_ARGS=(+set logfile 2)
NO_BOTS_ARGS=(+set bot_enable 0)
NO_SOUND_ARGS=(+set s_initsound 0)
FRESH_HOME_DIR="${TMPDIR:-/tmp}/openjk-fresh"
# The game's own home (fs_homepath): configs, mods like japlus, qconsole.log
DEFAULT_HOME_DIR="$HOME/.local/share/openjk"
# Exit code of a process the loader could not start (e.g. a missing shared library)
EXIT_LOADER_FAILED=127

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
    local name
    write_alt "openjk - start OpenJK from the install of its newest build tree under $REPO_ROOT/$BUILD_DIR_PATTERN"
    cat <<EOF

Usage: $ALIAS_NAME $RUN_COMMAND [options] [+game args...]
Nothing runs without $RUN_COMMAND as the first arg; a bare $ALIAS_NAME cds into the repo and prints how to run it.
Options are case insensitive, in any order, with or without leading dashes.

Game (default $DEFAULT_GAME):
EOF
    for name in "${GAME_NAMES[@]}"; do
        printf '  %-6s %-28s %s\n' "$name" "${GAME_DIRS[$name]}/${GAME_EXES[$name]}.$ARCH" "${GAME_INFO[$name]}"
    done
    cat <<EOF

Build / install (the tree: the build*/ dir with the newest exe of the game; runs from its $INSTALL_PREFIX_VAR):
  tree=<dir>             this build dir instead (relative to the repo, or absolute)
  build                  cmake --build, then cmake --install ($DEFAULT_BUILD_DIR/ configured when no tree exists)
  install                cmake --install only

Renderer / mods:
  $(join_by ' | ' "${RENDERER_NAMES[@]}")         cl_renderer rd-rend2 / rd-vanilla (mp only; it is remembered in the config)
  mod=<name>             fs_game <name> (a mod dir in the game's dir or in $DEFAULT_HOME_DIR)
  $(join_by ' | ' "${JAPLUS_TOKENS[@]}")         mod=$JAPLUS_MOD (JA+)

Window / sound:
  win                    windowed (r_fullscreen 0)
  full                   fullscreen (r_fullscreen 1)
  size=<W>x<H>           r_mode -1, r_customwidth / r_customheight
  nosound                s_initsound 0

Starting:
  dev                    ${GAME_MAP_COMMANDS[mp]} of the game's dev map (mp ${GAME_DEV_MAPS[mp]}, sp ${GAME_DEV_MAPS[sp]}, jo ${GAME_DEV_MAPS[jo]}; ded uses ${GAME_MAP_COMMANDS[ded]})
  dev=<map>, map=<map>   that map instead
  bots                   +addbot $(join_by ', ' "${BOTS[@]}") (skill $BOT_SKILL) on the map (the dev map if none; mp / ded)
  nobots                 bot_enable 0 (mp / ded)
  connect=<address>      +connect <address> instead of a map (mp)
  fresh                  empty fs_homepath at $FRESH_HOME_DIR (cleared each run)
  log                    logfile 2 (qconsole.log in <home>/<mod or base>)

Other:
  +...                   this arg and all after it go to the game as they are
  $(join_by ' | ' "${PRINT_TOKENS[@]}")  print the bash line for this run instead of running it
  $(join_by ' | ' "${HELP_TOKENS[@]}") (also -help, --help)  this help

The game data must be in <install>/<dir>/$GAME_DATA_DIR_NAME/$GAME_DATA_PATTERN (from the game's GameData/base).

Examples:
  $ALIAS_NAME $RUN_COMMAND japp rend2 win
  $ALIAS_NAME $RUN_COMMAND map=mp/ffa3 bots fresh log
  $ALIAS_NAME $RUN_COMMAND sp dev=t1_sour build
  $ALIAS_NAME $RUN_COMMAND ded map=mp/duel1 +set g_gametype 3

EOF
    show_manual_run
}

show_usage() {
    # A bare call: how to run OpenJK, through this script and by hand
    write_alt "openjk - $REPO_ROOT"
    write_label "Run it through this script (the options after $RUN_COMMAND; '$ALIAS_NAME help' lists them):"
    write_extra "$ALIAS_NAME $RUN_COMMAND [$(join_by ' | ' "${GAME_NAMES[@]}")]"
    show_manual_run
}

show_manual_run() {
    # Prints how to build / install it and start each installed game by hand, without this script
    local name tree_rel prefix game_dir found=false
    local -a trees
    mapfile -t trees < <(find_build_trees)
    prefix="$(install_prefix_of "${trees[0]:-}")"
    tree_rel="${trees[0]:-$REPO_ROOT/$DEFAULT_BUILD_DIR}"
    tree_rel="${tree_rel#"$REPO_ROOT/"}"

    write_label "Or by hand - build and install (from $REPO_ROOT; into $prefix):"
    write_extra "cmake --build $tree_rel --parallel \$(nproc) && cmake --install $tree_rel"
    for name in "${GAME_NAMES[@]}"; do
        game_dir="$prefix/${GAME_DIRS[$name]}"
        [[ -x "$game_dir/${GAME_EXES[$name]}.$ARCH" ]] || continue
        if ! $found; then write_label "and run an installed game from its dir:"; found=true; fi
        write_extra "(cd $(format_shell_arg "$game_dir") && ./${GAME_EXES[$name]}.$ARCH)   # $name: ${GAME_INFO[$name]%% (*}"
    done
    if ! $found; then write_warn "Nothing is installed in $prefix yet."; fi
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
    opt_help=false; opt_print_only=false; opt_game="$DEFAULT_GAME"; opt_tree=""; opt_build=false
    opt_install=false; opt_renderer=""; opt_mod=""; opt_windowed=false; opt_fullscreen=false
    opt_size=""; opt_no_sound=false; opt_dev=false; opt_map=""; opt_bots=false; opt_no_bots=false; opt_connect=""
    opt_fresh=false; opt_log=false; opt_extra=()

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
        if [[ -n "$name" && -n "${GAME_ALIASES[$name]:-}" ]]; then name="${GAME_ALIASES[$name]}"; fi

        if in_list "$name" "${HELP_TOKENS[@]}"; then opt_help=true
        elif in_list "$name" "${PRINT_TOKENS[@]}"; then opt_print_only=true
        elif in_list "$name" "${GAME_NAMES[@]}"; then opt_game="$name"
        elif [[ "$name" == "tree" && -n "$value" ]]; then opt_tree="$value"
        elif [[ "$name" == "build" ]]; then opt_build=true
        elif [[ "$name" == "install" ]]; then opt_install=true
        elif [[ -n "$name" && -n "${RENDERERS[$name]:-}" ]]; then opt_renderer="${RENDERERS[$name]}"
        elif [[ "$name" == "mod" && -n "$value" ]]; then opt_mod="$value"
        elif in_list "$name" "${JAPLUS_TOKENS[@]}"; then opt_mod="$JAPLUS_MOD"
        elif [[ "$name" == "win" ]]; then opt_windowed=true
        elif [[ "$name" == "full" ]]; then opt_fullscreen=true
        elif [[ "$name" == "size" && "$value" =~ ^[0-9]+x[0-9]+$ ]]; then opt_size="$value"
        elif [[ "$name" == "nosound" ]]; then opt_no_sound=true
        elif [[ "$name" == "dev" ]]; then opt_map="${value:-}"; opt_dev=true
        elif [[ "$name" == "map" && -n "$value" ]]; then opt_map="$value"; opt_dev=true
        elif [[ "$name" == "bots" ]]; then opt_bots=true
        elif [[ "$name" == "nobots" ]]; then opt_no_bots=true
        elif [[ "$name" == "connect" && -n "$value" ]]; then opt_connect="$value"
        elif [[ "$name" == "fresh" ]]; then opt_fresh=true
        elif [[ "$name" == "log" ]]; then opt_log=true
        else
            write_err "Unknown arg: $raw (tree= / mod= / size=<W>x<H> / map= / connect= need a value) - see '$ALIAS_NAME help'."
            exit 1
        fi
        shift
    done

    # dev / map= / bots load a map; a dev / bots without one (and a server) get the game's dev map
    if $opt_dev || $opt_bots || [[ "$opt_game" == "ded" ]]; then
        [[ -n "$opt_map" ]] || opt_map="${GAME_DEV_MAPS[$opt_game]}"
    fi
    if $opt_windowed && $opt_fullscreen; then write_warn "win and full both given - using full."; opt_windowed=false; fi
    if ! in_list "$opt_game" "${MP_GAMES[@]}"; then
        local -a ignored=()
        [[ -n "$opt_renderer" ]] && ignored+=("$opt_renderer")
        $opt_bots && ignored+=(bots)
        $opt_no_bots && ignored+=(nobots)
        [[ -n "$opt_connect" ]] && ignored+=("connect=$opt_connect")
        if (( ${#ignored[@]} > 0 )); then write_warn "$(join_by ', ' "${ignored[@]}") is multiplayer only - ignoring it for $opt_game."; fi
        opt_renderer=""; opt_bots=false; opt_no_bots=false; opt_connect=""
    fi
}

find_build_trees() {
    # The build*/ dirs holding a CMake cache, newest cache first
    local dir
    for dir in "$REPO_ROOT"/$BUILD_DIR_PATTERN; do
        [[ -f "$dir/$CMAKE_CACHE_NAME" ]] && printf '%s %s\n' "$(stat -c %Y -- "$dir/$CMAKE_CACHE_NAME")" "$dir"
    done | sort -rn | cut -d' ' -f2-
}

install_prefix_of() {
    # install_prefix_of <tree> - its cached CMAKE_INSTALL_PREFIX, else the default
    local prefix=""
    if [[ -n "$1" && -f "$1/$CMAKE_CACHE_NAME" ]]; then
        prefix="$(sed -n "s/^$INSTALL_PREFIX_VAR:[A-Z]*=//p" "$1/$CMAKE_CACHE_NAME" | head -1)"
    fi
    printf '%s' "${prefix:-$DEFAULT_INSTALL_PREFIX}"
}

resolve_game() {
    # Sets tree_dir (tree=, else the tree with the newest exe of the game, else the newest tree,
    # else build/), tree_exe (the game's exe in it), install_prefix, game_dir and exe_path
    local exe_name="${GAME_EXES[$opt_game]}.$ARCH" tree newest=""
    local -a trees
    if [[ -n "$opt_tree" ]]; then
        if [[ "$opt_tree" == /* ]]; then tree_dir="$opt_tree"; else tree_dir="$REPO_ROOT/$opt_tree"; fi
    else
        mapfile -t trees < <(find_build_trees)
        tree_dir="${trees[0]:-$REPO_ROOT/$DEFAULT_BUILD_DIR}"
        for tree in "${trees[@]}"; do
            [[ -f "$tree/$exe_name" ]] || continue
            if [[ -z "$newest" || "$tree/$exe_name" -nt "$newest/$exe_name" ]]; then newest="$tree"; fi
        done
        [[ -n "$newest" ]] && tree_dir="$newest"
    fi
    tree_exe="$tree_dir/$exe_name"
    install_prefix="$(install_prefix_of "$tree_dir")"
    game_dir="$install_prefix/${GAME_DIRS[$opt_game]}"
    exe_path="$game_dir/$exe_name"
}

get_build_commands() {
    # Sets build_commands: the bash lines configuring (when the tree has no cache), building and
    # installing the tree, as `build` / `install` ask
    build_commands=()
    if $opt_build; then
        if [[ ! -f "$tree_dir/$CMAKE_CACHE_NAME" ]]; then
            build_commands+=("cmake -S $(format_shell_arg "$REPO_ROOT") -B $(format_shell_arg "$tree_dir") $(format_args "${CONFIGURE_ARGS[@]}")")
        fi
        build_commands+=("cmake --build $(format_shell_arg "$tree_dir") --parallel $BUILD_JOBS")
    fi
    if $opt_build || $opt_install; then
        build_commands+=("cmake --install $(format_shell_arg "$tree_dir")")
    fi
}

build_and_install() {
    # Configures (when needed), builds and installs the tree, as `build` / `install` ask
    if $opt_build; then
        if [[ ! -f "$tree_dir/$CMAKE_CACHE_NAME" ]]; then
            write_warn "No configured $tree_dir yet - configuring it."
            write_extra "cmake -S $REPO_ROOT -B $tree_dir ${CONFIGURE_ARGS[*]}"
            if ! cmake -S "$REPO_ROOT" -B "$tree_dir" "${CONFIGURE_ARGS[@]}"; then
                write_err "Configure failed."
                exit 1
            fi
        fi
        write_extra "cmake --build $tree_dir --parallel $BUILD_JOBS"
        if ! cmake --build "$tree_dir" --parallel "$BUILD_JOBS"; then
            write_err "Build failed."
            exit 1
        fi
    fi
    write_extra "cmake --install $tree_dir"
    if ! cmake --install "$tree_dir"; then
        write_err "Install failed."
        exit 1
    fi
    write_ok "Installed into $(install_prefix_of "$tree_dir")."
}

check_game_data() {
    # Exits when the game's base/ holds no assets*.pk3
    local data_dir="$game_dir/$GAME_DATA_DIR_NAME"
    local -a paks
    mapfile -t paks < <(find "$data_dir" -maxdepth 1 -type f -iname "$GAME_DATA_PATTERN" -printf '%f\n' 2>/dev/null | sort)
    if (( ${#paks[@]} == 0 )); then
        write_err "No $GAME_DATA_PATTERN in $data_dir - copy them from the game's GameData/$GAME_DATA_DIR_NAME."
        exit 1
    fi
    write_label "Game data: $data_dir ($(join_by ', ' "${paks[@]}"))"
}

get_launch_args() {
    # Sets launch_args: the cvars of the options, then the commands, then the raw args
    local bot
    launch_args=()
    if $opt_fresh; then launch_args+=(+set fs_homepath "$FRESH_HOME_DIR"); fi
    if [[ -n "$opt_mod" ]]; then launch_args+=(+set fs_game "$opt_mod"); fi
    if [[ -n "$opt_renderer" ]]; then launch_args+=(+set cl_renderer "$opt_renderer"); fi
    if $opt_windowed; then launch_args+=("${WINDOWED_ARGS[@]}"); fi
    if $opt_fullscreen; then launch_args+=("${FULLSCREEN_ARGS[@]}"); fi
    if [[ -n "$opt_size" ]]; then
        launch_args+=(+set r_mode -1 +set r_customwidth "${opt_size%x*}" +set r_customheight "${opt_size#*x}")
    fi
    if $opt_no_sound; then launch_args+=("${NO_SOUND_ARGS[@]}"); fi
    if $opt_log; then launch_args+=("${LOG_ARGS[@]}"); fi
    if $opt_no_bots; then launch_args+=("${NO_BOTS_ARGS[@]}"); fi

    if [[ -n "$opt_connect" ]]; then
        if [[ -n "$opt_map" ]]; then write_warn "connect joins a server - ignoring the map."; fi
        launch_args+=(+connect "$opt_connect")
    elif [[ -n "$opt_map" ]]; then
        launch_args+=("${GAME_MAP_COMMANDS[$opt_game]}" "$opt_map")
        if $opt_bots; then
            launch_args+=(+wait "$BOT_WAIT_FRAMES")
            for bot in "${BOTS[@]}"; do launch_args+=(+addbot "$bot" "$BOT_SKILL"); done
        fi
    fi

    launch_args+=("${opt_extra[@]}")
}

reset_fresh_home() {
    # The `fresh` fs_homepath is emptied first, so no openjk.cfg carries over
    rm -rf -- "$FRESH_HOME_DIR"
    write_label "Fresh home: $FRESH_HOME_DIR"
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

start_client() {
    # Runs the game from its install dir in the foreground (it loads its renderer and game
    # libraries and base/ from there)
    local exit_code=0
    (cd "$game_dir" && "./$(basename -- "$exe_path")" "$@") || exit_code=$?

    if (( exit_code == 0 )); then
        write_label "$(basename -- "$exe_path") exited (exit code 0)."
        return
    fi

    write_err "$(basename -- "$exe_path") exited with exit code $exit_code."
    if (( exit_code == EXIT_LOADER_FAILED )); then
        write_err "$EXIT_LOADER_FAILED: it could not be started - a shared library may be missing (ldd $exe_path)."
    fi
    write_err "Add 'log' for qconsole.log in $DEFAULT_HOME_DIR/${opt_mod:-$GAME_DATA_DIR_NAME}."
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

write_alt "openjk ($opt_game: ${GAME_INFO[$opt_game]%% (*})..."

if [[ ! -d "$REPO_ROOT" ]]; then
    write_err "OpenJK repo not found: $(join_by ' or ' "${REPO_ROOT_CANDIDATES[@]}")"
    exit 1
fi

resolve_game
get_launch_args

if $opt_print_only; then
    get_build_commands
    echo
    write_extra "# $ALIAS_NAME $(format_args "${script_args[@]}")"
    for line in "${build_commands[@]}"; do write_extra "$line"; done
    if $opt_fresh; then write_extra "rm -rf -- $(format_shell_arg "$FRESH_HOME_DIR")"; fi
    write_extra "(cd $(format_shell_arg "$game_dir") && ./$(basename -- "$exe_path")${launch_args[*]:+ $(format_args "${launch_args[@]}")})"
    exit 0
fi

if $opt_build || $opt_install; then
    build_and_install
    resolve_game
fi

if [[ ! -x "$exe_path" ]]; then
    if [[ -f "$tree_exe" ]]; then
        write_err "$exe_path is not installed - add 'install' (cmake --install $tree_dir)."
    else
        write_err "No $exe_path and no $tree_exe - add 'build' (builds and installs $tree_dir)."
    fi
    exit 1
fi

write_label "Using: $exe_path"
write_label "  installed $(date -r "$exe_path" +"$BUILD_TIME_FORMAT") from $tree_dir"
if [[ -f "$tree_exe" && "$tree_exe" -nt "$exe_path" ]]; then
    write_warn "The build in $tree_dir is newer than the install - add 'install' to install it."
fi
check_game_data
if $opt_fresh; then reset_fresh_home; fi

echo

write_extra "(cd $game_dir && ./$(basename -- "$exe_path")${launch_args[*]:+ ${launch_args[*]}})"
start_client "${launch_args[@]}"
