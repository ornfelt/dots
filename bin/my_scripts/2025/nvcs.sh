#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# nvcs.sh - locate (or build) the nvcs executable and run it, forwarding
#               all arguments.
#
# Scans $code_root_dir/Code2/C#/my_cs/nvcs/src/nvcs/bin/<Config>/<Tfm>/ for the
# nvcs apphost (or nvcs.dll) across every configuration and target framework.
#
# Selection order:
#   1. newest build time (max of mtime / birth time)
#   2. on a tie (within $TIE_TOLERANCE_SECONDS): highest .NET version wins
#   3. still tied: Release beats Debug
#
# If nothing is built, runs `dotnet build` in the project dir, picking the
# newest TargetFramework from the csproj that is installed on this machine.
#
# After a build is chosen, git is asked (cheaply) whether anything under
# $code_root_dir/Code2/C#/my_cs/nvcs/src/nvcs changed after the exe was built -
# both the last commit touching it and any uncommitted/untracked file there. If
# so, it is rebuilt with the SAME config/framework it already had, then run.
#
# All arguments are forwarded verbatim to nvcs:
#     ./nvcs.sh test.py --verbose
# ---------------------------------------------------------------------------

# Everything on the command line belongs to nvcs - capture it before anything else.
SCRIPT_ARGS=("$@")

# ---------------------------------------------------------------------------
# Hard-coded options (intentionally NOT exposed as script arguments)
# ---------------------------------------------------------------------------
USE_RELEASE=false           # true  => `dotnet build -c Release` instead of Debug
DRY_RUN=false               # true  => print the commands instead of running them
TIE_TOLERANCE_SECONDS=5     # build times within this many seconds count as "the same"
CHECK_SOURCES=true          # false => skip the git "sources newer than exe" check
SRC_REL_PATH='src/nvcs'     # path (relative to the repo dir) watched for changes

# ---------------------------------------------------------------------------
# Colored print helpers
# ---------------------------------------------------------------------------
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
DARKGRAY='\033[90m'
write_ok()      { echo -e "${GREEN}${1}${RESET}"; }
write_err()     { echo -e "${RED}${1}${RESET}" >&2; }
write_warn()    { echo -e "${YELLOW}${1}${RESET}"; }
write_info()    { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt(){ echo -e "${MAGENTA}${1}${RESET}"; }
write_dim()     { echo -e "${DARKGRAY}${1}${RESET}"; }

fail() { write_err "ERROR: $1"; exit 1; }

# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

join_by() {
    local d="$1"; shift
    local out="" x
    for x in "$@"; do out+="${out:+$d}$x"; done
    printf '%s' "$out"
}

contains() {
    local needle="$1"; shift
    local x
    for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
    return 1
}

# "net9.0", "net9.0-linux" -> 9000 (major*1000+minor); unparseable -> 0
tfm_version_key() {
    if [[ "$1" =~ ^net([0-9]+)\.([0-9]+) ]]; then
        echo $(( ${BASH_REMATCH[1]} * 1000 + ${BASH_REMATCH[2]} ))
    else
        echo 0
    fi
}

# "9.0.100" / "9.0.0-preview.1" -> "net9.0"
version_to_tfm() {
    if [[ "$1" =~ ^([0-9]+)\.([0-9]+) ]]; then
        echo "net${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
}

# TFMs given as args -> one per line, newest .NET version first
sort_tfms_desc() {
    local t k
    for t in "$@"; do
        [[ -n "$t" ]] || continue
        k="$(tfm_version_key "$t")"
        printf '%s %s\n' "$k" "$t"
    done | sort -rn -k1,1 | awk '{ print $2 }'
}

# ---------------------------------------------------------------------------
# Git freshness helpers
# ---------------------------------------------------------------------------
# Committer date (epoch) of the last commit touching $SRC_REL_PATH; 0 when git
# failed, the dir is not a repo, or that path was never committed.
last_commit_time() {
    local out
    out="$(git -C "$REPO_DIR" log -1 --format=%ct -- "$SRC_REL_PATH" 2>/dev/null)"
    if [[ "$out" =~ ^[0-9]+$ ]]; then echo "$out"; else echo 0; fi
}

# Newest build time among files git reports as dirty/untracked under
# $SRC_REL_PATH. `git log` only sees COMMITTED work, so this covers "edited and
# saved but not committed yet". Sets DIRTY_TIME (0 = none) and DIRTY_FILE.
find_dirty_worktree_change() {
    DIRTY_TIME=0
    DIRTY_FILE=""

    local top entry st p full t
    top="$(git -C "$REPO_DIR" rev-parse --show-toplevel 2>/dev/null)"
    [[ -n "$top" ]] || return 0

    # -z: NUL-separated, so paths with spaces/quotes/# need no unquoting.
    # Porcelain paths are relative to the repo TOP, not to $REPO_DIR.
    while IFS= read -r -d '' entry; do
        st="${entry:0:2}"
        p="${entry:3}"
        # renames/copies emit the original path as an extra field - consume it
        if [[ "$st" == R* || "$st" == C* ]]; then IFS= read -r -d '' _ || true; fi

        [[ -n "$p" ]] || continue
        full="$top/$p"
        [[ -f "$full" ]] || continue          # deletions have nothing to stat

        t="$(file_build_time "$full")"
        if (( t > DIRTY_TIME )); then
            DIRTY_TIME=$t
            DIRTY_FILE="$p"
        fi
    done < <(git -C "$REPO_DIR" status --porcelain -z --untracked-files=all -- "$SRC_REL_PATH" 2>/dev/null)
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
if [[ -z "${code_root_dir:-}" ]]; then
    fail "environment variable 'code_root_dir' is not set."
fi

REPO_DIR="$code_root_dir/Code2/C#/my_cs/nvcs"
PROJECT_DIR="$code_root_dir/Code2/C#/my_cs/nvcs/src/nvcs"
CSPROJ_PATH="$PROJECT_DIR/nvcs.csproj"
BIN_DIR="$PROJECT_DIR/bin"

[[ -d "$PROJECT_DIR" ]] || fail "project dir not found: $PROJECT_DIR"
[[ -f "$CSPROJ_PATH" ]] || fail "csproj not found: $CSPROJ_PATH"

write_info "Project : $PROJECT_DIR"
write_info "Csproj  : $CSPROJ_PATH"

# ---------------------------------------------------------------------------
# 1. Read target framework(s) from the csproj
# ---------------------------------------------------------------------------
csproj_text="$(tr '\n' ' ' < "$CSPROJ_PATH")"
PROJECT_TFMS=()
IS_MULTI_TARGET=false

if [[ "$csproj_text" =~ \<TargetFrameworks\>([^\<]*)\</TargetFrameworks\> ]]; then
    raw_tfms="${BASH_REMATCH[1]}"
    IS_MULTI_TARGET=true
elif [[ "$csproj_text" =~ \<TargetFramework\>([^\<]*)\</TargetFramework\> ]]; then
    raw_tfms="${BASH_REMATCH[1]}"
else
    fail "no <TargetFramework> or <TargetFrameworks> element found in $CSPROJ_PATH"
fi

IFS=';' read -ra _parts <<< "$raw_tfms"
for _p in "${_parts[@]}"; do
    _p="$(trim "$_p")"
    [[ -n "$_p" ]] && PROJECT_TFMS+=("$_p")
done

(( ${#PROJECT_TFMS[@]} > 0 )) || fail "target framework element in $CSPROJ_PATH is empty"

mapfile -t PROJECT_TFMS < <(sort_tfms_desc "${PROJECT_TFMS[@]}")

if $IS_MULTI_TARGET; then
    write_info_alt "Csproj targets MULTIPLE frameworks (${#PROJECT_TFMS[@]}): $(join_by ', ' "${PROJECT_TFMS[@]}")"
else
    write_info_alt "Csproj targets a SINGLE framework: ${PROJECT_TFMS[0]}"
fi

# ---------------------------------------------------------------------------
# 2. Discover installed SDKs / runtimes
# ---------------------------------------------------------------------------
command -v dotnet >/dev/null 2>&1 || fail "'dotnet' was not found on PATH - install the .NET SDK."

sdk_lines="$(dotnet --list-sdks 2>/dev/null)"
runtime_lines="$(dotnet --list-runtimes 2>/dev/null)"

SDK_TFMS=()
RUNTIME_TFMS=()

while read -r _ver; do
    [[ -n "$_ver" ]] || continue
    _tfm="$(version_to_tfm "$_ver")"
    [[ -n "$_tfm" ]] && ! contains "$_tfm" "${SDK_TFMS[@]}" && SDK_TFMS+=("$_tfm")
done < <(echo "$sdk_lines" | awk '{ print $1 }')

while read -r _ver; do
    [[ -n "$_ver" ]] || continue
    _tfm="$(version_to_tfm "$_ver")"
    [[ -n "$_tfm" ]] && ! contains "$_tfm" "${RUNTIME_TFMS[@]}" && RUNTIME_TFMS+=("$_tfm")
done < <(echo "$runtime_lines" | awk '$1 == "Microsoft.NETCore.App" { print $2 }')

if (( ${#SDK_TFMS[@]} == 0 && ${#RUNTIME_TFMS[@]} == 0 )); then
    fail "could not detect any installed .NET SDKs or runtimes (dotnet --list-sdks / --list-runtimes returned nothing)."
fi

(( ${#SDK_TFMS[@]} ))     && mapfile -t SDK_TFMS     < <(sort_tfms_desc "${SDK_TFMS[@]}")
(( ${#RUNTIME_TFMS[@]} )) && mapfile -t RUNTIME_TFMS < <(sort_tfms_desc "${RUNTIME_TFMS[@]}")

INSTALLED_TFMS=()
for _t in "${SDK_TFMS[@]}" "${RUNTIME_TFMS[@]}"; do
    contains "$_t" "${INSTALLED_TFMS[@]}" || INSTALLED_TFMS+=("$_t")
done
mapfile -t INSTALLED_TFMS < <(sort_tfms_desc "${INSTALLED_TFMS[@]}")

if (( ${#SDK_TFMS[@]} )); then
    write_info "Installed SDKs     : $(join_by ', ' "${SDK_TFMS[@]}")"
else
    write_info "Installed SDKs     : (none)"
fi
if (( ${#RUNTIME_TFMS[@]} )); then
    write_info "Installed runtimes : $(join_by ', ' "${RUNTIME_TFMS[@]}")"
else
    write_info "Installed runtimes : (none)"
fi
write_info "Latest installed .NET framework: ${INSTALLED_TFMS[0]}"

# csproj vs machine
MATCHING_TFMS=()
for _t in "${PROJECT_TFMS[@]}"; do
    contains "$_t" "${INSTALLED_TFMS[@]}" && MATCHING_TFMS+=("$_t")
done

if (( ${#MATCHING_TFMS[@]} == 0 )); then
    write_err "ERROR: none of the csproj target frameworks are installed on this machine."
    write_err "  csproj    : $(join_by ', ' "${PROJECT_TFMS[@]}")"
    write_err "  installed : $(join_by ', ' "${INSTALLED_TFMS[@]}")"
    exit 1
fi
mapfile -t MATCHING_TFMS < <(sort_tfms_desc "${MATCHING_TFMS[@]}")
write_ok "Usable framework(s) (csproj n installed): $(join_by ', ' "${MATCHING_TFMS[@]}")"

# ---------------------------------------------------------------------------
# 3. Find existing builds
# ---------------------------------------------------------------------------
# Parallel arrays, one slot per candidate.
CAND_PATH=(); CAND_CONFIG=(); CAND_TFM=(); CAND_KEY=()
CAND_REL=();  CAND_TIME=();   CAND_LABEL=(); CAND_VIA_DOTNET=()

file_build_time() {
    local f="$1" m b
    m="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
    b="$(stat -c %W "$f" 2>/dev/null || echo 0)"
    [[ "$b" =~ ^[0-9]+$ ]] || b=0
    if (( b > m )); then echo "$b"; else echo "$m"; fi
}

find_build_candidates() {
    CAND_PATH=(); CAND_CONFIG=(); CAND_TFM=(); CAND_KEY=()
    CAND_REL=();  CAND_TIME=();   CAND_LABEL=(); CAND_VIA_DOTNET=()

    [[ -d "$BIN_DIR" ]] || return 0

    local f dir base rel key config tfm via
    while IFS= read -r -d '' f; do
        dir="$(dirname "$f")"
        base="$(basename "$f")"

        # An apphost next to the dll wins; only fall back to `dotnet nvcs.dll`.
        if [[ "$base" == "nvcs.dll" && -x "$dir/nvcs" ]]; then continue; fi
        via=false
        [[ "$base" == "nvcs.dll" ]] && via=true

        rel="${f#"$BIN_DIR"/}"
        IFS='/' read -ra _rp <<< "$rel"
        (( ${#_rp[@]} >= 3 )) || continue    # expect <Config>/<Tfm>/nvcs

        config="${_rp[0]}"
        tfm="${_rp[1]}"
        key="$(tfm_version_key "$tfm")"
        if (( key == 0 )); then
            write_warn "Skipping (unrecognized framework dir): $f"
            continue
        fi

        CAND_PATH+=("$f")
        CAND_CONFIG+=("$config")
        CAND_TFM+=("$tfm")
        CAND_KEY+=("$key")
        if [[ "${config,,}" == "release" ]]; then CAND_REL+=(1); else CAND_REL+=(0); fi
        CAND_TIME+=("$(file_build_time "$f")")
        CAND_LABEL+=("$config/$tfm")
        CAND_VIA_DOTNET+=("$via")
    done < <(find "$BIN_DIR" -type f \( -name 'nvcs' -o -name 'nvcs.dll' \) -print0 2>/dev/null)
}

# Sets BEST_IDX and BEST_REASON.
select_best_build() {
    local n=${#CAND_PATH[@]} i newest cutoff
    local -a tied=()

    newest=0
    for (( i = 0; i < n; i++ )); do
        (( CAND_TIME[i] > newest )) && newest=${CAND_TIME[i]}
    done
    cutoff=$(( newest - TIE_TOLERANCE_SECONDS ))

    for (( i = 0; i < n; i++ )); do
        (( CAND_TIME[i] >= cutoff )) && tied+=("$i")
    done

    # Among the tied ones: highest TFM, then Release, then newest.
    BEST_IDX=${tied[0]}
    for i in "${tied[@]}"; do
        if   (( CAND_KEY[i]  > CAND_KEY[BEST_IDX]  )); then BEST_IDX=$i
        elif (( CAND_KEY[i] == CAND_KEY[BEST_IDX] )); then
            if   (( CAND_REL[i]  > CAND_REL[BEST_IDX]  )); then BEST_IDX=$i
            elif (( CAND_REL[i] == CAND_REL[BEST_IDX] )) && (( CAND_TIME[i] > CAND_TIME[BEST_IDX] )); then BEST_IDX=$i
            fi
        fi
    done

    # Explain the choice.
    if (( n == 1 )); then
        BEST_REASON="it is the only build present."
    elif (( ${#tied[@]} == 1 )); then
        local runner_idx=-1
        for (( i = 0; i < n; i++ )); do
            (( i == BEST_IDX )) && continue
            if (( runner_idx < 0 )) || (( CAND_TIME[i] > CAND_TIME[runner_idx] )); then runner_idx=$i; fi
        done
        local gap=$(( CAND_TIME[BEST_IDX] - CAND_TIME[runner_idx] ))
        BEST_REASON="it is the most recently compiled build (${gap}s newer than the next one, ${CAND_LABEL[runner_idx]})."
    else
        local -a why=() labels=()
        local higher=0 lower=0 debugs=0
        for i in "${tied[@]}"; do
            labels+=("${CAND_LABEL[i]}")
            (( CAND_KEY[i] > CAND_KEY[BEST_IDX] )) && higher=1
            (( CAND_KEY[i] < CAND_KEY[BEST_IDX] )) && lower=1
            (( CAND_REL[i] == 0 )) && debugs=1
        done
        (( higher == 0 && lower == 1 )) && why+=("highest .NET version (${CAND_TFM[BEST_IDX]})")
        (( CAND_REL[BEST_IDX] == 1 && debugs == 1 )) && why+=("Release preferred over Debug")
        (( ${#why[@]} == 0 )) && why+=("first by build time")
        BEST_REASON="${#tied[@]} builds were compiled within ${TIE_TOLERANCE_SECONDS}s of each other ($(join_by ', ' "${labels[@]}")), so it won on: $(join_by ', ' "${why[@]}")."
    fi
}

find_build_candidates

# ---------------------------------------------------------------------------
# 4. Build if nothing exists
# ---------------------------------------------------------------------------
if (( ${#CAND_PATH[@]} == 0 )); then
    if [[ -d "$BIN_DIR" ]]; then
        write_warn "No nvcs executable found under $BIN_DIR - building."
    else
        write_warn "No bin dir at $BIN_DIR - building."
    fi

    build_config="Debug"
    $USE_RELEASE && build_config="Release"
    build_tfm="${MATCHING_TFMS[0]}"

    dotnet_args=(build -c "$build_config")
    if $IS_MULTI_TARGET; then
        dotnet_args+=(-f "$build_tfm")
        write_info "Multi-target csproj -> building only $build_tfm (latest installed match)."
    else
        write_info "Single-target csproj -> no -f needed (framework is $build_tfm)."
    fi

    write_info_alt "Running: dotnet ${dotnet_args[*]}   (cwd: $PROJECT_DIR)"

    if $DRY_RUN; then
        write_warn "DRY_RUN enabled - build skipped."
        exit 0
    fi

    ( cd "$PROJECT_DIR" && dotnet "${dotnet_args[@]}" )
    build_exit=$?
    (( build_exit == 0 )) || fail "dotnet build failed with exit code $build_exit."
    write_ok "Build succeeded ($build_config / $build_tfm)."

    find_build_candidates
    (( ${#CAND_PATH[@]} > 0 )) || fail "build reported success but no nvcs executable was found under $BIN_DIR."
else
    write_info "Found ${#CAND_PATH[@]} build(s):"
    for i in $(for (( j = 0; j < ${#CAND_PATH[@]}; j++ )); do echo "${CAND_TIME[j]} $j"; done | sort -rn -k1,1 | awk '{ print $2 }'); do
        printf "${CYAN}  %-22s %s  %s${RESET}\n" \
            "${CAND_LABEL[i]}" \
            "$(date -d "@${CAND_TIME[i]}" '+%Y-%m-%d %H:%M:%S')" \
            "${CAND_PATH[i]}"
    done
fi

# ---------------------------------------------------------------------------
# 5. Pick the winner and validate it can run here
# ---------------------------------------------------------------------------
select_best_build

BEST_PATH="${CAND_PATH[BEST_IDX]}"
BEST_TFM="${CAND_TFM[BEST_IDX]}"

write_ok "Chosen : ${CAND_LABEL[BEST_IDX]} -> $BEST_PATH"
write_ok "Reason : $BEST_REASON"
if [[ "${CAND_VIA_DOTNET[BEST_IDX]}" == "true" ]]; then
    write_warn "No apphost in that dir - launching via 'dotnet $BEST_PATH'."
fi

if (( ${#RUNTIME_TFMS[@]} )) && ! contains "$BEST_TFM" "${RUNTIME_TFMS[@]}"; then
    write_err "ERROR: the selected build targets $BEST_TFM, but that runtime is not installed."
    write_err "  selected  : $BEST_PATH"
    write_err "  installed : $(join_by ', ' "${RUNTIME_TFMS[@]}")"
    write_err "  Install the .NET ${BEST_TFM#net} runtime, or rebuild for one of the installed versions."
    exit 1
fi

# ---------------------------------------------------------------------------
# 5b. Rebuild when sources changed after the chosen exe was built
# ---------------------------------------------------------------------------
BEST_TIME="${CAND_TIME[BEST_IDX]}"
BEST_CONFIG="${CAND_CONFIG[BEST_IDX]}"

if ! $CHECK_SOURCES; then
    write_warn "Source freshness check disabled ($SRC_REL_PATH not inspected)."
elif ! command -v git >/dev/null 2>&1; then
    write_warn "'git' was not found on PATH - skipping the source freshness check."
elif [[ ! -d "$REPO_DIR" ]]; then
    write_warn "Repo dir not found: $REPO_DIR - skipping the source freshness check."
else
    write_info "Exe built : $(date -d "@$BEST_TIME" '+%Y-%m-%d %H:%M:%S')"
    write_info "Checking '$SRC_REL_PATH' in $REPO_DIR for newer changes..."

    commit_time="$(last_commit_time)"
    find_dirty_worktree_change      # sets DIRTY_TIME / DIRTY_FILE

    newest_src=0
    newest_what=""

    if (( commit_time > 0 )); then
        write_info "  last commit touching it : $(date -d "@$commit_time" '+%Y-%m-%d %H:%M:%S')"
        newest_src=$commit_time
        newest_what="last commit touching $SRC_REL_PATH"
    else
        write_warn "  no git history for $SRC_REL_PATH (not a repo, or nothing committed there)."
    fi

    if (( DIRTY_TIME > 0 )); then
        write_info "  newest uncommitted edit : $(date -d "@$DIRTY_TIME" '+%Y-%m-%d %H:%M:%S')  ($DIRTY_FILE)"
        if (( DIRTY_TIME > newest_src )); then
            newest_src=$DIRTY_TIME
            newest_what="uncommitted change in $DIRTY_FILE"
        fi
    fi

    if (( newest_src > BEST_TIME )); then
        stale_by=$(( newest_src - BEST_TIME ))
        write_warn "STALE: sources are ${stale_by}s newer than the exe ($newest_what) - recompiling."

        rebuild_args=(build -c "$BEST_CONFIG")
        if $IS_MULTI_TARGET; then
            rebuild_args+=(-f "$BEST_TFM")
            write_info "Reusing the chosen exe's options: $BEST_CONFIG / $BEST_TFM."
        else
            write_info "Reusing the chosen exe's configuration: $BEST_CONFIG (single-target csproj, no -f)."
        fi

        write_info_alt "Running: dotnet ${rebuild_args[*]}   (cwd: $PROJECT_DIR)"

        if $DRY_RUN; then
            write_warn "DRY_RUN enabled - rebuild skipped."
        else
            ( cd "$PROJECT_DIR" && dotnet "${rebuild_args[@]}" )
            rebuild_exit=$?
            (( rebuild_exit == 0 )) || fail "dotnet build failed with exit code $rebuild_exit."
            [[ -e "$BEST_PATH" ]] || fail "rebuild reported success but $BEST_PATH no longer exists."

            CAND_TIME[BEST_IDX]="$(file_build_time "$BEST_PATH")"
            write_ok "Rebuild succeeded (${CAND_LABEL[BEST_IDX]}) - exe now $(date -d "@${CAND_TIME[BEST_IDX]}" '+%Y-%m-%d %H:%M:%S')."
        fi
    elif (( newest_src > 0 )); then
        write_ok "Up to date: nothing under $SRC_REL_PATH is newer than the exe."
    fi
fi

# ---------------------------------------------------------------------------
# 6. Run, forwarding all script arguments
# ---------------------------------------------------------------------------
if (( ${#SCRIPT_ARGS[@]} )); then
    write_info_alt "Forwarding args: ${SCRIPT_ARGS[*]}"
else
    write_info_alt "No args to forward."
fi

RUN_CMD=()
[[ "${CAND_VIA_DOTNET[BEST_IDX]}" == "true" ]] && RUN_CMD+=(dotnet)
RUN_CMD+=("$BEST_PATH")

if $DRY_RUN; then
    write_warn "DRY_RUN enabled - would run: ${RUN_CMD[*]} ${SCRIPT_ARGS[*]}"
    exit 0
fi

if (( ${#SCRIPT_ARGS[@]} )); then
    "${RUN_CMD[@]}" "${SCRIPT_ARGS[@]}"
else
    "${RUN_CMD[@]}"
fi
exit $?
