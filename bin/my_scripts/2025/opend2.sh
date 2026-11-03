#!/bin/bash
# opend2.sh - runs OpenDiablo2 ($code_root_dir/Code2/Go/OpenDiablo2) with config.json's MpqPath
# pointing at a local d2 dir (<d2 dir>/d2video holds the MPQs).
#
# Usage example (no args):
# .opend2
#
# The d2 dir is the first of $HOME/Downloads/d2 and /mnt/new/d2 that exists. When neither does, it
# is copied into $HOME/Downloads from a mounted HDD (/media/2024/d2, /media2/2024/d2, or one level
# deeper, like /media/$USER/<drive>/2024/d2) when there is room for it plus a 5 GB margin.
set -e  # exit immediately if a command exits with a non-zero status

write_label() { printf '\033[90m%s\033[0m\n' "$1"; } # Dark gray
write_info()  { printf '\033[36m%s\033[0m\n' "$1"; } # Cyan
write_warn()  { printf '\033[33m%s\033[0m\n' "$1"; } # Dark yellow
write_ok()    { printf '\033[32m%s\033[0m\n' "$1"; } # Green
write_err()   { printf '\033[31m%s\033[0m\n' "$1"; } # Red

if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi

OPEND2_DIR="$code_root_dir/Code2/Go/OpenDiablo2"
OPEND2_EXE="OpenDiablo2"
CONFIG_FILE="$HOME/.config/OpenDiablo2/config.json"
D2_DIR_NAME="d2"
MPQ_SUBDIR="d2video"
DOWNLOADS_DIR="$HOME/Downloads"
HDD_D2_SUBPATH="2024/$D2_DIR_NAME"
SPACE_MARGIN_BYTES=$((5 * 1024 * 1024 * 1024))

# Local d2 dirs, checked in this order
DIABLO_DIRS=(
    "$DOWNLOADS_DIR/$D2_DIR_NAME"
    "/mnt/new/$D2_DIR_NAME"
)

# HDD mount points holding 2024/d2: the roots themselves, then one level below them
HDD_ROOTS=("/media" "/media2")

human_size() { numfmt --to=iec --suffix=B "$1"; }

if [ ! -x "$OPEND2_DIR/$OPEND2_EXE" ]; then
    write_err "$OPEND2_DIR/$OPEND2_EXE does not exist. Build it first:"
    write_info "cd $OPEND2_DIR && go build"
    exit 1
fi

D2_DIR=""
for DIR in "${DIABLO_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        D2_DIR="$DIR"
        break
    fi
done

# Not found locally: copy it from a mounted HDD into $DOWNLOADS_DIR
if [ -z "$D2_DIR" ]; then
    write_warn "No local Diablo 2 directory found (checked: ${DIABLO_DIRS[*]}). Looking on mounted HDDs..."

    shopt -s nullglob
    HDD_CANDIDATES=()
    for ROOT in "${HDD_ROOTS[@]}"; do
        HDD_CANDIDATES+=("$ROOT/$HDD_D2_SUBPATH" "$ROOT"/*/"$HDD_D2_SUBPATH")
    done
    HDD_CANDIDATES+=("/media/$USER"/*/"$HDD_D2_SUBPATH")
    shopt -u nullglob

    HDD_D2_DIR=""
    for DIR in "${HDD_CANDIDATES[@]}"; do
        if [ -d "$DIR" ]; then
            HDD_D2_DIR="$DIR"
            break
        fi
    done

    if [ -z "$HDD_D2_DIR" ]; then
        write_err "No Diablo 2 directory found locally (${DIABLO_DIRS[*]}) or on a mounted HDD (${HDD_ROOTS[*]} [/<drive>]/$HDD_D2_SUBPATH)."
        exit 1
    fi

    mkdir -p "$DOWNLOADS_DIR"
    D2_SIZE=$(du -sb "$HDD_D2_DIR" | cut -f1)
    FREE_SPACE=$(df -B1 --output=avail "$DOWNLOADS_DIR" | tail -n 1 | tr -d ' ')
    NEEDED_SPACE=$((D2_SIZE + SPACE_MARGIN_BYTES))
    write_label "Found $HDD_D2_DIR ($(human_size "$D2_SIZE")). Free in $DOWNLOADS_DIR: $(human_size "$FREE_SPACE"), needed (+$(human_size "$SPACE_MARGIN_BYTES") margin): $(human_size "$NEEDED_SPACE")"

    if [ "$FREE_SPACE" -lt "$NEEDED_SPACE" ]; then
        write_err "Not enough disk space to copy $HDD_D2_DIR into $DOWNLOADS_DIR."
        exit 1
    fi

    # Copy into a temporary dir first, so an interrupted copy never looks like a complete d2 dir
    D2_DIR="$DOWNLOADS_DIR/$D2_DIR_NAME"
    PARTIAL_DIR="$D2_DIR.partial"
    if [ -d "$PARTIAL_DIR" ]; then
        write_warn "Removing the leftover $PARTIAL_DIR of an interrupted copy"
        rm -rf "$PARTIAL_DIR"
    fi
    write_info "Copying $HDD_D2_DIR into $D2_DIR..."
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --info=progress2 "$HDD_D2_DIR/" "$PARTIAL_DIR/"
    else
        cp -a "$HDD_D2_DIR" "$PARTIAL_DIR"
    fi
    mv "$PARTIAL_DIR" "$D2_DIR"
    write_ok "Copied $HDD_D2_DIR into $D2_DIR"
fi

MPQ_PATH="$D2_DIR/$MPQ_SUBDIR"
write_label "Using Diablo 2 directory: $D2_DIR"

# Point config.json's MpqPath at it, unless it already does
if [ -f "$CONFIG_FILE" ]; then
    CURRENT_PATH=$(sed -n 's/.*"MpqPath": *"\([^"]*\)".*/\1/p' "$CONFIG_FILE" | head -n 1)
    if ! grep -q '"MpqPath"' "$CONFIG_FILE"; then
        write_warn "$CONFIG_FILE has no MpqPath entry - not updated."
    elif [ "${CURRENT_PATH%/}" = "$MPQ_PATH" ]; then
        write_label "config.json MpqPath is already $MPQ_PATH"
    else
        ESCAPED_NEW_PATH=$(printf '%s' "$MPQ_PATH" | sed 's/[\\&|]/\\&/g')
        sed -i "s|\"MpqPath\": *\"[^\"]*\"|\"MpqPath\": \"$ESCAPED_NEW_PATH\"|" "$CONFIG_FILE"
        write_ok "Updated config.json MpqPath: $CURRENT_PATH -> $MPQ_PATH"
    fi
else
    write_warn "$CONFIG_FILE does NOT exist yet. OpenDiablo2 has not been run yet - run this again after its first run to set MpqPath."
fi

cd "$OPEND2_DIR" && "./$OPEND2_EXE"
