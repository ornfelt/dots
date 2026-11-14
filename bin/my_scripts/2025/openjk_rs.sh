#!/usr/bin/env bash
# openjk_rs.sh - starts openjk-rs (the Rust port of OpenJK: Jedi Academy multiplayer / single
# player, Jedi Outcast single player, the dedicated server) from its cargo dist dir
# (target/dist/release), the same way openjk.sh starts the C build from its install. Checks that
# the game data is in place (links it in from the C install after asking) and that the port is
# built and not older than its sources (builds it after asking).
#
# Usage examples (nothing runs without `run` as the first arg; the args after it in any order,
# case insensitive; `.openjk_rs help` lists them all):
# cd into the repo and print how to run it, through this script and by hand (runs nothing):
# .openjk_rs
#
# Jedi Academy multiplayer (the default), single player, Jedi Outcast:
# .openjk_rs run
# .openjk_rs run sp
# .openjk_rs run jo
#
# the JA+ mod, on the rend2 renderer, windowed at 1600x900:
# .openjk_rs run japp rend2 win size=1600x900
#
# a multiplayer map with bots, on a fresh config, writing qconsole.log:
# .openjk_rs run map=mp/ffa3 bots fresh log
#
# a single player level with cheats (devmap), rebuilt first:
# .openjk_rs run sp dev=t1_sour build
#
# a dedicated server, raw game args after the options (from the first + arg on):
# .openjk_rs run ded map=mp/duel1 +set g_gametype 3
#
# with the C build's home (its configs, saves and mod dirs) instead of the port's own:
# .openjk_rs run sharedhome
#
# print the bash lines for this run instead of running it:
# .openjk_rs run jo dev print

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

# When true, a missing or out-of-date build is built without asking first
AUTO_BUILD=false
# When true, missing pk3 files (and a mod's libraries) are linked in without asking first
AUTO_COPY_DATA=false
# When true, a pk3 on the same filesystem is hard-linked; otherwise (or when that fails) it is
# symlinked - the assets are ~1.5 GB, so nothing is copied
LINK_SAME_VOLUME=true

# The Rust port; `cargo xtask dist --release` builds the workspace and lays the binaries out as
# the C install does: <dist>/JediAcademy/{openjk,openjk_sp,openjkded}.<arch>, the renderers,
# OpenJK/ and base/ with the modules; <dist>/JediOutcast/openjo_sp.<arch>, ...
REPO_ROOT="$code_root_dir/Code2/Rust/openjk-rs"
DEFAULT_DIST_SUBPATH="target/dist/release"
BUILD_COMMAND="cargo"
RELEASE_BUILD_ARGS=(xtask dist --release)
DEBUG_BUILD_ARGS=(xtask dist)
DEBUG_DIST_NAME="debug"
# The sources whose change makes a build out of date (target/ and .git/ are skipped)
SOURCE_NAME_PATTERNS=("*.rs" "Cargo.toml" "Cargo.lock")
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

ARCH="$(uname -m)"
BUILD_JOBS="$(nproc 2>/dev/null || echo 4)"

# The games: <dist>/<dir>/<exe>.<arch>, with the game data in <dir>/base/assets*.pk3
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
# The libraries each game needs next to its exe (relative to <dist>/<dir>; ARCH is filled in)
declare -A GAME_LIBRARIES=(
    [mp]="rd-vanilla_ARCH.so base/cgameARCH.so base/uiARCH.so base/jampgameARCH.so"
    [sp]="rdsp-vanilla_ARCH.so OpenJK/jagameARCH.so"
    [jo]="rdjosp-vanilla_ARCH.so OpenJK/jospgameARCH.so"
    [ded]="base/jampgameARCH.so"
)
# dev / bots load this map; the server starts it with map (no cheats), the others with devmap
declare -A GAME_DEV_MAPS=([mp]=mp/ffa1 [sp]=yavin1 [jo]=kejim_post [ded]=mp/ffa1)
declare -A GAME_MAP_COMMANDS=([mp]=+devmap [sp]=+devmap [jo]=+devmap [ded]=+map)
MP_GAMES=(mp ded)
GAME_DATA_DIR_NAME="base"
GAME_DATA_PATTERN="assets*.pk3"
PK3_PATTERN="*.pk3"
declare -A REQUIRED_PK3S=([JediAcademy]="assets0.pk3 assets1.pk3 assets2.pk3 assets3.pk3" [JediOutcast]="assets0.pk3 assets1.pk3 assets2.pk3")

# Where the game data is linked from: the C build's install (openjk.sh's), i.e. the
# CMAKE_INSTALL_PREFIX of each C build tree, then the default prefix; then other dist dirs here
C_REPO_ROOT_CANDIDATES=("$code_root_dir/Code/c++/OpenJK" "$code_root_dir/Code2/C++/OpenJK")
C_BUILD_DIR_PATTERN="build*"
CMAKE_CACHE_NAME="CMakeCache.txt"
INSTALL_PREFIX_VAR="CMAKE_INSTALL_PREFIX"
C_DEFAULT_INSTALL_PREFIX="$HOME/.local/share/openjk"

# fs_homepath (configs, saves, mod dirs, qconsole.log). The engine's default is the C build's
# home (<data home>/openjk, openjo for Jedi Outcast) - shared with the C build. The port runs with
# its own <name>-rs home instead, so it never rewrites the C build's configs or saves;
# `sharedhome` uses the C build's.
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
declare -A GAME_HOME_NAMES=([mp]=openjk [sp]=openjk [jo]=openjo [ded]=openjk)
RS_HOME_SUFFIX="-rs"
FRESH_HOME_DIR="${TMPDIR:-/tmp}/openjk-rs-fresh"

# Launch options (show_help)
ALIAS_NAME=".openjk_rs"
RUN_COMMAND="run"
HELP_TOKENS=(help h)
PRINT_TOKENS=(print onlyprint showcmd)
SHARED_HOME_TOKENS=(sharedhome sharehome chome)
OPTION_VALUE_SEPARATOR="="
PASSTHROUGH_PREFIX="+"
# cl_renderer is archived in the config, so vanilla is needed to leave rend2 again (mp only)
RENDERER_NAMES=(rend2 vanilla)
declare -A RENDERERS=([rend2]=rd-rend2 [vanilla]=rd-vanilla)
JAPLUS_MOD="japlus"
JAPLUS_TOKENS=(japp japlus)
# A mod dir found only in the C build's home: these files of it are linked into the port's home
# (its configs, bans and logs stay where they are)
MOD_LINK_PATTERNS=("*.so" "*.pk3")
BOTS=(Tavion Desann Alora)
BOT_SKILL="3"
BOT_WAIT_FRAMES="200"
WINDOWED_ARGS=(+set r_fullscreen 0)
FULLSCREEN_ARGS=(+set r_fullscreen 1)
LOG_ARGS=(+set logfile 2)
NO_BOTS_ARGS=(+set bot_enable 0)
NO_SOUND_ARGS=(+set s_initsound 0)
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
    write_alt "openjk_rs - build (when missing or out of date, after asking) and start openjk-rs from $REPO_ROOT/$DEFAULT_DIST_SUBPATH"
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

Build (a missing build, or one older than the sources, is offered for building before the run):
  tree=<dir>             this dist dir instead of $DEFAULT_DIST_SUBPATH (relative to the repo, or absolute;
                         target/dist/$DEBUG_DIST_NAME builds without --release)
  build                  $BUILD_COMMAND ${RELEASE_BUILD_ARGS[*]} first, without asking (builds the workspace and lays out the dist dir)
  install                the same: the dist step is the port's install

Renderer / mods:
  $(join_by ' | ' "${RENDERER_NAMES[@]}")         cl_renderer rd-rend2 / rd-vanilla (mp only; it is remembered in the config)
  mod=<name>             fs_game <name> (a mod dir in the game's dir or the home; one only in the C build's home
                         gets its $(join_by ' / ' "${MOD_LINK_PATTERNS[@]}") files linked in, after asking)
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

Home (fs_homepath; default: the port's own $DATA_HOME/<openjk or openjo>$RS_HOME_SUFFIX):
  $(join_by ' | ' "${SHARED_HOME_TOKENS[@]}")  the C build's home ($DATA_HOME/openjk, openjo for jo) - its configs, saves and mods
  home=<dir>             this dir
  fresh                  empty fs_homepath at $FRESH_HOME_DIR (cleared each run)
  log                    logfile 2 (qconsole.log in <home>/<mod or base>)

Other:
  +...                   this arg and all after it go to the game as they are
  $(join_by ' | ' "${PRINT_TOKENS[@]}")  print the bash lines for this run instead of running it
  $(join_by ' | ' "${HELP_TOKENS[@]}") (also -help, --help)  this help

The game data must be in <dist>/<dir>/$GAME_DATA_DIR_NAME/$GAME_DATA_PATTERN; missing pk3 files are linked in (after asking)
from the C build's install ($C_DEFAULT_INSTALL_PREFIX/<dir>/$GAME_DATA_DIR_NAME, or its build tree's $INSTALL_PREFIX_VAR).

Examples:
  $ALIAS_NAME $RUN_COMMAND japp rend2 win
  $ALIAS_NAME $RUN_COMMAND map=mp/ffa3 bots fresh log
  $ALIAS_NAME $RUN_COMMAND sp dev=t1_sour build
  $ALIAS_NAME $RUN_COMMAND ded map=mp/duel1 +set g_gametype 3

EOF
    show_manual_run
}

show_usage() {
    # A bare call: how to run openjk-rs, through this script and by hand
    write_alt "openjk-rs - $REPO_ROOT"
    write_label "Run it through this script (the options after $RUN_COMMAND; '$ALIAS_NAME help' lists them):"
    write_extra "$ALIAS_NAME $RUN_COMMAND [$(join_by ' | ' "${GAME_NAMES[@]}")]"
    show_manual_run
}

show_manual_run() {
    # Prints how to build and start each game by hand, without this script (the data check left out)
    local name dist_dir game_dir found=false
    dist_dir="$REPO_ROOT/$DEFAULT_DIST_SUBPATH"
    write_label "Or by hand - build (from $REPO_ROOT; into $DEFAULT_DIST_SUBPATH):"
    write_extra "$BUILD_COMMAND ${RELEASE_BUILD_ARGS[*]}"
    for name in "${GAME_NAMES[@]}"; do
        game_dir="$dist_dir/${GAME_DIRS[$name]}"
        [[ -x "$game_dir/${GAME_EXES[$name]}.$ARCH" ]] || continue
        if ! $found; then write_label "and run a game from its dir (its own home, as this script does):"; found=true; fi
        write_extra "(cd $(format_shell_arg "$game_dir") && ./${GAME_EXES[$name]}.$ARCH +set fs_homepath $(format_shell_arg "$DATA_HOME/${GAME_HOME_NAMES[$name]}$RS_HOME_SUFFIX"))   # $name: ${GAME_INFO[$name]%% (*}"
    done
    if ! $found; then write_warn "Nothing is built in $dist_dir yet."; fi
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
    opt_renderer=""; opt_mod=""; opt_windowed=false; opt_fullscreen=false
    opt_size=""; opt_no_sound=false; opt_dev=false; opt_map=""; opt_bots=false; opt_no_bots=false; opt_connect=""
    opt_fresh=false; opt_shared_home=false; opt_home=""; opt_log=false; opt_extra=()

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
        elif [[ "$name" == "build" || "$name" == "install" ]]; then opt_build=true
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
        elif in_list "$name" "${SHARED_HOME_TOKENS[@]}"; then opt_shared_home=true
        elif [[ "$name" == "home" && -n "$value" ]]; then opt_home="$value"
        elif [[ "$name" == "log" ]]; then opt_log=true
        else
            write_err "Unknown arg: $raw (tree= / mod= / size=<W>x<H> / map= / connect= / home= need a value) - see '$ALIAS_NAME help'."
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
    if [[ "$opt_game" == "ded" && -n "$opt_renderer" ]]; then
        write_warn "The dedicated server has no renderer - ignoring $opt_renderer."
        opt_renderer=""
    fi
    local -a homes=()
    $opt_fresh && homes+=(fresh)
    $opt_shared_home && homes+=(sharedhome)
    [[ -n "$opt_home" ]] && homes+=("home=$opt_home")
    if (( ${#homes[@]} > 1 )); then write_warn "$(join_by ', ' "${homes[@]}") given - using ${homes[0]}."; fi
}

resolve_game() {
    # Sets dist_dir, build_args, game_dir, exe_path, home_dir (empty: the engine's default, the
    # C build's home), c_home_dir and required_libraries
    local lib
    if [[ -z "$opt_tree" ]]; then
        dist_dir="$REPO_ROOT/$DEFAULT_DIST_SUBPATH"
    elif [[ "$opt_tree" == /* ]]; then
        dist_dir="$opt_tree"
    else
        dist_dir="$REPO_ROOT/$opt_tree"
    fi
    dist_dir="$(realpath -m -- "$dist_dir")"
    if [[ "$(basename -- "$dist_dir")" == "$DEBUG_DIST_NAME" ]]; then
        build_args=("${DEBUG_BUILD_ARGS[@]}")
    else
        build_args=("${RELEASE_BUILD_ARGS[@]}")
    fi
    # Only <cargo target dir>/dist/<profile> is what the build writes; another tree= (a copy of
    # a dist dir) is run as it is, without building or the out-of-date check
    local cargo_dist
    cargo_dist="$(realpath -m -- "${CARGO_TARGET_DIR:-$REPO_ROOT/target}/dist")"
    dist_buildable=false
    if [[ "$dist_dir" == "$cargo_dist/release" || "$dist_dir" == "$cargo_dist/$DEBUG_DIST_NAME" ]]; then
        dist_buildable=true
    fi
    game_dir="$dist_dir/${GAME_DIRS[$opt_game]}"
    exe_path="$game_dir/${GAME_EXES[$opt_game]}.$ARCH"

    c_home_dir="$DATA_HOME/${GAME_HOME_NAMES[$opt_game]}"
    if $opt_fresh; then home_dir="$FRESH_HOME_DIR"
    elif $opt_shared_home; then home_dir=""
    elif [[ -n "$opt_home" ]]; then home_dir="$(realpath -m -- "$opt_home")"
    else home_dir="$c_home_dir$RS_HOME_SUFFIX"
    fi

    required_libraries=()
    for lib in ${GAME_LIBRARIES[$opt_game]}; do required_libraries+=("${lib//ARCH/$ARCH}"); done
    if [[ -n "$opt_renderer" && "$opt_renderer" != "rd-vanilla" ]]; then
        required_libraries+=("${opt_renderer}_$ARCH.so")
    fi
}

get_missing_files() {
    # get_missing_files <dir> <file names...> - prints the names not found in dir
    local dir="$1" name
    shift
    for name in "$@"; do
        [[ -e "$dir/$name" ]] || printf '%s\n' "$name"
    done
}

ask_yes_no() {
    # ask_yes_no <auto> <question> - true on y / yes (or when auto is true); no when stdin is not a terminal
    local auto="$1" question="$2" answer
    if [[ "$auto" == true ]]; then
        write_label "$question - yes (set in the script)."
        return 0
    fi
    if [[ ! -t 0 ]]; then
        write_warn "$question - no (not a terminal)."
        return 1
    fi
    read -r -p "$question [y/N] " answer
    answer="${answer,,}"
    [[ "$answer" == "y" || "$answer" == "yes" ]]
}

find_newer_source() {
    # Prints the first source file newer than the given file (empty when the build is current)
    local reference="$1" pattern
    local -a name_args=()
    for pattern in "${SOURCE_NAME_PATTERNS[@]}"; do
        (( ${#name_args[@]} > 0 )) && name_args+=(-o)
        name_args+=(-name "$pattern")
    done
    find "$REPO_ROOT" \( -path "$REPO_ROOT/target" -o -path "$REPO_ROOT/.git" \) -prune -o \
        -type f \( "${name_args[@]}" \) -newer "$reference" -print -quit 2>/dev/null
}

run_build() {
    local exit_code=0
    if ! command -v "$BUILD_COMMAND" >/dev/null 2>&1; then
        write_err "$BUILD_COMMAND not found on PATH - install the Rust toolchain (rustup) first."
        exit 1
    fi
    write_extra "(cd $REPO_ROOT && $BUILD_COMMAND ${build_args[*]})"
    (cd "$REPO_ROOT" && CARGO_BUILD_JOBS="$BUILD_JOBS" "$BUILD_COMMAND" "${build_args[@]}") || exit_code=$?
    if (( exit_code != 0 )); then
        write_err "Build failed (exit code $exit_code)."
        exit 1
    fi
    write_ok "Build done."
}

check_build() {
    # Builds when asked (build), or after asking when the exe / a library is missing or the
    # sources are newer than the exe; exits when a missing build is not built
    local newer
    local -a missing
    if [[ ! -d "$REPO_ROOT" ]]; then
        write_err "openjk-rs repo not found: $REPO_ROOT"
        exit 1
    fi

    if ! $dist_buildable; then
        if $opt_build; then write_warn "build writes ${CARGO_TARGET_DIR:-$REPO_ROOT/target}/dist, not $dist_dir - ignoring it."; fi
        mapfile -t missing < <(get_missing_files "$game_dir" "$(basename -- "$exe_path")" "${required_libraries[@]}")
        if (( ${#missing[@]} > 0 )); then
            write_err "$(join_by ', ' "${missing[@]}") missing from $game_dir (tree=$opt_tree is not built by this script)."
            exit 1
        fi
    elif $opt_build; then
        run_build
    else
        mapfile -t missing < <(get_missing_files "$game_dir" "$(basename -- "$exe_path")" "${required_libraries[@]}")
        if (( ${#missing[@]} > 0 )); then
            write_warn "Not built: $(join_by ', ' "${missing[@]}") missing from $game_dir."
            if ask_yes_no "$AUTO_BUILD" "Build it now ($BUILD_COMMAND ${build_args[*]})?"; then
                run_build
            else
                write_err "Nothing to run - build it with '$ALIAS_NAME $RUN_COMMAND build' or $BUILD_COMMAND ${build_args[*]} in $REPO_ROOT."
                exit 1
            fi
        else
            newer="$(find_newer_source "$exe_path")"
            if [[ -n "$newer" ]]; then
                write_warn "The build is older than the sources (e.g. ${newer#"$REPO_ROOT/"} changed since $(date -r "$exe_path" +"$BUILD_TIME_FORMAT"))."
                if ask_yes_no "$AUTO_BUILD" "Rebuild it now ($BUILD_COMMAND ${build_args[*]})?"; then
                    run_build
                else
                    write_label "Running the existing build."
                fi
            fi
        fi
    fi

    mapfile -t missing < <(get_missing_files "$game_dir" "$(basename -- "$exe_path")" "${required_libraries[@]}")
    if (( ${#missing[@]} > 0 )); then
        write_err "The build finished but $(join_by ', ' "${missing[@]}") is still missing from $game_dir."
        exit 1
    fi
    write_label "Using: $exe_path"
    write_label "  built $(date -r "$exe_path" +"$BUILD_TIME_FORMAT") ($(git -C "$REPO_ROOT" log -1 --format='%h %s' 2>/dev/null | cut -c1-80))"
}

find_c_install_prefixes() {
    # The C build trees' CMAKE_INSTALL_PREFIX values (newest cache first), then the default prefix
    local repo dir
    for repo in "${C_REPO_ROOT_CANDIDATES[@]}"; do
        for dir in "$repo"/$C_BUILD_DIR_PATTERN; do
            [[ -f "$dir/$CMAKE_CACHE_NAME" ]] && printf '%s %s\n' "$(stat -c %Y -- "$dir/$CMAKE_CACHE_NAME")" "$dir/$CMAKE_CACHE_NAME"
        done
    done | sort -rn | cut -d' ' -f2- | while read -r cache; do
        sed -n "s/^$INSTALL_PREFIX_VAR:[A-Z]*=//p" "$cache" | head -1
    done
    printf '%s\n' "$C_DEFAULT_INSTALL_PREFIX"
}

find_source_data_dir() {
    # Sets source_data_dir: the first base/ (the C installs, then the other dist dirs here) that
    # holds every required pk3 of the game
    local target_full candidate prefix
    local -a candidates missing required
    local -A seen=()
    read -r -a required <<< "${REQUIRED_PK3S[${GAME_DIRS[$opt_game]}]}"
    target_full="$(realpath -m -- "$1")"
    source_data_dir=""

    mapfile -t candidates < <(
        find_c_install_prefixes | while read -r prefix; do
            [[ -n "$prefix" ]] && printf '%s\n' "$prefix/${GAME_DIRS[$opt_game]}/$GAME_DATA_DIR_NAME"
        done
        for candidate in "$REPO_ROOT"/target/dist/*/"${GAME_DIRS[$opt_game]}/$GAME_DATA_DIR_NAME"; do
            [[ -d "$candidate" ]] && printf '%s\n' "$candidate"
        done
    )
    for candidate in "${candidates[@]}"; do
        [[ -d "$candidate" ]] || continue
        candidate="$(realpath -m -- "$candidate")"
        [[ "$candidate" == "$target_full" || -n "${seen[$candidate]:-}" ]] && continue
        seen[$candidate]=1
        mapfile -t missing < <(get_missing_files "$candidate" "${required[@]}")
        if (( ${#missing[@]} == 0 )); then
            write_ok "Found game data: $candidate"
            source_data_dir="$candidate"
            return
        fi
        write_warn "$candidate is missing $(join_by ', ' "${missing[@]}") - skipping it."
    done
}

link_data_file() {
    # Hard-links the file when source and destination share a filesystem (and LINK_SAME_VOLUME
    # is set), symlinks it otherwise or when that fails
    local source="$1" dest_dir="$2"
    local dest="$dest_dir/$(basename -- "$source")"
    if [[ "$LINK_SAME_VOLUME" == true && "$(stat -c %d -- "$source")" == "$(stat -c %d -- "$dest_dir")" ]]; then
        if ln -- "$source" "$dest" 2>/dev/null; then
            write_ok "Linked $source -> $dest"
            return
        fi
    fi
    if ln -s -- "$source" "$dest"; then
        write_ok "Symlinked $source -> $dest"
    else
        write_err "Could not link $source -> $dest_dir"
    fi
}

check_game_data() {
    # Links the source's missing pk3 files into <game dir>/base (after asking), then checks the
    # required ones; exits when one is still missing
    local data_dir="$game_dir/$GAME_DATA_DIR_NAME" name
    local -a required missing_required source_names to_link still_missing paks
    read -r -a required <<< "${REQUIRED_PK3S[${GAME_DIRS[$opt_game]}]}"
    source_data_dir=""

    mapfile -t missing_required < <(get_missing_files "$data_dir" "${required[@]}")
    if (( ${#missing_required[@]} > 0 )); then
        write_warn "Game data missing from $data_dir: $(join_by ', ' "${missing_required[@]}")"
        find_source_data_dir "$data_dir"
    fi

    if [[ -n "$source_data_dir" ]]; then
        mapfile -t source_names < <(find "$source_data_dir" -maxdepth 1 \( -type f -o -type l \) -iname "$PK3_PATTERN" -printf '%f\n' | sort)
        mapfile -t to_link < <(get_missing_files "$data_dir" "${source_names[@]}")
        if (( ${#to_link[@]} > 0 )); then
            if ask_yes_no "$AUTO_COPY_DATA" "Link $(join_by ', ' "${to_link[@]}") from $source_data_dir into $data_dir?"; then
                mkdir -p -- "$data_dir"
                for name in "${to_link[@]}"; do link_data_file "$source_data_dir/$name" "$data_dir"; done
            else
                write_warn "Skipped linking."
            fi
        fi
    elif (( ${#missing_required[@]} > 0 )); then
        write_warn "No C install ($(find_c_install_prefixes | sort -u | sed "s|\$|/${GAME_DIRS[$opt_game]}/$GAME_DATA_DIR_NAME|" | paste -sd, -)) holds $(join_by ', ' "${required[@]}")."
    fi

    mapfile -t still_missing < <(get_missing_files "$data_dir" "${required[@]}")
    if (( ${#still_missing[@]} > 0 )); then
        write_err "Required game data missing from $data_dir: $(join_by ', ' "${still_missing[@]}")"
        write_err "Install the C build with its data ('.openjk'), or link / copy the game's GameData/$GAME_DATA_DIR_NAME/$GAME_DATA_PATTERN in by hand."
        exit 1
    fi
    mapfile -t paks < <(find "$data_dir" -maxdepth 1 \( -type f -o -type l \) -iname "$GAME_DATA_PATTERN" -printf '%f\n' 2>/dev/null | sort)
    write_label "Game data: $data_dir ($(join_by ', ' "${paks[@]}"))"
}

check_mod() {
    # A mod dir found neither in the game's dir nor in the home, but in the C build's home: its
    # libraries / pk3s are linked into the home's mod dir (after asking)
    local effective_home="${home_dir:-$c_home_dir}" source="$c_home_dir/$opt_mod" pattern file
    local -a files=()
    [[ -n "$opt_mod" ]] || return 0
    if [[ -d "$game_dir/$opt_mod" || -d "$effective_home/$opt_mod" ]]; then
        write_label "Mod: $opt_mod ($( [[ -d "$game_dir/$opt_mod" ]] && printf '%s' "$game_dir/$opt_mod" || printf '%s' "$effective_home/$opt_mod"))"
        return 0
    fi
    if [[ ! -d "$source" ]] || $opt_shared_home; then
        write_warn "No mod dir $opt_mod in $game_dir or $effective_home - fs_game $opt_mod may not load it."
        return 0
    fi
    for pattern in "${MOD_LINK_PATTERNS[@]}"; do
        for file in "$source"/$pattern; do [[ -e "$file" ]] && files+=("$file"); done
    done
    if (( ${#files[@]} == 0 )); then
        write_warn "$source holds no $(join_by ' / ' "${MOD_LINK_PATTERNS[@]}") files - fs_game $opt_mod may not load it."
        return 0
    fi
    if $opt_fresh; then
        write_label "Mod: linking $opt_mod's files from $source into the fresh home."
    elif ! ask_yes_no "$AUTO_COPY_DATA" "Mod $opt_mod is only in the C build's home - symlink its $(join_by ', ' "${files[@]##*/}") into $effective_home/$opt_mod?"; then
        write_warn "Skipped - fs_game $opt_mod may not load it (or use sharedhome)."
        return 0
    fi
    mkdir -p -- "$effective_home/$opt_mod"
    for file in "${files[@]}"; do ln -sf -- "$file" "$effective_home/$opt_mod/"; done
    write_ok "Linked into $effective_home/$opt_mod (its configs stay in $source)."
}

get_launch_args() {
    # Sets launch_args: the home, the cvars of the options, then the commands, then the raw args
    local bot
    launch_args=()
    if [[ -n "$home_dir" ]]; then launch_args+=(+set fs_homepath "$home_dir"); fi
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

start_game() {
    # Runs the game from its dist dir in the foreground (it loads its renderer and game libraries
    # and base/ from there)
    local exit_code=0 log_home="${home_dir:-$c_home_dir}"
    (cd "$game_dir" && "./$(basename -- "$exe_path")" "$@") || exit_code=$?

    if (( exit_code == 0 )); then
        write_label "$(basename -- "$exe_path") exited (exit code 0)."
        return
    fi

    write_err "$(basename -- "$exe_path") exited with exit code $exit_code."
    if (( exit_code == EXIT_LOADER_FAILED )); then
        write_err "$EXIT_LOADER_FAILED: it could not be started - a shared library may be missing (ldd $exe_path)."
    fi
    write_err "Add 'log' for qconsole.log in $log_home/${opt_mod:-$GAME_DATA_DIR_NAME} (a crash also writes crashlog-*.txt to $c_home_dir)."
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

write_alt "openjk-rs ($opt_game: ${GAME_INFO[$opt_game]%% (*})..."

resolve_game
get_launch_args

if $opt_print_only; then
    echo
    write_extra "# $ALIAS_NAME $(format_args "${script_args[@]}")"
    if $dist_buildable && { $opt_build || [[ ! -x "$exe_path" ]]; }; then
        write_extra "(cd $(format_shell_arg "$REPO_ROOT") && $BUILD_COMMAND ${build_args[*]})"
    fi
    if $opt_fresh; then write_extra "rm -rf -- $(format_shell_arg "$FRESH_HOME_DIR")"; fi
    write_extra "(cd $(format_shell_arg "$game_dir") && ./$(basename -- "$exe_path")${launch_args[*]:+ $(format_args "${launch_args[@]}")})"
    exit 0
fi

check_build
check_game_data
if $opt_fresh; then reset_fresh_home; fi
if [[ -n "$home_dir" ]]; then
    mkdir -p -- "$home_dir"
    if $opt_fresh || [[ -n "$opt_home" ]]; then
        write_label "Home: $home_dir"
    else
        write_label "Home: $home_dir (the port's own; sharedhome uses the C build's $c_home_dir)"
    fi
else
    write_label "Home: $c_home_dir (shared with the C build)"
fi
check_mod

echo

write_extra "(cd $game_dir && ./$(basename -- "$exe_path")${launch_args[*]:+ $(format_args "${launch_args[@]}")})"
start_game "${launch_args[@]}"
