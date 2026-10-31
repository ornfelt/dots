#!/usr/bin/env bash
# cci.sh - Claude Code usage, printed like the awesome bar widget prints it:
#   ✻ 5h 5% · 7d 89% · F 0%
# Same data, same text and same colours as ~/.config/awesome/claude_usage (the theme
# in themes/multicolor/theme.lua): the starburst in Claude orange, the numbers in
# orange too, red from 90 %, grey while there is an error and no data. A " ⚑" is
# appended while a running session waits for you.
# Windows counterpart: windows_dots/my_scripts/cci.ps1.
#
# Where the numbers come from, in this order (like claude_usage/cli.lua):
#   1. the last result, if younger than --max-age seconds (default 300)
#   2. the statusLine cache written by claude_usage/contrib/statusline-cache.sh, if
#      younger than two minutes
#   3. the OAuth usage endpoint (skipped while backing off after a 429/network error)
#   4. the statusLine cache at any age, then the cachedUsageUtilization in ~/.claude.json
# The result and the backoff live in ~/.cache/claude-usage/last.json, shared with
# cli.lua, so calling this often does not hammer the rate-limited endpoint.
#
# Usage examples:
#   cci.sh
# always fetch (the backoff is still honoured):
#   cci.sh --max-age 0
# cache files only, never call the API:
#   cci.sh --no-network
# print it like the wezterm status line does (~/.wezterm/claude_usage.lua): 5h left
# out while there is no such window, Fable left out at 0 %, wezterm's orange:
#   cci.sh --wezterm
# this help (also help, -h; case insensitive):
#   cci.sh --help
#
# Requires jq and curl.

set -uo pipefail

SCRIPT_NAME="${0##*/}"

usage() {
    sed -n '2,/^# Requires/s/^# \{0,1\}//p' "$0"
}

max_age=300
network=1
wezterm=false
while (($#)); do
    case "${1,,}" in
        --max-age)
            shift
            [[ "${1:-}" =~ ^[0-9]+$ ]] || { echo "$SCRIPT_NAME: --max-age needs a number of seconds" >&2; exit 2; }
            max_age="$1"
            ;;
        --no-network) network=0 ;;
        -w | --wezterm) wezterm=true ;;
        help | -h | --help) usage; exit 0 ;;
        *) echo "$SCRIPT_NAME: unknown argument '$1' (see --help)" >&2; exit 2 ;;
    esac
    shift
done

for cmd in jq curl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "$SCRIPT_NAME: $cmd is required" >&2; exit 1; }
done

# ------------------------------------------------------------------ config --
# Same values as claude_usage/config.lua and the theme.
VERSION="0.5.3"
USER_AGENT="awesome-claude-usage/$VERSION (+https://github.com/derblub/awesome-claude-usage)"
API_URL="https://api.anthropic.com/api/oauth/usage"
BETA_HEADER="oauth-2025-04-20"
TIMEOUT=15
BACKOFF=(300 600 1200 1800)
STALE_AFTER=3600
FRESH_CACHE_MAX_AGE=120
CREDENTIALS_PATH="$HOME/.claude/.credentials.json"
CLAUDE_JSON_PATH="$HOME/.claude.json"
SESSIONS_DIR="$HOME/.claude/sessions"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage"
STATUSLINE_CACHE="$CACHE_DIR/rate_limits.json"
LAST_PATH="$CACHE_DIR/last.json"
WARN_AT=75
CRIT_AT=90

ICON="✻"  # stands in for the drawn starburst
COLOR_NORMAL="#D97757"
COLOR_ICON="#D97757"
COLOR_WARN="#D97757"  # same as normal in the theme
COLOR_CRIT="#C8442E"
COLOR_ERROR="#9C9A93"

# --wezterm: same as M.hide_zero_fable and CLAUDE_ORANGE in ~/.wezterm/claude_usage.lua
HIDE_ZERO_FABLE=true
FABLE_NAME="Fable"
if [[ "$wezterm" == true ]]; then
    COLOR_NORMAL="#C86D50"
    COLOR_ICON="$COLOR_NORMAL"
    COLOR_WARN="$COLOR_NORMAL"
fi

now=$(date +%s)

# ---------------------------------------------------------------- jq library --
# Ports of normalize.lua and the bar parts of format.lua.
JQ_LIB='
def pct: (tonumber? // null) | if . == null then null elif . < 0 then 0 else . end;
def epoch_s: (tonumber? // null) | if . == null then null elif . > 1e11 then (. / 1000 | floor) else floor end;
def iso8601:
  if type != "string" then null else
    (capture("^\\s*(?<d>\\d{4}-\\d{2}-\\d{2})[Tt ](?<h>\\d{2}):(?<m>\\d{2})(:(?<s>\\d{2}))?([.,]\\d+)?(?<z>[Zz]|[+-]\\d{2}:?\\d{2})?\\s*$")? // null)
    | if . == null then null else
        ((.d + "T" + .h + ":" + .m + ":" + (.s // "00") + "Z") | fromdateiso8601) as $e
        | (if .z == null or .z == "Z" or .z == "z" then 0 else
             (.z | capture("(?<sg>[+-])(?<oh>\\d{2}):?(?<om>\\d{2})")
                 | ((.oh | tonumber) * 3600 + (.om | tonumber) * 60) * (if .sg == "-" then -1 else 1 end))
           end) as $off
        | $e - $off
      end
  end;
def win($p; $r): if $p == null then null else {percent: $p, resets_at: $r} end;
def money: if type == "number" then . elif type == "object" and (.amount_minor | type) == "number"
  then .amount_minor / pow(10; (.exponent | tonumber? // 2)) else null end;

def spend_from:
  if (.spend | type) == "object" then
    .spend as $s | {enabled: ($s.enabled == true), percent: ($s.percent | pct // 0), used: ($s.used | money),
      currency: (if ($s.used | type) == "object" then $s.used.currency else null end // "USD"), limit: ($s.limit | money)}
  elif (.extra_usage | type) == "object" and .extra_usage.is_enabled != null then
    .extra_usage as $e | {enabled: ($e.is_enabled == true), percent: ($e.utilization | pct // 0),
      used: ($e.used_credits | tonumber? // null), currency: ($e.currency // "USD"), limit: ($e.monthly_limit | tonumber? // null)}
  else null end;

def breakdown_from:
  if (.seven_day_breakdown | type) == "object" and (.seven_day_breakdown.rows | type) == "array" then
    [.seven_day_breakdown.rows[] | select(type == "object") | (.percent | pct) as $p
      | select($p != null and .display_name) | {name: .display_name, percent: $p}]
    | if length == 0 then null else . end
  else null end;

def from_api($now):
  . as $raw
  | {scoped: [], fetched_at: $now}
  | if ($raw | type) != "object" then . else
      reduce (($raw.limits | if type == "array" then .[] else empty end) | select(type == "object")) as $l (.;
        win($l.percent | pct; $l.resets_at | iso8601) as $w0
        | if $w0 == null then . else
            ($w0 + {kind: $l.kind, is_active: ($l.is_active == true)}) as $w
            | if $l.kind == "session" then .five_hour //= $w
              elif $l.kind == "weekly_all" then .seven_day //= $w
              elif $l.kind == "weekly_scoped" then
                ((if ($l.scope | type) == "object" then $l.scope.model else null end)
                  | if type == "object" then (.display_name // .id) else null end) as $name
                | if $name then .scoped += [$w + {name: $name}] else . end
              else . end
          end)
      | if .five_hour == null and ($raw.five_hour | type) == "object" then
          .five_hour = win($raw.five_hour.utilization | pct; $raw.five_hour.resets_at | iso8601) else . end
      | if .seven_day == null and ($raw.seven_day | type) == "object" then
          .seven_day = win($raw.seven_day.utilization | pct; $raw.seven_day.resets_at | iso8601) else . end
      | if (.scoped | length) == 0 then
          .scoped = [["Opus", "seven_day_opus"], ["Sonnet", "seven_day_sonnet"]
            | . as [$name, $key] | $raw[$key] | select(type == "object")
            | win(.utilization | pct; .resets_at | iso8601) | select(. != null) | . + {name: $name}]
        else . end
      | .seven_day as $wk
      | .scoped |= map(if .resets_at == null and $wk != null then .resets_at = $wk.resets_at else . end)
      | .spend = ($raw | spend_from)
      | .breakdown = ($raw | breakdown_from)
    end;

def from_statusline($now):
  . as $raw
  | {scoped: [], fetched_at: $now}
  | if ($raw | type) != "object" then . else
      (if ($raw.rate_limits | type) == "object" then $raw.rate_limits else null end) as $rl
      # a missing window next to a present one means "0 %, not started yet"
      | if $rl then reduce ("five_hour", "seven_day") as $k (.;
          if ($rl[$k] | type) == "object" then .[$k] = win($rl[$k].used_percentage | pct; $rl[$k].resets_at | epoch_s)
          else .[$k] = {percent: 0, resets_at: null, assumed: true} end) else . end
      | if $rl and ($rl.spend_limit | type) == "object" and ($rl.spend_limit.used_percentage | pct) != null then
          .spend = {enabled: true, percent: ($rl.spend_limit.used_percentage | pct), currency: "USD"} else . end
      | ($raw.ts | epoch_s) as $ts | if $ts then .fetched_at = $ts else . end
    end;

def from_claude_json($now):
  (if (.cachedUsageUtilization | type) == "object" then .cachedUsageUtilization else . end) as $cu
  | ($cu.utilization | from_api($now))
  | ($cu.fetchedAtMs | epoch_s) as $f | if $f then .fetched_at = $f else . end;

def has_data: type == "object" and (.five_hour != null or .seven_day != null or ((.scoped // []) | length) > 0);
def max_percent: [.five_hour, .seven_day, (.scoped // [])[]]
  | map(select(type == "object" and (.percent | type) == "number") | .percent) | max;
def short_error: {unauthorized: "!auth", no_credentials: "!cred", rate_limited: "!429", network: "!net",
  parse: "!parse", no_source: "!none"}[. // ""] // "!err";
def pct_text: if type == "object" and (.percent | type) == "number" then "\(.percent + 0.5 | floor)%" else "--" end;
# $wez: no 5h while there is no such window (the wezterm worker never assumes one),
# and with $hide_fable no $fable window at 0 %
def bar_text($wez; $hide_fable; $fable):
  if has_data | not then (if .error then (.error.code | short_error) else "--" end)
  else
    (((if $wez and (.five_hour | type != "object" or (.percent | type) != "number" or .assumed == true)
        then [] else ["5h " + (.five_hour | pct_text)] end)
      + ["7d " + (.seven_day | pct_text)]
      + [(.scoped // [])[]
          | select(($wez and $hide_fable and ((.name | tostring | ascii_downcase) == ($fable | ascii_downcase))
              and pct_text == "0%") | not)
          | ((.name | tostring) | .[0:1]) + " " + pct_text]) | join(" · "))
    + (if (.sessions.attention // 0) > 0 then " ⚑" else "" end)
  end
  | sub("^\\s+"; "") | sub("\\s+$"; "");
# normal | warn | crit | error, the level that picks the text colour (format.color_for)
def level($warn; $crit):
  if has_data | not then (if .error then "error" else "normal" end)
  else max_percent as $m
    | if $m == null then "normal" elif $m >= $crit then "crit" elif $m >= $warn then "warn" else "normal" end
  end;
'

# jqf FILTER [jq args...]: jq with the library and $now
jqf() { jq --argjson now "$now" "$JQ_LIB $1" "${@:2}"; }

# Valid JSON object from a file, or nothing.
read_json() { [[ -r "$1" ]] && jq -ec 'select(type == "object")' "$1" 2>/dev/null; }

# ------------------------------------------------------------------ fetch --
last=$(read_json "$LAST_PATH") || last='{}'
state=""
err="null"

# 1) recent result
state=$(jq -c --argjson now "$now" --argjson max "$max_age" \
    'select(.state != null and .fetched_at != null and $now - .fetched_at <= $max) | .state' <<<"$last")

# 2) fresh statusLine cache
statusline_raw() { read_json "$STATUSLINE_CACHE" | jq -c 'select((.rate_limits | type) == "object" or (.context | type) == "object")'; }
if [[ -z "$state" ]]; then
    raw=$(statusline_raw)
    if [[ -n "$raw" ]]; then
        state=$(jqf 'select((.ts | tonumber? // null) != null and $now - (.ts | tonumber) <= $fresh)
             | from_statusline($now) + {source: "statusline"}' --argjson fresh "$FRESH_CACHE_MAX_AGE" -c <<<"$raw")
    fi
fi

# 3) API, unless backing off
if [[ -z "$state" ]] && ((network)); then
    retry_at=$(jq -r '.retry_at // empty' <<<"$last")
    if [[ -n "$retry_at" ]] && ((now < ${retry_at%.*})); then
        err=$(jq -nc --argjson now "$now" --argjson r "$retry_at" \
            '{code: "rate_limited", message: "backing off", retry_at: $r, at: $now}')
    else
        creds=""
        if ! content=$(cat -- "$CREDENTIALS_PATH" 2>/dev/null) || [[ -z "$content" ]]; then
            err=$(jq -nc --argjson now "$now" --arg m "cannot read $CREDENTIALS_PATH" '{code: "no_credentials", message: $m, at: $now}')
        elif ! creds=$(jq -ec --argjson now "$now" '
                .claudeAiOauth | select(type == "object" and (.accessToken | type) == "string" and .accessToken != "")
                | {token: .accessToken, subscription: .subscriptionType,
                   expires_at: ((.expiresAt | tonumber? // null) | if . != null and . > 1e11 then . / 1000 else . end)}' \
                <<<"$content" 2>/dev/null); then
            if jq -e . <<<"$content" >/dev/null 2>&1; then
                m="no claudeAiOauth.accessToken in credentials"
            else
                m="credentials file is not valid JSON"
            fi
            err=$(jq -nc --argjson now "$now" --arg m "$m" '{code: "no_credentials", message: $m, at: $now}')
            creds=""
        elif jq -e --argjson now "$now" '.expires_at != null and .expires_at <= $now' <<<"$creds" >/dev/null; then
            err=$(jq -nc --argjson now "$now" '{code: "unauthorized", message: "access token expired", at: $now}')
            creds=""
        fi

        if [[ -n "$creds" ]]; then
            token=$(jq -r '.token' <<<"$creds")
            subscription=$(jq -c '.subscription' <<<"$creds")
            errfile=$(mktemp)
            # The token goes in through stdin, not the argument list.
            out=$(printf 'Authorization: Bearer %s\n' "$token" | curl -sS --max-time "$TIMEOUT" \
                -H @- -H "anthropic-beta: $BETA_HEADER" -H "Accept: application/json" \
                -A "$USER_AGENT" -w $'\n%{http_code}' "$API_URL" 2>"$errfile")
            code=$?
            stderr=$(<"$errfile")
            rm -f "$errfile"
            unset token

            if ((code != 0)); then
                msg=$(sed -E 's/^[[:space:]]*curl:[[:space:]]*\([0-9]+\)[[:space:]]*//' <<<"$stderr")
                msg="${msg%"${msg##*[![:space:]]}"}"
                [[ -n "$msg" ]] || msg="curl failed (exit $code)"
                err=$(jq -nc --argjson now "$now" --arg m "$msg" '{code: "network", message: $m, at: $now}')
            else
                http="${out##*$'\n'}"
                body="${out%$'\n'*}"
                if [[ ! "$http" =~ ^[0-9]{3}$ ]]; then
                    err=$(jq -nc --argjson now "$now" '{code: "parse", message: "no HTTP status in curl output", at: $now}')
                elif ((http == 200)); then
                    if state=$(jqf 'select(type == "object") | from_api($now) + {source: "api", subscription: $sub}' \
                            --argjson sub "$subscription" -c <<<"$body" 2>/dev/null) \
                            && [[ -n "$state" ]]; then
                        last=$(jq -c 'del(.retry_at) | .backoff_attempt = 0' <<<"$last")
                    else
                        state=""
                        err=$(jq -nc --argjson now "$now" '{code: "parse", message: "response is not valid JSON", http: 200, at: $now}')
                    fi
                else
                    case "$http" in
                        401 | 403) ecode=unauthorized ;;
                        429) ecode=rate_limited ;;
                        5??) ecode=network ;;
                        *) ecode=parse ;;
                    esac
                    err=$(jq -nc --argjson now "$now" --arg c "$ecode" --argjson h "$http" \
                        '{code: $c, message: "HTTP \($h)", http: $h, at: $now}')
                fi
            fi

            # back off after a 429 or a network error, like the widget
            if jq -e '.code == "rate_limited" or .code == "network"' <<<"$err" >/dev/null 2>&1; then
                attempt=$(jq -r --argjson n "${#BACKOFF[@]}" '[(.backoff_attempt // 0) + 1, $n] | min' <<<"$last")
                retry_at=$((now + BACKOFF[attempt - 1]))
                last=$(jq -c --argjson a "$attempt" --argjson r "$retry_at" '.backoff_attempt = $a | .retry_at = $r' <<<"$last")
                err=$(jq -c --argjson r "$retry_at" '.retry_at = $r' <<<"$err")
            fi
        fi
    fi
fi

# 4) fallbacks
if [[ -z "$state" ]]; then
    raw=$(statusline_raw)
    [[ -n "$raw" ]] && state=$(jqf 'from_statusline($now) + {source: "statusline"}' -c <<<"$raw")
fi
if [[ -z "$state" && -r "$CLAUDE_JSON_PATH" ]] && grep -qF '"cachedUsageUtilization"' "$CLAUDE_JSON_PATH"; then
    state=$(jqf 'select((.cachedUsageUtilization.utilization | type) == "object")
        | from_claude_json($now) + {source: "claude_json"}' -c "$CLAUDE_JSON_PATH" 2>/dev/null)
fi
[[ -z "$state" ]] && state=$(jq -c '.state // empty' <<<"$last")
[[ -z "$state" ]] && state='{"scoped": []}'

# ---------------------------------------------------------------- sessions --
# ~/.claude/sessions/<pid>.json of live processes; waiting/needs_input = needs you.
total=0 working=0 idle=0 attention=0
shopt -s nullglob
session_files=("$SESSIONS_DIR"/*.json)
shopt -u nullglob
if ((${#session_files[@]})); then
    while read -r pid status; do
        [[ "$pid" =~ ^[0-9]+$ && -e "/proc/$pid/stat" ]] || continue
        ((total++))
        case "$status" in
            busy) ((working++)) ;;
            waiting | needs_input) ((attention++)) ;;
            *) ((idle++)) ;;
        esac
    done < <(for f in "${session_files[@]}"; do
        [[ "${f##*/}" =~ ^[0-9]+\.json$ ]] && jq -r 'select(.pid != null) | "\(.pid) \(.status)"' "$f" 2>/dev/null
    done)
fi

state=$(jq -c --argjson now "$now" --argjson stale "$STALE_AFTER" --argjson err "$err" \
    --argjson t "$total" --argjson w "$working" --argjson i "$idle" --argjson a "$attention" '
    .scoped = (.scoped // [])
    | .error = $err
    | .stale = (.fetched_at != null and ($now - .fetched_at) > $stale)
    | .sessions = {total: $t, working: $w, idle: $i, attention: $a}' <<<"$state")

# persist for the next call (only real fetches refresh the timestamp)
last=$(jq -c --argjson now "$now" --argjson st "$state" '
    if $st.source == "api" or $st.source == "statusline" then .state = $st | .fetched_at = ($st.fetched_at // $now) else . end' <<<"$last")
if mkdir -p "$CACHE_DIR" 2>/dev/null; then
    printf '%s\n' "$last" >"$LAST_PATH.tmp" 2>/dev/null && mv -f "$LAST_PATH.tmp" "$LAST_PATH" 2>/dev/null
fi

# ----------------------------------------------------------------- output --
{ read -r text; read -r level; } < <(jq -r --argjson warn "$WARN_AT" --argjson crit "$CRIT_AT" \
    --argjson wez "$wezterm" --argjson hide_fable "$HIDE_ZERO_FABLE" --arg fable "$FABLE_NAME" \
    "$JQ_LIB bar_text(\$wez; \$hide_fable; \$fable), level(\$warn; \$crit)" <<<"$state")

case "$level" in
    crit) color="$COLOR_CRIT" ;;
    warn) color="$COLOR_WARN" ;;
    error) color="$COLOR_ERROR" ;;
    *) color="$COLOR_NORMAL" ;;
esac

# Truecolor where the terminal says so, else the nearest 256-colour entry, else the
# basic yellow/red/grey.
colors=0
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    if [[ "${COLORTERM:-}" == truecolor || "${COLORTERM:-}" == 24bit ]]; then
        colors=24
    else
        colors=$(tput colors 2>/dev/null || echo 8)
    fi
fi

paint() {
    local hex="${1#\#}"
    if ((colors == 24)); then
        printf '\033[38;2;%d;%d;%dm' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
    elif ((colors >= 256)); then
        case "$1" in
            "$COLOR_CRIT") printf '\033[38;5;167m' ;;
            "$COLOR_ERROR") printf '\033[38;5;247m' ;;
            *) printf '\033[38;5;173m' ;;
        esac
    elif ((colors > 0)); then
        case "$1" in
            "$COLOR_CRIT") printf '\033[31m' ;;
            "$COLOR_ERROR") printf '\033[90m' ;;
            *) printf '\033[33m' ;;
        esac
    fi
}

if ((colors > 0)); then
    printf '%s%s\033[0m %s%s\033[0m\n' "$(paint "$COLOR_ICON")" "$ICON" "$(paint "$color")" "$text"
else
    printf '%s %s\n' "$ICON" "$text"
fi
