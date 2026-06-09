#!/usr/bin/env bash
# tmux_copy_latest.sh
# Copy the latest command input/output from tmux scrollback to primary selection.
# Mirrors WezTerm's 'trigger-vim-with-scrollback-copy-latest' event.
# Also writes debug files:
#   ~/wez_text_dbg.txt  - raw scrollback
#   ~/wez_text.txt      - all parsed input/output blocks

LOG_FILE="$HOME/tmux_copy_log.txt"
DEBUG_FILE="$HOME/tmux_text_dbg.txt"
PARSED_FILE="$HOME/tmux_text.txt"
# Prompt pattern: matches "jonas:<anything>$ "
# Uses [$] for literal dollar sign in awk ERE
PROMPT_PATTERN='^jonas:.*[$] '

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

log "--- tmux_copy_latest.sh started ---"

# Capture entire scrollback from current pane
text=$(tmux capture-pane -p -S - -E -)
if [ -z "$text" ]; then
    log "Empty scrollback"
    tmux display-message "No scrollback content"
    exit 0
fi

# Write raw scrollback to debug file
printf '%s\n' "$text" > "$DEBUG_FILE"
log "Wrote raw scrollback to $DEBUG_FILE ($(wc -l < "$DEBUG_FILE") lines)"

# Write all parsed input/output blocks to wez_text.txt
printf '%s\n' "$text" | awk -v pattern="$PROMPT_PATTERN" '
BEGIN { n = 0 }
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
    for (i = 1; i <= n; i++) {
        printf "Input:\n%s\n", input[i]
        if (output[i] != "") printf "Output:\n%s\n", output[i]
        printf "\n"
    }
}
' > "$PARSED_FILE"
log "Wrote parsed blocks to $PARSED_FILE"

# Extract latest entry with non-empty output for clipboard
result=$(printf '%s\n' "$text" | awk -v pattern="$PROMPT_PATTERN" '
BEGIN { n = 0 }
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
    for (i = n; i >= 1; i--) {
        tmp = output[i]
        gsub(/[[:space:]]/, "", tmp)
        if (tmp != "") {
            printf "Input:\n%s\n\nOutput:\n%s", input[i], output[i]
            exit
        }
    }
}
')

if [ -n "$result" ]; then
    if command -v xclip &>/dev/null; then
        #printf '%s' "$result" | xclip -selection primary >/dev/null 2>&1 &
        printf '%s' "$result" | xclip -selection clipboard >/dev/null 2>&1 &
        log "Copied latest entry to clipboard via xclip"
    elif command -v xsel &>/dev/null; then
        printf '%s' "$result" | xsel --clipboard >/dev/null 2>&1 &
        log "Copied latest entry to clipboard via xsel"
    elif command -v wl-copy &>/dev/null; then
        printf '%s' "$result" | wl-copy >/dev/null 2>&1 &
        log "Copied latest entry to clipboard via wl-copy"
    else
        tmux set-buffer -- "$result"
        log "Copied latest entry to tmux buffer (no clipboard tool available)"
    fi
    tmux display-message "Copied latest input/output"
else
    log "No valid input/output found in scrollback"
    tmux display-message "No Input/Output Found"
fi

log "--- tmux_copy_latest.sh finished ---"
