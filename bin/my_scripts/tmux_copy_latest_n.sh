#!/usr/bin/env bash
# tmux_copy_latest_n.sh
# Copy the latest N command input/output pairs from tmux scrollback
# to primary selection. Mirrors WezTerm's 'trigger-copy-latest-n' event.
# Entries are separated by "\n---\n\n" just like the WezTerm version.

N=5  # How many entries to copy
LOG_FILE="$HOME/tmux_copy_log.txt"
PROMPT_PATTERN='^jonas:.*[$] '

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

log "--- tmux_copy_latest_n.sh started (N=$N) ---"

# Capture entire scrollback from current pane
text=$(tmux capture-pane -p -S - -E -)
if [ -z "$text" ]; then
    log "Empty scrollback"
    tmux display-message "No scrollback content"
    exit 0
fi

# Parse input/output blocks, collect latest N with non-empty output,
# print in original order separated by \n---\n\n
result=$(printf '%s\n' "$text" | awk -v pattern="$PROMPT_PATTERN" -v count="$N" '
BEGIN {
    n = 0
}
$0 ~ pattern {
    n++
    input[n] = $0
    output[n] = ""
    next
}
n > 0 {
    if (output[n] != "") output[n] = output[n] "\n"
    output[n] = output[n] $0
}
END {
    # Walk backward, collect indices of entries with non-empty output
    found = 0
    for (i = n; i >= 1; i--) {
        tmp = output[i]
        gsub(/[[:space:]]/, "", tmp)
        if (tmp != "") {
            found++
            idx[found] = i
            if (found >= count) break
        }
    }

    if (found == 0) exit

    # Print in original (chronological) order
    for (j = found; j >= 1; j--) {
        i = idx[j]
        if (j < found) printf "\n---\n\n"
        printf "Input:\n%s\n\nOutput:\n%s", input[i], output[i]
    }
}
')

if [ -n "$result" ]; then
    if command -v xclip &>/dev/null; then
        printf '%s' "$result" | xclip -selection clipboard >/dev/null 2>&1 &
        log "Copied latest $N entries to clipboard via xclip"
    elif command -v xsel &>/dev/null; then
        printf '%s' "$result" | xsel --clipboard >/dev/null 2>&1 &
        log "Copied latest $N entries to clipboard via xsel"
    elif command -v wl-copy &>/dev/null; then
        printf '%s' "$result" | wl-copy >/dev/null 2>&1 &
        log "Copied latest $N entries to clipboard via wl-copy"
    else
        tmux set-buffer -- "$result"
        log "Copied latest $N entries to tmux buffer (no clipboard tool available)"
    fi
    tmux display-message "Copied latest $N input/output pairs"
else
    log "No valid input/output found in scrollback"
    tmux display-message "No Input/Output Found"
fi

log "--- tmux_copy_latest_n.sh finished ---"
