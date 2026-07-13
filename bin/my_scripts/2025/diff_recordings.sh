#!/usr/bin/env bash
set -euo pipefail

# diff_recordings.sh
# Compare recording directories by file metadata (size, duration, dates),
# not just filenames. Reports missing files and name differences.
#
# Example usage:
# Defaults:
#./diff_recordings.sh
#./diff_recordings.sh /media2/recordings /media/recordings
#./diff_recordings.sh /path/a /path/b --no-duration
#./diff_recordings.sh /path/a /path/b --verbose

DIR1="${1:-/media2/recordings}"
DIR2="${2:-/media/recordings}"

USE_DURATION=true
VERBOSE=false

# Parse flags after positional args
shift 2 2>/dev/null || true
for arg in "$@"; do
    case "$arg" in
        --no-duration) USE_DURATION=false ;;
        --verbose)     VERBOSE=true ;;
        *) echo "Unknown flag: $arg"; exit 1 ;;
    esac
done

# ── Colours ──────────────────────────────────────────────────────────────────
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
BOLD='\033[1m'
DIM='\033[2m'

write_ok()   { echo -e "${GREEN}$1${RESET}"; }
write_err()  { echo -e "${RED}$1${RESET}"; }
write_warn() { echo -e "${YELLOW}$1${RESET}"; }
write_info() { echo -e "${CYAN}$1${RESET}"; }
write_dim()  { echo -e "${DIM}$1${RESET}"; }
write_head() { echo -e "\n${BOLD}${CYAN}═══ $1 ═══${RESET}"; }

# ── Dependency check ─────────────────────────────────────────────────────────
if $USE_DURATION; then
    if ! command -v ffprobe &>/dev/null; then
        write_warn "ffprobe not found — install ffmpeg for duration matching."
        write_warn "Falling back to size-only matching (use --no-duration to silence)."
        USE_DURATION=false
    fi
fi

for d in "$DIR1" "$DIR2"; do
    if [[ ! -d "$d" ]]; then
        write_err "Directory not found: $d"
        exit 1
    fi
done

# ── Helpers ──────────────────────────────────────────────────────────────────
human_size() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        local whole=$((bytes / 1073741824))
        local frac=$(( (bytes % 1073741824) * 100 / 1073741824 ))
        printf '%d.%02d GB' "$whole" "$frac"
    elif (( bytes >= 1048576 )); then
        local whole=$((bytes / 1048576))
        local frac=$(( (bytes % 1048576) * 10 / 1048576 ))
        printf '%d.%d MB' "$whole" "$frac"
    elif (( bytes >= 1024 )); then
        printf '%d KB' $((bytes / 1024))
    else
        printf '%d B' "$bytes"
    fi
}

human_duration() {
    local secs=$1
    if (( secs <= 0 )); then echo "n/a"; return; fi
    printf '%02d:%02d:%02d' $((secs/3600)) $(( (secs%3600)/60 )) $((secs%60))
}

human_date() {
    local epoch=$1
    if [[ "$epoch" == "0" || -z "$epoch" ]]; then echo "n/a"; return; fi
    date -d "@$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "n/a"
}

get_duration_secs() {
    local file="$1"
    local raw
    raw=$(ffprobe -v error -show_entries format=duration \
          -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "0")
    printf '%.0f' "$raw" 2>/dev/null || echo "0"
}

# ── Scan a directory ─────────────────────────────────────────────────────────
# Writes tab-separated lines:  relpath \t size \t duration \t mtime \t birth
scan_dir() {
    local base="$1" outfile="$2" label="$3"
    local count=0

    write_info "Scanning $label: $base"

    while IFS= read -r -d '' file; do
        local rel="${file#"$base"/}"
        local size mtime birth dur

        size=$(stat -c '%s' "$file" 2>/dev/null || echo "0")
        mtime=$(stat -c '%Y' "$file" 2>/dev/null || echo "0")
        birth=$(stat -c '%W' "$file" 2>/dev/null || echo "0")
        [[ "$birth" == "0" || -z "$birth" ]] && birth="$mtime"

        if $USE_DURATION; then
            dur=$(get_duration_secs "$file")
        else
            dur="0"
        fi

        printf '%s\t%s\t%s\t%s\t%s\n' "$rel" "$size" "$dur" "$mtime" "$birth" >> "$outfile"
        count=$((count + 1))
        printf '\r  %d files...' "$count" >&2
    done < <(find "$base" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -print0 | sort -z)

    echo "" >&2
    write_info "  Found $count file(s) in $label."
}

# ── Main ─────────────────────────────────────────────────────────────────────
script_start=$(date +%s%3N)

echo ""
write_info "Comparing recordings:"
write_info "  DIR1: $DIR1"
write_info "  DIR2: $DIR2"
write_info "  Duration matching: $USE_DURATION"

tmp1=$(mktemp); tmp2=$(mktemp)
trap 'rm -f "$tmp1" "$tmp2"' EXIT

echo ""
scan_dir "$DIR1" "$tmp1" "DIR1"
scan_dir "$DIR2" "$tmp2" "DIR2"

# ── Build fingerprint maps ──────────────────────────────────────────────────
# Fingerprint = size (+ _duration if enabled)
# Maps:  fingerprint -> list of 0-based line indices in the scan file

declare -A d1_fp_to_idx   # fp -> space-separated indices
declare -A d2_fp_to_idx

# Parallel arrays for dir1
d1_rels=(); d1_sizes=(); d1_durs=(); d1_mtimes=(); d1_births=()
idx=0
while IFS=$'\t' read -r rel size dur mtime birth; do
    d1_rels+=("$rel"); d1_sizes+=("$size"); d1_durs+=("$dur")
    d1_mtimes+=("$mtime"); d1_births+=("$birth")
    fp="$size"
    $USE_DURATION && fp="${fp}_${dur}"
    d1_fp_to_idx["$fp"]+="$idx "
    idx=$((idx + 1))
done < "$tmp1"

# Parallel arrays for dir2
d2_rels=(); d2_sizes=(); d2_durs=(); d2_mtimes=(); d2_births=()
idx=0
while IFS=$'\t' read -r rel size dur mtime birth; do
    d2_rels+=("$rel"); d2_sizes+=("$size"); d2_durs+=("$dur")
    d2_mtimes+=("$mtime"); d2_births+=("$birth")
    fp="$size"
    $USE_DURATION && fp="${fp}_${dur}"
    d2_fp_to_idx["$fp"]+="$idx "
    idx=$((idx + 1))
done < "$tmp2"

# ── Matching phase ───────────────────────────────────────────────────────────
# Track which indices have been matched
declare -A d1_matched  # d1 index -> 1
declare -A d2_matched  # d2 index -> 1

# Results
matched_same_name=()     # "d1_idx:d2_idx"
matched_diff_name=()     # "d1_idx:d2_idx"
matched_diff_date=()     # "d1_idx:d2_idx"  (mtime differs by >2s)

for fp in "${!d1_fp_to_idx[@]}"; do
    read -ra d1_idxs <<< "${d1_fp_to_idx[$fp]}"
    read -ra d2_idxs <<< "${d2_fp_to_idx[$fp]:-}"

    # No match in dir2 for this fingerprint
    [[ ${#d2_idxs[@]} -eq 0 || -z "${d2_idxs[0]}" ]] && continue

    # Try to pair up by basename first (for multi-match fingerprints)
    local_d1_unmatched=()
    local_d2_avail=("${d2_idxs[@]}")

    for i1 in "${d1_idxs[@]}"; do
        name1=$(basename "${d1_rels[$i1]}")
        found=false
        for k in "${!local_d2_avail[@]}"; do
            i2="${local_d2_avail[$k]}"
            name2=$(basename "${d2_rels[$i2]}")
            if [[ "$name1" == "$name2" ]]; then
                matched_same_name+=("$i1:$i2")
                d1_matched[$i1]=1; d2_matched[$i2]=1
                unset 'local_d2_avail[k]'
                found=true
                break
            fi
        done
        if ! $found; then
            local_d1_unmatched+=("$i1")
        fi
    done

    # Remaining: pair by order (fingerprint matched, names differ)
    local_d2_avail_clean=()
    for v in "${local_d2_avail[@]+"${local_d2_avail[@]}"}"; do
        [[ -n "$v" ]] && local_d2_avail_clean+=("$v")
    done

    for j in "${!local_d1_unmatched[@]}"; do
        i1="${local_d1_unmatched[$j]}"
        if [[ $j -lt ${#local_d2_avail_clean[@]} ]]; then
            i2="${local_d2_avail_clean[$j]}"
            matched_diff_name+=("$i1:$i2")
            d1_matched[$i1]=1; d2_matched[$i2]=1
        fi
    done
done

# Check mtime differences for all matched pairs
for pair in "${matched_same_name[@]}" "${matched_diff_name[@]}"; do
    IFS=':' read -r i1 i2 <<< "$pair"
    mt1="${d1_mtimes[$i1]}"; mt2="${d2_mtimes[$i2]}"
    diff=$(( mt1 > mt2 ? mt1 - mt2 : mt2 - mt1 ))
    if (( diff > 2 )); then
        matched_diff_date+=("$pair")
    fi
done

# Collect unmatched
only_in_d1=()
for i in "${!d1_rels[@]}"; do
    [[ -z "${d1_matched[$i]:-}" ]] && only_in_d1+=("$i")
done

only_in_d2=()
for i in "${!d2_rels[@]}"; do
    [[ -z "${d2_matched[$i]:-}" ]] && only_in_d2+=("$i")
done

# ── Report ───────────────────────────────────────────────────────────────────
total_matched=$(( ${#matched_same_name[@]} + ${#matched_diff_name[@]} ))

echo ""
write_head "SUMMARY"
echo -e "  Matched (same name):      ${GREEN}${#matched_same_name[@]}${RESET}"
echo -e "  Matched (name differs):   ${YELLOW}${#matched_diff_name[@]}${RESET}"
echo -e "  Matched (mtime differs):  ${MAGENTA}${#matched_diff_date[@]}${RESET}"
echo -e "  Only in DIR1:             ${RED}${#only_in_d1[@]}${RESET}"
echo -e "  Only in DIR2:             ${RED}${#only_in_d2[@]}${RESET}"
echo -e "  Total matched:            ${CYAN}${total_matched}${RESET}"

# ── Matched with different names ─────────────────────────────────────────────
if [[ ${#matched_diff_name[@]} -gt 0 ]]; then
    write_head "MATCHED — NAME DIFFERS"
    for pair in "${matched_diff_name[@]}"; do
        IFS=':' read -r i1 i2 <<< "$pair"
        sz=$(human_size "${d1_sizes[$i1]}")
        dur_s=$(human_duration "${d1_durs[$i1]}")
        echo -e "  ${CYAN}DIR1:${RESET} ${d1_rels[$i1]}"
        echo -e "  ${MAGENTA}DIR2:${RESET} ${d2_rels[$i2]}"
        echo -e "  ${DIM}size: $sz  |  duration: $dur_s  |  mtime1: $(human_date "${d1_mtimes[$i1]}")  |  mtime2: $(human_date "${d2_mtimes[$i2]}")${RESET}"
        echo ""
    done
fi

# ── Matched with different mtime ─────────────────────────────────────────────
if [[ ${#matched_diff_date[@]} -gt 0 ]]; then
    write_head "MATCHED — MTIME DIFFERS (>2s)"
    for pair in "${matched_diff_date[@]}"; do
        IFS=':' read -r i1 i2 <<< "$pair"
        name1=$(basename "${d1_rels[$i1]}")
        name2=$(basename "${d2_rels[$i2]}")
        echo -e "  ${DIM}file:${RESET} $name1"
        echo -e "    DIR1 mtime: $(human_date "${d1_mtimes[$i1]}")    DIR2 mtime: $(human_date "${d2_mtimes[$i2]}")"
    done
    echo ""
fi

# ── Only in DIR1 ─────────────────────────────────────────────────────────────
if [[ ${#only_in_d1[@]} -gt 0 ]]; then
    write_head "ONLY IN DIR1  ($DIR1)"
    for i in "${only_in_d1[@]}"; do
        sz=$(human_size "${d1_sizes[$i]}")
        dur_s=$(human_duration "${d1_durs[$i]}")
        mt_s=$(human_date "${d1_mtimes[$i]}")
        echo -e "  ${RED}✗${RESET} ${d1_rels[$i]}"
        echo -e "    ${DIM}size: $sz  |  duration: $dur_s  |  mtime: $mt_s${RESET}"
    done
    echo ""
fi

# ── Only in DIR2 ─────────────────────────────────────────────────────────────
if [[ ${#only_in_d2[@]} -gt 0 ]]; then
    write_head "ONLY IN DIR2  ($DIR2)"
    for i in "${only_in_d2[@]}"; do
        sz=$(human_size "${d2_sizes[$i]}")
        dur_s=$(human_duration "${d2_durs[$i]}")
        mt_s=$(human_date "${d2_mtimes[$i]}")
        echo -e "  ${RED}✗${RESET} ${d2_rels[$i]}"
        echo -e "    ${DIM}size: $sz  |  duration: $dur_s  |  mtime: $mt_s${RESET}"
    done
    echo ""
fi

# ── Verbose: all matched same-name ───────────────────────────────────────────
if $VERBOSE && [[ ${#matched_same_name[@]} -gt 0 ]]; then
    write_head "MATCHED — SAME NAME (verbose)"
    for pair in "${matched_same_name[@]}"; do
        IFS=':' read -r i1 i2 <<< "$pair"
        sz=$(human_size "${d1_sizes[$i1]}")
        dur_s=$(human_duration "${d1_durs[$i1]}")
        echo -e "  ${GREEN}✓${RESET} ${d1_rels[$i1]}  ${DIM}($sz, $dur_s)${RESET}"
    done
    echo ""
fi

# ── Copy missing files ───────────────────────────────────────────────────────
total_missing=$(( ${#only_in_d1[@]} + ${#only_in_d2[@]} ))

if (( total_missing > 0 )); then
    echo ""
    write_info "There are $total_missing file(s) that could be copied to sync both directories."
    if [[ ${#only_in_d1[@]} -gt 0 ]]; then
        echo -e "  ${CYAN}→${RESET} ${#only_in_d1[@]} file(s) from DIR1 to DIR2"
    fi
    if [[ ${#only_in_d2[@]} -gt 0 ]]; then
        echo -e "  ${CYAN}→${RESET} ${#only_in_d2[@]} file(s) from DIR2 to DIR1"
    fi
    echo ""
    read -rp "Copy missing files to sync? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        copied=0
        errors=0

        # DIR1 → DIR2
        for i in "${only_in_d1[@]}"; do
            rel="${d1_rels[$i]}"
            src="$DIR1/$rel"
            dst="$DIR2/$rel"
            dst_dir=$(dirname "$dst")
            mkdir -p "$dst_dir"
            if cp --preserve=timestamps -- "$src" "$dst" 2>/dev/null; then
                write_ok "  COPIED → DIR2: $rel"
                copied=$((copied + 1))
            else
                write_err "  ERR copying $rel to DIR2"
                errors=$((errors + 1))
            fi
        done

        # DIR2 → DIR1
        for i in "${only_in_d2[@]}"; do
            rel="${d2_rels[$i]}"
            src="$DIR2/$rel"
            dst="$DIR1/$rel"
            dst_dir=$(dirname "$dst")
            mkdir -p "$dst_dir"
            if cp --preserve=timestamps -- "$src" "$dst" 2>/dev/null; then
                write_ok "  COPIED → DIR1: $rel"
                copied=$((copied + 1))
            else
                write_err "  ERR copying $rel to DIR1"
                errors=$((errors + 1))
            fi
        done

        echo ""
        write_info "Copy done. Copied: $copied  |  Errors: $errors"
    else
        write_dim "Skipped copy."
    fi
fi
script_end=$(date +%s%3N)
elapsed=$((script_end - script_start))
printf "\n${DIM}Total runtime: %d.%03d seconds${RESET}\n" $((elapsed/1000)) $((elapsed%1000))
