#!/usr/bin/env bash
# cenilla.sh - starts cenilla (benilla, the WoW 1.12.1 client, translated to C on the gfx library)
# from one of its CMake build trees; a tree without the client is configured and built first.
#
# Usage examples (args in any order, case insensitive; `.cenilla help` lists them all):
# the optimized build (build-rel) on the gfx library's default window and device:
# .cenilla
#
# pick the gfx device and / or window:
# .cenilla vk sdl
# .cenilla gl3 glfw
#
# the sanitized debug build (build/), rebuilt first, with the debug panel open:
# .cenilla debug build panel
#
# log in as the checkout's .probe-identity, on another server and realm:
# .cenilla probe host=192.168.1.10 realm=Elysium
#
# a server-less capture on lavapipe, and the list of capture scenarios:
# .cenilla capture=water-noon vk soft
# .cenilla capture=list
#
# the engine viewer over Goldshire:
# .cenilla at=-9460,62
#
# any other env var (an upper-case name with an underscore) as it is:
# .cenilla WOW_MSAA=4 WOW_FARCLIP=800
#
# print the bash line for this run instead of running it:
# .cenilla vk debug print

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

REPO_ROOT="$code_root_dir/Code2/Wow/tools/cenilla"
BUILD_TIME_FORMAT="%Y-%m-%d %H:%M:%S"

# The build trees (docs/RUNNING.md), picked by name; `tree=<dir>` takes any other build dir as it
# is. A missing tree is configured with its args; pgo is tools/pgo.sh's (it trains on a live
# session), so it is not configured here. The names shared with benilla.sh mean the same there:
# release / rel the default optimized build, debug, player, and ship the fastest one.
DEFAULT_TREE="rel"
TREE_NAMES=(rel debug pgo player clang)
declare -A TREE_DIRS=([rel]=build-rel [debug]=build [pgo]=build-release [player]=build-player [clang]=build-clang)
declare -A TREE_ALIASES=([release]=rel [relwithdebinfo]=rel [dev]=debug [ship]=pgo)
declare -A TREE_INFO=(
    [rel]="RelWithDebInfo, no sanitizers: the playable build (also: release)"
    [debug]="Debug with ASan + UBSan: slow, catches bugs (also: dev)"
    [pgo]="Release from a PGO profile, made by tools/pgo.sh (also: ship)"
    [player]="Debug, CENILLA_DEV=OFF: no dev tools"
    [clang]="Debug + sanitizers, built with clang"
)
CMAKE_GENERATOR_ARGS=(-G Ninja)
declare -A TREE_CONFIGURE_ARGS=(
    [rel]="-DCMAKE_BUILD_TYPE=RelWithDebInfo"
    [debug]="-DCMAKE_BUILD_TYPE=Debug"
    [player]="-DCMAKE_BUILD_TYPE=Debug -DCENILLA_DEV=OFF"
    [clang]="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=clang"
)
PGO_SCRIPT="tools/pgo.sh"
CMAKE_CACHE_NAME="CMakeCache.txt"
# gcc needs its temp files inside the build tree when /tmp is full (docs/RUNNING.md)
BUILD_TMP_SUBDIR="tmp"
EXE_SUBDIR="bin"
CLIENT_EXE_NAME="cenilla"
WORLDVIEW_EXE_NAME="cenilla-worldview"

# The gfx library (cmake/gfx.cmake): the tree's cached GFX_DIR, else $GFX_DIR, else gfx_benilla
# when it exists, else gfx; GFX_CONFIGURATION, else Release when built, else Debug. The build
# copies it beside the client (a relink copies it again).
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
# A capture writes into the repo; build/ is gitignored there (captures hold Blizzard imagery)
CAPTURE_OUT_SUBDIR="build/capture"
CAPTURE_LIST="list"
SANITIZER_ENV="ASAN_OPTIONS=detect_leaks=0"
SOFT_ENV=(LIBGL_ALWAYS_SOFTWARE=1 VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json)
VALIDATE_ENV=(VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation)
# Exit code of a process the loader could not start (e.g. a missing shared library)
EXIT_LOADER_FAILED=127

# Launch options (show_help)
ALIAS_NAME=".cenilla"
HELP_TOKENS=(help h)
PRINT_TOKENS=(print onlyprint showcmd)
GFX_DEVICES=(gl4 gl3 gles3 vk d3d11 d3d12)
declare -A GFX_DEVICE_ALIASES=([vulkan]=vk [dx11]=d3d11 [dx12]=d3d12)
GFX_WINDOWS=(x11 sdl glfw win32)
OPTION_VALUE_SEPARATOR="="
ENV_ARG_PATTERN='^[A-Z][A-Z0-9]*_[A-Z0-9_]*='

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
    write_alt "cenilla - start cenilla from a build tree under $REPO_ROOT (configured and built when missing)"
    cat <<EOF

Usage: $ALIAS_NAME [options] [VAR_NAME=value...]
Options are case insensitive, in any order, with or without leading dashes.

Build tree (default $DEFAULT_TREE):
EOF
    for name in "${TREE_NAMES[@]}"; do
        printf '  %-8s %-14s %s\n' "$name" "${TREE_DIRS[$name]}/" "${TREE_INFO[$name]}"
    done
    cat <<EOF
  tree=<dir>             any other build dir (build-tsan, build-gfxnew, ...), not configured here
  build                  build the tree first (cmake --build: relinks and copies a newer gfx library)

gfx backends (WOW_GFX_DEVICE / WOW_GFX_WINDOW; unset, the library's first):
  $(join_by ' | ' "${GFX_DEVICES[@]}")   (vulkan = vk, dx11 / dx12 = d3d11 / d3d12)
  $(join_by ' | ' "${GFX_WINDOWS[@]}")
  d3d11 / d3d12 / win32 are Windows only; a name the library lacks stops the boot, listing its names.

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

The gfx library must be built first: $GFX_DLL_ROOT/${GFX_DIR_NAMES[0]}/bin/<Release|Debug>_x64/$GFX_LIB_NAME.
A sanitized tree gets $SANITIZER_ENV.

Examples:
  $ALIAS_NAME vk sdl panel
  $ALIAS_NAME debug build probe
  $ALIAS_NAME capture=felwood-night gl4 soft
  $ALIAS_NAME worldview at=-9460,62 vk
EOF
}

read_options() {
    # Sets the opt_* launch options from the script args; exits on an unknown one
    opt_help=false; opt_print_only=false; opt_tree=""; opt_tree_dir=""; opt_build=false
    opt_device=""; opt_window=""; opt_panel=false; opt_hud=false; opt_worldview=false; opt_at=""
    opt_host=""; opt_realm=""; opt_char=""; opt_probe=false; opt_nosound=false; opt_unattended=false
    opt_capture=""; opt_out=""; opt_fps=""; opt_exit=""; opt_soft=false; opt_validate=false
    opt_data=""; opt_data_set=false; opt_env=()

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
        if [[ -n "$name" && -n "${TREE_ALIASES[$name]:-}" ]]; then name="${TREE_ALIASES[$name]}"; fi

        if in_list "$name" "${HELP_TOKENS[@]}"; then opt_help=true
        elif in_list "$name" "${PRINT_TOKENS[@]}"; then opt_print_only=true
        elif in_list "$name" "${GFX_DEVICES[@]}"; then opt_device="$name"
        elif in_list "$name" "${GFX_WINDOWS[@]}"; then opt_window="$name"
        elif in_list "$name" "${TREE_NAMES[@]}"; then opt_tree="$name"
        elif [[ "$name" == "tree" && -n "$value" ]]; then opt_tree_dir="$value"
        elif [[ "$name" == "build" ]]; then opt_build=true
        elif [[ "$name" == "panel" ]]; then opt_panel=true
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
        elif [[ "$name" == "data" && -n "$value" ]]; then opt_data="$(realpath -m -- "$value")"; opt_data_set=true
        else
            write_err "Unknown arg: $raw (tree= / at= / host= / realm= / char= / capture= / out= / fps= / exit= need a value) - see '$ALIAS_NAME help'."
            exit 1
        fi
    done

    if [[ -n "$opt_tree" && -n "$opt_tree_dir" ]]; then
        write_warn "tree=$opt_tree_dir is used - ignoring $opt_tree."
        opt_tree=""
    fi
    if [[ -z "$opt_tree" && -z "$opt_tree_dir" ]]; then opt_tree="$DEFAULT_TREE"; fi
    if [[ -n "$opt_out" && -z "$opt_capture" ]]; then write_warn "out= is for a capture - ignoring it."; fi
    if $opt_worldview && [[ -n "$opt_capture" ]]; then
        write_warn "A capture runs in the client - ignoring worldview / at=."
        opt_worldview=false; opt_at=""
    fi
}

resolve_tree() {
    # Sets tree_dir, exe_path and cache_path from the options
    if [[ -n "$opt_tree_dir" ]]; then
        if [[ "$opt_tree_dir" == /* ]]; then tree_dir="$opt_tree_dir"; else tree_dir="$REPO_ROOT/$opt_tree_dir"; fi
    else
        tree_dir="$REPO_ROOT/${TREE_DIRS[$opt_tree]}"
    fi

    local exe_name="$CLIENT_EXE_NAME"
    if $opt_worldview; then exe_name="$WORLDVIEW_EXE_NAME"; fi
    exe_path="$tree_dir/$EXE_SUBDIR/$exe_name"
    cache_path="$tree_dir/$CMAKE_CACHE_NAME"
}

cache_value() {
    # cache_value <name> - the tree's cached value of a CMake variable (empty when not cached)
    [[ -f "$cache_path" ]] || return 0
    sed -n "s/^$1:[A-Z]*=//p" "$cache_path" | head -1
}

resolve_gfx_library() {
    # Sets gfx_lib: the library the tree links (see GFX_DLL_ROOT above)
    local gfx_dir config name
    gfx_dir="$(cache_value GFX_DIR)"
    [[ -n "$gfx_dir" ]] || gfx_dir="${GFX_DIR:-}"
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
        write_warn "The gfx library is newer than the copy beside the client - add 'build' to relink and copy it."
    else
        write_warn "The copy beside the client differs from $gfx_lib (another GFX_DIR / configuration?)."
    fi
}

test_sanitized_tree() {
    # True when the tree is a Debug build with CENILLA_SANITIZE on
    [[ "$(cache_value CMAKE_BUILD_TYPE)" == "Debug" && "$(cache_value CENILLA_SANITIZE)" == "ON" ]]
}

configure_tree() {
    # Configures a missing named tree; pgo and tree= dirs are not configured here
    if [[ -f "$cache_path" ]]; then return; fi
    if [[ -n "$opt_tree_dir" ]]; then
        write_err "$tree_dir is not a configured build tree."
        exit 1
    fi
    if [[ -z "${TREE_CONFIGURE_ARGS[$opt_tree]:-}" ]]; then
        write_err "$tree_dir is not built - run $PGO_SCRIPT from $REPO_ROOT (it trains on a live session)."
        exit 1
    fi

    local -a configure_args
    read -r -a configure_args <<<"${TREE_CONFIGURE_ARGS[$opt_tree]}"
    write_warn "No $tree_dir yet - configuring it."
    write_extra "cmake -S $REPO_ROOT -B $tree_dir ${CMAKE_GENERATOR_ARGS[*]} ${configure_args[*]}"
    if ! cmake -S "$REPO_ROOT" -B "$tree_dir" "${CMAKE_GENERATOR_ARGS[@]}" "${configure_args[@]}"; then
        write_err "Configure failed."
        exit 1
    fi
}

build_tree() {
    # Builds the client (or the engine viewer) in the tree
    local target build_tmp
    target="$(basename -- "$exe_path")"
    build_tmp="$tree_dir/$BUILD_TMP_SUBDIR"
    mkdir -p -- "$build_tmp"

    write_extra "TMPDIR=$build_tmp cmake --build $tree_dir --target $target"
    if ! TMPDIR="$build_tmp" cmake --build "$tree_dir" --target "$target"; then
        write_err "Build failed."
        exit 1
    fi
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
    # read_probe_field <name> - one field of .probe-identity (quotes stripped), as tools/smoke.sh reads it
    sed -n "s/^[[:space:]]*$1=[\"]*\\([^\"]*\\)[\"]*[[:space:]]*\$/\\1/p" "$REPO_ROOT/$PROBE_IDENTITY_NAME" | head -1
}

get_run_env() {
    # Sets run_env: the env vars of the options, as NAME=value
    local field value
    run_env=()
    probe_env_start=-1
    run_env+=("$WOW_DATA_VAR=$wow_data")
    if test_sanitized_tree && [[ -z "${ASAN_OPTIONS+set}" ]]; then run_env+=("$SANITIZER_ENV"); fi

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
    [[ -n "$opt_window" ]] && run_env+=("WOW_GFX_WINDOW=$opt_window")
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
    local -a configure_args
    echo
    write_extra "# $ALIAS_NAME $(format_args "${script_args[@]}")"
    if [[ ! -f "$cache_path" && -z "$opt_tree_dir" && -n "${TREE_CONFIGURE_ARGS[$opt_tree]:-}" ]]; then
        read -r -a configure_args <<<"${TREE_CONFIGURE_ARGS[$opt_tree]}"
        write_extra "cmake -S $(format_shell_arg "$REPO_ROOT") -B $(format_shell_arg "$tree_dir") ${CMAKE_GENERATOR_ARGS[*]} ${configure_args[*]}"
    fi
    if $opt_build || [[ ! -f "$exe_path" ]]; then
        write_extra "TMPDIR=$(format_shell_arg "$tree_dir/$BUILD_TMP_SUBDIR") cmake --build $(format_shell_arg "$tree_dir") --target $(basename -- "$exe_path")"
    fi
    write_extra "(cd $(format_shell_arg "$REPO_ROOT") && env $(format_env_args "${run_env[@]}") $(format_shell_arg "$exe_path"))"
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
read_options "$@"
if $opt_help; then
    show_help
    exit 0
fi

write_alt "cenilla..."

if [[ ! -d "$REPO_ROOT" ]]; then
    write_err "cenilla repo not found: $REPO_ROOT"
    exit 1
fi

capture_out=""
resolve_wow_data
resolve_tree
resolve_gfx_library
get_run_env

if $opt_print_only; then
    show_launch_command
    exit 0
fi

check_gfx_library
configure_tree
if $opt_build || [[ ! -f "$exe_path" ]]; then
    if [[ ! -f "$exe_path" ]]; then write_warn "No $exe_path yet - building it."; fi
    build_tree
fi
if [[ ! -f "$exe_path" ]]; then
    write_err "The build finished but $exe_path is still missing."
    exit 1
fi

write_label "Using: $exe_path"
write_label "  built $(date -r "$exe_path" +"$BUILD_TIME_FORMAT")"
check_gfx_copy
# The env again: a tree configured above now has its cache (the sanitizer check reads it)
get_run_env

echo

write_extra "env $(format_env_args "${run_env[@]}") $exe_path"
start_client
