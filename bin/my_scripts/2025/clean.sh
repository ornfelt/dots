#!/usr/bin/env bash
# clean.sh - Remove build artifacts for various programming languages.
#
# Usage:
#   ./clean.sh LANGUAGE [OPTIONS]
#
# Examples:
#   ./clean.sh cs
#   ./clean.sh rust --git-root
#   ./clean.sh java --path ~/projects/app
#   ./clean.sh cpp --no-recurse

# -- Color helpers -------------------------------------------------------------

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
DARKGRAY='\033[90m'

write_ok()       { echo -e "${GREEN}${1}${RESET}"; }
write_err()      { echo -e "${RED}${1}${RESET}"; }
write_warn()     { echo -e "${YELLOW}${1}${RESET}"; }
write_info()     { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt() { echo -e "${MAGENTA}${1}${RESET}"; }

confirm_action() {
    echo -en "${YELLOW}${1} ${RESET}[y/N] "
    read -r response
    [[ "${response,,}" =~ ^(y|yes)$ ]]
}

# -- Language map --------------------------------------------------------------

resolve_language() {
    case "${1,,}" in
        c)                   echo 'c' ;;
        cs|'c#'|csharp)      echo 'csharp' ;;
        cpp|'c++')           echo 'cpp' ;;
        go|golang)           echo 'go' ;;
        java)                echo 'java' ;;
        js|javascript)       echo 'javascript' ;;
        ts|typescript)       echo 'typescript' ;;
        py|python)           echo 'python' ;;
        rust|rs)             echo 'rust' ;;
        *)                   echo '' ;;
    esac
}

# -- Help ----------------------------------------------------------------------

show_help() {
    write_info 'clean.sh - Remove build artifacts for various programming languages'
    echo ''
    write_info 'USAGE'
    echo '  ./clean.sh LANGUAGE [OPTIONS]'
    echo ''
    write_info 'LANGUAGES'
    echo '  c                       C       (.o .obj .out .a build/)'
    echo '  cs | c# | csharp       C#      (bin/ obj/)'
    echo '  cpp | c++              C++     (.o .obj .out .a build/)'
    echo '  go | golang            Go      (go clean caches)'
    echo '  java                   Java    (.class target/ build/)'
    echo '  js | javascript        JS      (dist/ node_modules/)'
    echo '  ts | typescript        TS      (dist/ .tsbuildinfo node_modules/)'
    echo '  py | python            Python  (__pycache__/ .pyc dist/)'
    echo '  rust | rs              Rust    (target/)'
    echo ''
    write_info 'OPTIONS'
    echo '  -p, --path DIR     Use the specified directory instead of the current one'
    echo '  -n, --no-recurse   Only clean in the target directory (skip subdirectories)'
    echo '  -g, --git-root     Use the git repository root as the working directory'
    echo '  -h, --help         Show this help'
    echo ''
    write_info 'EXAMPLES'
    echo '  ./clean.sh cs                              # Clean C# from cwd recursively'
    echo '  ./clean.sh rust --git-root                  # Clean Rust from repo root'
    echo '  ./clean.sh java --path ~/projects/app       # Clean Java in specified dir'
    echo '  ./clean.sh cpp --no-recurse                 # Clean C++ (current dir only)'
    echo '  ./clean.sh js                               # Clean JS artifacts + optional node_modules'
    echo '  ./clean.sh -h                               # Show this help'
}

# -- Removal helpers -----------------------------------------------------------

remove_matching_dirs() {
    local base_path="$1"
    local recurse="$2"
    local ask_confirm="$3"
    local confirm_msg="$4"
    shift 4
    local names=("$@")

    local depth_args=()
    [[ "$recurse" != "true" ]] && depth_args=(-maxdepth 1)

    # Build find -name expression with -o
    local name_expr=()
    local first=true
    for name in "${names[@]}"; do
        $first || name_expr+=(-o)
        name_expr+=(-name "$name")
        first=false
    done

    local dirs=()
    while IFS= read -r -d '' d; do
        dirs+=("$d")
    done < <(find "$base_path" "${depth_args[@]}" -type d \( "${name_expr[@]}" \) -print0 2>/dev/null)

    if [[ ${#dirs[@]} -eq 0 ]]; then
        local label
        label=$(IFS=', '; echo "${names[*]}")
        write_info "  No directories found matching: $label"
        return
    fi

    for d in "${dirs[@]}"; do
        echo -e "    Found: ${DARKGRAY}${d}${RESET}"
    done

    if [[ "$ask_confirm" == "true" ]]; then
        local msg="${confirm_msg:-Delete ${#dirs[@]} director(y/ies)?}"
        if ! confirm_action "  $msg"; then
            write_warn '  Skipped.'
            return
        fi
    fi

    local count=0
    for d in "${dirs[@]}"; do
        [[ ! -d "$d" ]] && continue
        if rm -rf "$d" 2>/dev/null; then
            write_ok "  Deleted: $d"
            ((count++)) || true
        else
            write_err "  Failed to delete: $d"
        fi
    done
    [[ $count -gt 0 ]] && write_info "  Removed $count director(y/ies)."
}

remove_matching_files() {
    local base_path="$1"
    local recurse="$2"
    shift 2
    local extensions=("$@")

    local depth_args=()
    [[ "$recurse" != "true" ]] && depth_args=(-maxdepth 1)

    # Build find -name expression: -name "*.ext" -o -name "*.ext2" ...
    local name_expr=()
    local first=true
    for ext in "${extensions[@]}"; do
        $first || name_expr+=(-o)
        name_expr+=(-name "*${ext}")
        first=false
    done

    local files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$base_path" "${depth_args[@]}" -type f \( "${name_expr[@]}" \) -print0 2>/dev/null)

    if [[ ${#files[@]} -eq 0 ]]; then
        local label
        label=$(IFS=', '; echo "${extensions[*]}")
        write_info "  No files found matching: $label"
        return
    fi

    local count=0
    for f in "${files[@]}"; do
        [[ ! -f "$f" ]] && continue
        if rm -f "$f" 2>/dev/null; then
            write_ok "  Deleted: $f"
            ((count++)) || true
        else
            write_err "  Failed to delete: $f"
        fi
    done
    [[ $count -gt 0 ]] && write_info "  Removed $count file(s)."
}

remove_dirs_by_suffix() {
    local base_path="$1"
    local suffix="$2"
    local recurse="$3"

    local depth_args=()
    [[ "$recurse" != "true" ]] && depth_args=(-maxdepth 1)

    local dirs=()
    while IFS= read -r -d '' d; do
        dirs+=("$d")
    done < <(find "$base_path" "${depth_args[@]}" -type d -name "*${suffix}" -print0 2>/dev/null)

    [[ ${#dirs[@]} -eq 0 ]] && return

    local count=0
    for d in "${dirs[@]}"; do
        [[ ! -d "$d" ]] && continue
        if rm -rf "$d" 2>/dev/null; then
            write_ok "  Deleted: $d"
            ((count++)) || true
        else
            write_err "  Failed to delete: $d"
        fi
    done
    [[ $count -gt 0 ]] && write_info "  Removed $count '*${suffix}' director(y/ies)."
}

run_clean_command() {
    local base_path="$1"
    local description="$2"
    shift 2
    local cmd=("$@")
    local display="${cmd[*]}"

    if ! confirm_action "  Run '$display' ($description)?"; then
        return
    fi

    write_info "  Running: $display"
    local output
    local rc=0
    output=$(cd "$base_path" && "${cmd[@]}" 2>&1) || rc=$?
    if [[ -n "$output" ]]; then
        echo "$output" | sed 's/^/    /'
    fi
    if [[ $rc -eq 0 ]]; then
        write_ok "  $display completed."
    else
        write_err "  $display failed (exit code $rc)."
    fi
}

# -- Language cleaners ---------------------------------------------------------

clean_c() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning C artifacts --'

    write_info '  Removing compiled object / binary files...'
    remove_matching_files "$base_path" "$recurse" \
        .o .obj .out .a .so .dylib .dll .lib .exe .pdb .d .gch

    write_info '  Checking for build/ directory...'
    remove_matching_dirs "$base_path" "$recurse" true "Delete 'build' director(y/ies)?" build

    if [[ -f "$base_path/Makefile" || -f "$base_path/makefile" ]]; then
        run_clean_command "$base_path" 'run Makefile clean target' make clean
    fi
}

clean_cpp() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning C++ artifacts --'

    write_info '  Removing compiled object / binary files...'
    remove_matching_files "$base_path" "$recurse" \
        .o .obj .out .a .so .dylib .dll .lib .exe .pdb .d .gch .pch

    write_info '  Checking for build/ directory...'
    remove_matching_dirs "$base_path" "$recurse" true "Delete 'build' director(y/ies)?" build

    local has_makefile=false
    local has_cmake=false
    [[ -f "$base_path/Makefile" || -f "$base_path/makefile" ]] && has_makefile=true
    [[ -f "$base_path/CMakeLists.txt" ]] && has_cmake=true

    if $has_makefile; then
        run_clean_command "$base_path" 'run Makefile clean target' make clean
    fi
    if $has_cmake && ! $has_makefile; then
        run_clean_command "$base_path" 'cmake build clean' cmake --build build --target clean
    fi
}

clean_csharp() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning C# artifacts --'

    write_info '  Removing bin/ and obj/ directories...'
    remove_matching_dirs "$base_path" "$recurse" false '' bin obj

    local has_sln=false
    local has_csproj=false
    [[ -n "$(find "$base_path" -maxdepth 1 -name '*.sln' -print -quit 2>/dev/null)" ]] && has_sln=true
    [[ -n "$(find "$base_path" -maxdepth 1 -name '*.csproj' -print -quit 2>/dev/null)" ]] && has_csproj=true

    if $has_sln || $has_csproj; then
        run_clean_command "$base_path" 'dotnet SDK clean' dotnet clean
    fi
}

clean_go() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning Go artifacts --'

    write_info '  Removing compiled binaries...'
    remove_matching_files "$base_path" "$recurse" .exe .test

    if [[ -f "$base_path/go.mod" ]]; then
        run_clean_command "$base_path" 'remove object files and cached binaries' go clean
    fi

    run_clean_command "$base_path" 'clear build cache' go clean -cache
    run_clean_command "$base_path" 'clear test cache' go clean -testcache
}

clean_java() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning Java artifacts --'

    write_info '  Removing .class files...'
    remove_matching_files "$base_path" "$recurse" .class

    write_info '  Removing build output directories (target/ build/ out/)...'
    remove_matching_dirs "$base_path" "$recurse" false '' target build out

    # Maven
    if [[ -f "$base_path/pom.xml" ]]; then
        run_clean_command "$base_path" 'Maven clean' mvn clean
    fi

    # Gradle
    local has_gradle=false
    [[ -f "$base_path/build.gradle" ]]     && has_gradle=true
    [[ -f "$base_path/build.gradle.kts" ]] && has_gradle=true

    if $has_gradle; then
        if [[ -x "$base_path/gradlew" ]]; then
            run_clean_command "$base_path" 'Gradle wrapper clean' ./gradlew clean
        else
            run_clean_command "$base_path" 'Gradle clean' gradle clean
        fi
    fi
}

clean_node_modules() {
    local base_path="$1"
    local recurse="$2"

    write_info '  Checking for package directories...'

    local depth_args=()
    [[ "$recurse" != "true" ]] && depth_args=(-maxdepth 1)

    local nm_dirs=()
    while IFS= read -r -d '' d; do
        nm_dirs+=("$d")
    done < <(find "$base_path" "${depth_args[@]}" -type d -name 'node_modules' -prune -print0 2>/dev/null)

    if [[ ${#nm_dirs[@]} -gt 0 ]]; then
        for d in "${nm_dirs[@]}"; do
            echo -e "    Found: ${DARKGRAY}${d}${RESET}"
        done
        if confirm_action "  Delete ${#nm_dirs[@]} node_modules director(y/ies)?"; then
            local count=0
            for d in "${nm_dirs[@]}"; do
                [[ ! -d "$d" ]] && continue
                if rm -rf "$d" 2>/dev/null; then
                    write_ok "  Deleted: $d"
                    ((count++)) || true
                else
                    write_err "  Failed: $d"
                fi
            done
            [[ $count -gt 0 ]] && write_info "  Removed $count node_modules director(y/ies)."
        else
            write_warn '  Skipped node_modules.'
        fi
    else
        write_info '  No node_modules directories found.'
    fi
}

clean_node_cache() {
    local base_path="$1"

    local pm='npm'
    [[ -f "$base_path/yarn.lock" ]]      && pm='yarn'
    [[ -f "$base_path/pnpm-lock.yaml" ]] && pm='pnpm'

    case "$pm" in
        npm)  run_clean_command "$base_path" 'clear npm cache'  npm cache clean --force ;;
        yarn) run_clean_command "$base_path" 'clear yarn cache' yarn cache clean ;;
        pnpm) run_clean_command "$base_path" 'prune pnpm store' pnpm store prune ;;
    esac
}

clean_javascript() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning JavaScript artifacts --'

    write_info '  Removing build output directories...'
    remove_matching_dirs "$base_path" "$recurse" false '' \
        dist .cache .parcel-cache .next .nuxt .output .turbo coverage .nyc_output

    clean_node_modules "$base_path" "$recurse"
    clean_node_cache "$base_path"
}

clean_typescript() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning TypeScript artifacts --'

    write_info '  Removing build output directories...'
    remove_matching_dirs "$base_path" "$recurse" false '' \
        dist out .cache .parcel-cache .next .nuxt .output .turbo coverage .nyc_output

    write_info '  Removing .tsbuildinfo files...'
    remove_matching_files "$base_path" "$recurse" .tsbuildinfo

    clean_node_modules "$base_path" "$recurse"
    clean_node_cache "$base_path"
}

clean_python() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning Python artifacts --'

    write_info '  Removing .pyc / .pyo files...'
    remove_matching_files "$base_path" "$recurse" .pyc .pyo

    write_info '  Removing cache and build directories...'
    remove_matching_dirs "$base_path" "$recurse" false '' \
        __pycache__ .pytest_cache .mypy_cache .ruff_cache .tox htmlcov \
        dist build .eggs

    write_info '  Removing *.egg-info directories...'
    remove_dirs_by_suffix "$base_path" '.egg-info' "$recurse"

    write_info '  Removing .coverage files...'
    remove_matching_files "$base_path" "$recurse" .coverage

    run_clean_command "$base_path" 'clear pip download cache' pip cache purge
}

clean_rust() {
    local base_path="$1"
    local recurse="$2"

    write_info_alt '-- Cleaning Rust artifacts --'

    write_info '  Removing target/ directories...'
    remove_matching_dirs "$base_path" "$recurse" false '' target

    if [[ -f "$base_path/Cargo.toml" ]]; then
        run_clean_command "$base_path" 'cargo clean' cargo clean
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

# -- 1. Parse arguments --------------------------------------------------------

LANGUAGE=''
CUSTOM_PATH=''
NO_RECURSE=false
GIT_ROOT=false

if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--path)
            if [[ $# -lt 2 ]]; then
                write_err '--path requires a directory argument.'
                exit 1
            fi
            CUSTOM_PATH="$2"
            shift 2
            ;;
        -n|--no-recurse)
            NO_RECURSE=true
            shift
            ;;
        -g|--git-root)
            GIT_ROOT=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            write_err "Unknown option: $1"
            echo ''
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$LANGUAGE" ]]; then
                LANGUAGE="$1"
            else
                write_err "Unexpected argument: $1"
                echo ''
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# -- 2. Help / language check --------------------------------------------------

lang_lower="${LANGUAGE,,}"

if [[ -z "$LANGUAGE" || "$lang_lower" =~ ^(help|--help|-h)$ ]]; then
    show_help
    exit 0
fi

lang=$(resolve_language "$lang_lower")

if [[ -z "$lang" ]]; then
    write_err "Unknown language: '$LANGUAGE'"
    echo ''
    show_help
    exit 1
fi

# -- 3. Resolve working directory ----------------------------------------------

if [[ -n "$CUSTOM_PATH" && "$GIT_ROOT" == "true" ]]; then
    write_err 'Cannot use both --path and --git-root at the same time.'
    exit 1
fi

if [[ "$GIT_ROOT" == "true" ]]; then
    work_dir=$(git rev-parse --show-toplevel 2>/dev/null) || {
        write_err 'Not inside a git repository. Cannot use --git-root.'
        exit 1
    }
elif [[ -n "$CUSTOM_PATH" ]]; then
    if [[ ! -d "$CUSTOM_PATH" ]]; then
        write_err "Path does not exist or is not a directory: $CUSTOM_PATH"
        exit 1
    fi
    work_dir=$(cd "$CUSTOM_PATH" && pwd)
else
    work_dir=$(pwd)
fi

# -- 4. Git-repo safety check -------------------------------------------------

recurse=true
[[ "$NO_RECURSE" == "true" ]] && recurse=false

if [[ "$recurse" == "true" ]]; then
    in_git_repo=false
    (cd "$work_dir" && git rev-parse --is-inside-work-tree >/dev/null 2>&1) && in_git_repo=true

    if [[ "$in_git_repo" == "false" ]]; then
        write_warn "WARNING: '$work_dir' is not inside a git repository."
        if ! confirm_action '  Proceed with recursive cleanup?'; then
            write_warn 'Aborted.'
            exit 0
        fi
    fi
fi

# -- 5. Run language cleaner ---------------------------------------------------

echo ''
write_info_alt "Language : $lang"
write_info_alt "Directory: $work_dir"
write_info_alt "Recursive: $recurse"
echo ''

case "$lang" in
    c)          clean_c          "$work_dir" "$recurse" ;;
    csharp)     clean_csharp     "$work_dir" "$recurse" ;;
    cpp)        clean_cpp        "$work_dir" "$recurse" ;;
    go)         clean_go         "$work_dir" "$recurse" ;;
    java)       clean_java       "$work_dir" "$recurse" ;;
    javascript) clean_javascript "$work_dir" "$recurse" ;;
    typescript) clean_typescript "$work_dir" "$recurse" ;;
    python)     clean_python     "$work_dir" "$recurse" ;;
    rust)       clean_rust       "$work_dir" "$recurse" ;;
esac

echo ''
write_ok 'Cleanup complete.'
