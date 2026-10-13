#!/usr/bin/env bash
# benilla.sh - starts benilla (the Rust WoW 1.12.1 client on trimmed Bevy and the gfx library)
# from one of its cargo profiles; a profile without the client is built with cargo first.
#
# Usage examples (args in any order, case insensitive; `.benilla help` lists them all):
# the release build (target/release) on the gfx library's default window and device:
# .benilla
#
# pick the gfx device and / or window:
# .benilla vk sdl
# .benilla gl3 glfw
#
# the play profile (release + incremental), rebuilt first, with the debug panel open:
# .benilla play build panel
#
# log in as the checkout's .probe-identity, on another server and realm:
# .benilla probe host=192.168.1.10 realm=Elysium
#
# a server-less capture on lavapipe, and the list of capture scenarios:
# .benilla capture=water-noon vk soft
# .benilla capture=list
#
# the engine viewer over Goldshire:
# .benilla at=-9460,62
#
# any other env var (an upper-case name with an underscore) as it is:
# .benilla WOW_MSAA=4 WOW_FARCLIP=800
#
# print the bash line for this run instead of running it:
# .benilla vk debug print

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

REPO_ROOT="$code_root_dir/Code2/Wow/tools/benilla"
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

# The install is read from $WOW_DATA, else the repo's WoW link; WOW_DATA is set to this when unset
WOW_DATA_DIR="${wow_classic_dir:+$wow_classic_dir/Data}"
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
    write_alt "benilla - start benilla from a cargo profile under $REPO_ROOT (built when missing)"
    cat <<EOF

Usage: $ALIAS_NAME [options] [VAR_NAME=value...]
Options are case insensitive, in any order, with or without leading dashes.

Profile (default $DEFAULT_PROFILE):
EOF
    for name in "${PROFILE_NAMES[@]}"; do
        printf '  %-8s %-22s %s\n' "$name" "${PROFILE_DIRS[$name]}/" "${PROFILE_INFO[$name]}"
    done
    cat <<EOF
  build                  cargo build first (copies a newer gfx library beside the client too)

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
  VAR_NAME=value         any env var with an upper-case name holding an underscore, as it is
  $(join_by ' | ' "${PRINT_TOKENS[@]}")  print the bash line for this run instead of running it
  $(join_by ' | ' "${HELP_TOKENS[@]}") (also -help, --help)  this help

The gfx library must be built first: $GFX_DLL_ROOT/${GFX_DIR_NAMES[0]}/bin/<Release|Debug>_x64/$GFX_LIB_NAME.
WOW_DATA is set to ${WOW_DATA_DIR:-\$wow_classic_dir/Data} when unset.

Examples:
  $ALIAS_NAME vk sdl panel
  $ALIAS_NAME play build probe
  $ALIAS_NAME capture=felwood-night gl4 soft
  $ALIAS_NAME worldview at=-9460,62 vk
EOF
}

read_options() {
    # Sets the opt_* launch options from the script args; exits on an unknown one
    opt_help=false; opt_print_only=false; opt_profile="$DEFAULT_PROFILE"; opt_build=false
    opt_device=""; opt_window=""; opt_panel=false; opt_hud=false; opt_worldview=false; opt_at=""
    opt_host=""; opt_realm=""; opt_char=""; opt_probe=false; opt_nosound=false; opt_unattended=false
    opt_capture=""; opt_out=""; opt_fps=""; opt_exit=""; opt_soft=false; opt_validate=false
    opt_env=()

    local raw name value
    for raw in "$@"; do
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
        else
            write_err "Unknown arg: $raw (at= / host= / realm= / char= / capture= / out= / fps= / exit= need a value) - see '$ALIAS_NAME help'."
            exit 1
        fi
    done

    if [[ -n "$opt_out" && -z "$opt_capture" ]]; then write_warn "out= is for a capture - ignoring it."; fi
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
    # Sets build_args: cargo's args building the binary of the profile
    local -a profile_args
    read -r -a profile_args <<<"${PROFILE_BUILD_ARGS[$opt_profile]}"
    build_args=(build "${profile_args[@]}" -p "$package")
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
    write_ok "Build done."
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
    if [[ -z "${WOW_DATA+set}" && -n "$WOW_DATA_DIR" ]]; then run_env+=("WOW_DATA=$WOW_DATA_DIR"); fi

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
    if $opt_build || [[ ! -f "$exe_path" ]]; then
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
read_options "$@"
if $opt_help; then
    show_help
    exit 0
fi

write_alt "benilla..."

if [[ ! -d "$REPO_ROOT" ]]; then
    write_err "benilla repo not found: $REPO_ROOT"
    exit 1
fi

capture_out=""
resolve_exe
resolve_gfx_library
get_run_env

if $opt_print_only; then
    show_launch_command
    exit 0
fi

check_gfx_library
if $opt_build || [[ ! -f "$exe_path" ]]; then
    if [[ ! -f "$exe_path" ]]; then write_warn "No $exe_path yet - building it."; fi
    build_client
fi
if [[ ! -f "$exe_path" ]]; then
    write_err "The build finished but $exe_path is still missing."
    exit 1
fi

write_label "Using: $exe_path"
write_label "  built $(date -r "$exe_path" +"$BUILD_TIME_FORMAT")"
check_gfx_copy

echo

write_extra "env $(format_env_args "${run_env[@]}") $exe_path"
start_client
