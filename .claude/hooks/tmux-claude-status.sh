#!/usr/bin/env bash
# The tmux side of wezterm-claude-status.sh (linux): puts @claude-icon (✨) in
# front of the name of the tmux window this Claude Code session runs in once a
# response has finished, @claude-failed-icon (💥) when the turn ended on an API
# error instead, until that window is looked at; and shows
#   ✨ Finished in gfx (window 3)
# in front of the right status for a few seconds. The tmux version of the tab
# icon and status message ~/.config/wezterm/claude.lua draws in wezterm.
#
# Called by wezterm-claude-status.sh, which reads the Claude Code hook payload:
#   tmux-claude-status.sh done   <label>                Stop
#   tmux-claude-status.sh failed <label> <error type>   StopFailure
#   tmux-claude-status.sh clear                         UserPromptSubmit
# and by tmux, or by hand:
#   tmux-claude-status.sh expire <id>     takes the message down once it timed out
#   tmux-claude-status.sh demo [<pane>]   a mocked failed message, then a finished
#                                         one, to see how they look (no icon)
#
# The state lives in tmux user options, so it goes away with its pane / server:
#   pane    @claude_state       done / failed until the window is looked at
#           @claude_label       the session's dir name, for the "waiting:" part
#           @claude_error       the StopFailure error type
#   global  @claude_message     the message, drawn by #{E:@claude_message_slot}
#                               in status-right (cut to the client's width)
#           @claude_message_id  the run that set it, so an older timer leaves a
#                               newer message alone
# ~/.tmux.conf turns @claude_state into the window icon, clears it when a window
# is looked at, and while its @claude-status switch is on sets @claude_active and
# leaves a flag file next to the server's socket (ACTIVE_FLAG below). Without
# the flag nothing here talks to tmux at all, without @claude_active nothing
# here changes it (except an expire, which only takes a message down).

set -u

action="${1:-done}"

# Message colors: status.lua's success / warning colors in wezterm (gruvbox)
DONE_COLOR='#98971a'
FAILED_COLOR='#fe8019'
# How long the message stays, claude.lua's notification_timeout_ms
MESSAGE_SECONDS=4
# Drawn between the message and the rest of the right status
MESSAGE_SEPARATOR=' '
# Between the session that just finished and the ones still waiting
PART_SEPARATOR='  ·  '
# Between the parts of "rate_limit, session work, window 3, pane 2"
LOCATION_SEPARATOR=', '
# Used while ~/.tmux.conf leaves @claude-icon / @claude-failed-icon unset
DEFAULT_ICON='✨ '
DEFAULT_FAILED_ICON='💥 '
# Shown for a session whose dir name is unknown, as in claude.lua
DEFAULT_LABEL='claude code'

# Hard-coded switch, claude.lua's short_notification: "✨ gfx (w3 p2)" instead
# of "✨ Finished in gfx (window 3, pane 2)" - one letter per location part, no
# "Finished in" and the label cut to SHORT_LABEL_MAX_LENGTH. "Error in" stays,
# so a failure still reads as one next to a finished response.
SHORT_NOTIFICATION=0
SHORT_LOCATION_SEPARATOR=' '
SHORT_LABEL_MAX_LENGTH=15
SHORT_LABEL_ELLIPSIS='…' # U+2026, one cell instead of three

# Session name and error of the mocked messages from "demo"
DEMO_LABEL='demo'
DEMO_ERROR='rate_limit'

# First tmux with display-message -l
DISPLAY_LITERAL_VERSION=3.4

DONE='done'
FAILED='failed'
# Separates the fields of tmux's -F output. A tab: tmux prints control
# characters escaped (\037), a tab in a session name as \t, and the labels come
# from JSON, where a tab is still \t. Split with split_fields, which keeps
# empty fields (read with IFS=tab merges them).
FS=$'\t'
# Absolute, so the tmux timer jobs below don't depend on the cwd they run in,
# and single quoted for their /bin/sh (dash: no $'...', which printf %q may
# write); run-shell expands formats in its command first, hence the doubled #
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
SELF_QUOTED="'${SELF//\'/\'\\\'\'}'"
SELF_QUOTED="${SELF_QUOTED//#/##}"

# ~/.tmux.conf's flag file: "<socket path>.<server pid>.claude-status", both
# taken from $TMUX ("<socket path>,<server pid>,<session>")
TMUX_SOCKET="${TMUX:-}"
TMUX_SOCKET="${TMUX_SOCKET%%,*}"
TMUX_SERVER_PID="${TMUX:-},"
TMUX_SERVER_PID="${TMUX_SERVER_PID#*,}"
TMUX_SERVER_PID="${TMUX_SERVER_PID%%,*}"
ACTIVE_FLAG="${TMUX_SOCKET}.${TMUX_SERVER_PID}.claude-status"

tm() { tmux "$@" 2>/dev/null; }

#--- A value for tmux's argv: tmux takes a trailing ";" for a command separator
# and drops it ("semi;" would be stored as "semi"), "\;" keeps it
tmux_arg() {
  case "$1" in
    *';') printf '%s\\;' "${1%;}" ;;
    *) printf '%s' "$1" ;;
  esac
}

#--- Splits one line of tmux's -F output into FIELDS
split_fields() {
  FIELDS=()
  mapfile -t -d "$FS" FIELDS < <(printf '%s' "$1")
}

#--- Takes the message down, unless a newer one replaced it meanwhile. Checked
# and done in one tmux command, so nothing can slip in between.
expire() {
  local id="$1"
  [ -n "$id" ] || return 0
  tm if -F "#{==:#{@claude_message_id},${id}}" 'set -gu @claude_message ; set -gu @claude_message_id'
}

#--- "tab 3" in wezterm, here "window 3" or, short, "w3"
location_part() {
  local kind="$1" value="$2"
  if [ "$SHORT_NOTIFICATION" = 1 ]; then
    printf '%s%s' "${kind:0:1}" "$value"
  else
    printf '%s %s' "$kind" "$value"
  fi
}

#--- The label, cut to SHORT_LABEL_MAX_LENGTH characters
short_label() {
  local label="$1"
  if [ "${#label}" -le "$SHORT_LABEL_MAX_LENGTH" ]; then
    printf '%s' "$label"
  else
    printf '%s%s' "${label:0:SHORT_LABEL_MAX_LENGTH}" "$SHORT_LABEL_ELLIPSIS"
  fi
}

#--- "gfx (rate_limit, session work, window 3, pane 2)". The session only while
# the server has more than one, the pane only in a window of several, just as
# claude.lua leaves out the wezterm window while there is only one.
describe() {
  local label="$1" error="$2" session="$3" window="$4" pane_index="$5" panes="$6"
  local separator="$LOCATION_SEPARATOR"
  local parts=()
  if [ "$SHORT_NOTIFICATION" = 1 ]; then
    separator="$SHORT_LOCATION_SEPARATOR"
    label="$(short_label "$label")"
  fi
  [ -z "$error" ] || parts+=("$error")
  if [ "${sessions:-1}" -gt 1 ] 2>/dev/null; then
    parts+=("$(location_part session "$session")")
  fi
  parts+=("$(location_part window "$window")")
  if [ "${panes:-1}" -gt 1 ] 2>/dev/null; then
    parts+=("$(location_part pane "$pane_index")")
  fi

  local joined="" part
  for part in "${parts[@]}"; do
    joined="${joined:+$joined$separator}$part"
  done
  printf '%s (%s)' "$label" "$joined"
}

#--- Reads the pane's location and the icons into globals; fails for a pane
# tmux doesn't know (any more). A window linked into several sessions (grouped
# sessions, link-window) is named after one somebody is attached to.
read_pane() {
  local line info=""
  while IFS= read -r line; do
    split_fields "$line"
    [ -n "$info" ] || info="$line"
    if [ "${FIELDS[0]:-0}" != 0 ]; then
      info="$line"
      break
    fi
  done < <(tm list-panes -a -f "#{==:#{pane_id},$1}" -F "#{session_attached}${FS}#{pane_id}${FS}#{window_id}${FS}#{session_name}${FS}#{window_index}${FS}#{pane_index}${FS}#{window_panes}${FS}#{server_sessions}${FS}#{@claude-icon}${FS}#{@claude-failed-icon}")
  [ -n "$info" ] || return 1
  split_fields "$info"
  pane="${FIELDS[1]:-}" window_id="${FIELDS[2]:-}" session="${FIELDS[3]:-}"
  window_index="${FIELDS[4]:-}" pane_index="${FIELDS[5]:-}" window_panes="${FIELDS[6]:-}"
  sessions="${FIELDS[7]:-}" icon="${FIELDS[8]:-}" failed_icon="${FIELDS[9]:-}"
  [ -n "$pane" ] || return 1
  [ -n "$icon" ] || icon="$DEFAULT_ICON"
  [ -n "$failed_icon" ] || failed_icon="$DEFAULT_FAILED_ICON"
}

#--- Whether a client the user is looking at (its terminal has the focus) shows
# the window right now
window_visible() {
  local line
  while IFS= read -r line; do
    split_fields "$line"
    [ "${FIELDS[1]:-}" = "$1" ] || continue
    case ",${FIELDS[0]:-}," in *,focused,*) return 0 ;; esac
  done < <(tm list-clients -F "#{client_flags}${FS}#{window_id}")
  return 1
}

#--- Shows the message of a finished / failed response in front of the right
# status, plus this server's other responses that finished earlier and still
# haven't been looked at (claude.lua's "waiting:" part). Uses the globals
# read_pane() set, and kind / label / error.
announce() {
  local text color
  local fresh
  fresh="$(describe "$label" "$error" "$session" "$window_index" "$pane_index" "$window_panes")"
  if [ "$kind" = "$FAILED" ]; then
    text="${failed_icon}Error in ${fresh}"
    color="$FAILED_COLOR"
  else
    local done_prefix='Finished in '
    [ "$SHORT_NOTIFICATION" != 1 ] || done_prefix=''
    text="${icon}${done_prefix}${fresh}"
    color="$DONE_COLOR"
  fi

  # A window linked into several sessions lists its panes once per session:
  # each pane is named once, after a session somebody is attached to if any
  local line id attached state w_error waiting=""
  local order=()
  local -A described=() described_attached=()
  while IFS= read -r line; do
    split_fields "$line"
    attached="${FIELDS[0]:-0}" id="${FIELDS[1]:-}" state="${FIELDS[2]:-}" w_error="${FIELDS[4]:-}"
    [ -n "$id" ] && [ "$id" != "$pane" ] || continue
    if [ -n "${described[$id]+set}" ]; then
      [ "${described_attached[$id]}" = 0 ] && [ "$attached" != 0 ] || continue
    else
      order+=("$id")
    fi
    [ "$state" = "$FAILED" ] || w_error=""
    described[$id]="$(describe "${FIELDS[3]:-$DEFAULT_LABEL}" "$w_error" "${FIELDS[5]:-}" "${FIELDS[6]:-}" "${FIELDS[7]:-}" "${FIELDS[8]:-}")"
    described_attached[$id]="$attached"
  done < <(tm list-panes -a -f '#{@claude_state}' -F "#{session_attached}${FS}#{pane_id}${FS}#{@claude_state}${FS}#{@claude_label}${FS}#{@claude_error}${FS}#{session_name}${FS}#{window_index}${FS}#{pane_index}${FS}#{window_panes}")
  for id in "${order[@]}"; do
    waiting="${waiting:+$waiting, }${described[$id]}"
  done
  [ -z "$waiting" ] || text="${text}${PART_SEPARATOR}waiting: ${waiting}"

  # The status line draws #[...] as a style and ## as #, so a dir name like
  # "C#" or "#[bold]" has to have its # doubled. ~/.tmux.conf cuts the message
  # to what the client's width leaves next to the git branch
  # (@claude_message_slot), so it can't push the window list out of view.
  local message_id
  message_id="$$-$(date +%s%N)"
  tm set -g @claude_message "#[fg=${color}]${text//#/##}#[default]${MESSAGE_SEPARATOR}" ';' \
     set -g @claude_message_id "$message_id"
  # tmux's own timer, not a sleep here: it outlives this hook process. run-shell
  # shows whatever its command prints, or a failure, in the pane - so it prints
  # nothing and never fails.
  tm run-shell -b -d "$MESSAGE_SECONDS" "bash ${SELF_QUOTED} expire '${message_id}' >/dev/null 2>&1; true"

  # A client with the status line off (alt-b) can't see that: it gets a tmux
  # message instead, which is drawn over the bottom line then (wezterm falls
  # back to a toast the same way). That is drawn with #[...] styles and ## too,
  # hence the doubled # again; -l (tmux 3.4+) keeps formats out of it. 3.3 has
  # no -l, so there the formats halve the doubled # once more: only a "##" in a
  # dir name comes out as a single #.
  local literal=""
  while IFS= read -r line; do
    split_fields "$line"
    [ "${FIELDS[1]:-}" = off ] || continue
    [ -n "$literal" ] || literal="$(tm display -p "#{e|>=|f|0:#{s/[^0-9.]//:version},${DISPLAY_LITERAL_VERSION}}")"
    if [ "$literal" = 1 ]; then
      tm display-message -c "${FIELDS[0]:-}" -l -d "$((MESSAGE_SECONDS * 1000))" "${text//#/##}"
    else
      tm display-message -c "${FIELDS[0]:-}" -d "$((MESSAGE_SECONDS * 1000))" "${text//#/##}"
    fi
  done < <(tm list-clients -F "#{client_name}${FS}#{status}")
}

#--- Stop / StopFailure: marks the pane and announces it
mark() {
  kind="$1"
  label="${2:-$DEFAULT_LABEL}"
  error="${3:-}"
  # A tab or a newline would split the label's field / line in tmux's -F output
  # (only possible with the PWD fallback, the payload's cwd keeps them escaped)
  label="${label//[[:cntrl:]]/ }"
  error="${error//[[:cntrl:]]/ }"
  [ -n "${TMUX_PANE:-}" ] || return 0
  read_pane "$TMUX_PANE" || return 0
  if [ "$kind" = "$FAILED" ]; then
    [ -n "$error" ] || error="unknown"
  else
    error=""
  fi

  # The user is looking at the window: no icon (claude.lua likewise drops the
  # marker of the active tab right after announcing it). One state per pane, a
  # failure replaces a finished one and vice versa.
  if window_visible "$window_id"; then
    tm set -pu -t "$pane" @claude_state
  elif [ "$kind" = "$FAILED" ]; then
    tm set -p -t "$pane" @claude_state "$FAILED" ';' set -p -t "$pane" @claude_label "$(tmux_arg "$label")" ';' \
       set -p -t "$pane" @claude_error "$(tmux_arg "$error")"
  else
    tm set -p -t "$pane" @claude_state "$DONE" ';' set -p -t "$pane" @claude_label "$(tmux_arg "$label")" ';' \
       set -pu -t "$pane" @claude_error
  fi
  announce
}

#--- UserPromptSubmit: the pane is busy again
clear_pane() {
  [ -n "${TMUX_PANE:-}" ] || return 0
  tm set -pu -t "$TMUX_PANE" @claude_state ';' set -pu -t "$TMUX_PANE" @claude_label ';' \
     set -pu -t "$TMUX_PANE" @claude_error
}

#--- A mocked failed message for the given pane (any tmux target, default: the
# current pane), then a finished one once that has expired; nothing is marked
demo() {
  local target="${1:-${TMUX_PANE:-}}" which="${2:-$FAILED}"
  if [ -n "$target" ]; then
    target="$(tm display -p -t "$target" '#{pane_id}')"
  else
    target="$(tm display -p '#{pane_id}')"
  fi
  read_pane "$target" || return 0
  kind="$which"
  label="$DEMO_LABEL"
  error=""
  [ "$kind" != "$FAILED" ] || error="$DEMO_ERROR"
  announce
  if [ "$kind" = "$FAILED" ]; then
    tm run-shell -b -d "$MESSAGE_SECONDS" "bash ${SELF_QUOTED} demo '${pane}' '${DONE}' >/dev/null 2>&1; true"
  fi
}

command -v tmux >/dev/null 2>&1 || exit 0
[ -n "${TMUX:-}" ] || exit 0

# Cleaning up runs even if the switch was turned off meanwhile
if [ "$action" = "expire" ]; then
  expire "${2:-}"
  exit 0
fi

# Only while ~/.tmux.conf has it on (@claude-status). The flag file first: with
# it off, tmux isn't even asked (each command would end up in its message log)
[ -e "$ACTIVE_FLAG" ] || exit 0
[ -n "$(tm show -gqv @claude_active)" ] || exit 0

case "$action" in
  "$DONE" | "$FAILED") mark "$action" "${2:-}" "${3:-}" ;;
  clear) clear_pane ;;
  demo) demo "${2:-}" "${3:-}" ;;
esac

exit 0
