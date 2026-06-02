#!/usr/bin/env bash
# proc.sh — Linux process management helper.
# Lists, searches, inspects, kills, counts and exports processes.
# Includes chart commands (stats, monitor, live, livetop, tree) via
# an external Python script (proc_stats_linux.py).
#
# Actions:
#   list, search, kill, info, top, count, export   — process management
#   stats, monitor, live, livetop, tree             — charts (Python + backend)
#
# Chart flags:  -b backend, -t theme, -m metric, -C chart, -n top,
#               --interval, --duration, --width, --height
# Metrics:      cpu, memory, io, threads, fds
# Backends:     plotext (default), termplotlib, matplotlib
# Themes:       dark (gruvbox-dark, default), light (gruvbox-light)

set -o pipefail

# --- colors ----------------------------------------------------------------
# Auto-disabled when stdout isn't a TTY so piping/redirection stays clean.

if [[ -t 1 ]]; then
    C_OK=$'\033[32m'
    C_ERR=$'\033[31m'
    C_WARN=$'\033[33m'
    C_INFO=$'\033[36m'
    C_ALT=$'\033[35m'
    C_RESET=$'\033[0m'
else
    C_OK= C_ERR= C_WARN= C_INFO= C_ALT= C_RESET=
fi

write_ok()       { printf '%s%s%s\n' "$C_OK"   "$*" "$C_RESET"; }
write_err()      { printf '%s%s%s\n' "$C_ERR"  "$*" "$C_RESET" >&2; }
write_warn()     { printf '%s%s%s\n' "$C_WARN" "$*" "$C_RESET"; }
write_info()     { printf '%s%s%s\n' "$C_INFO" "$*" "$C_RESET"; }
write_info_alt() { printf '%s%s%s\n' "$C_ALT"  "$*" "$C_RESET"; }

# --- defaults --------------------------------------------------------------

ACTION=""
NAME=""
PID_ARG=""
ALL=0
FORCE=0
SORT_BY="mem"
TOP_N=10
OUT_FILE=""
VERBOSE=0
SIGNAL="TERM"

# Chart defaults
EXTRA_NAMES=()
PID_ARGS=()
CHART="pie"
METRIC="cpu"
BACKEND="plotext"
THEME="dark"
INTERVAL="2"
DURATION="0"
PLOT_WIDTH="100"
PLOT_HEIGHT="25"

# --- help ------------------------------------------------------------------

show_help() {
    write_info_alt "proc.sh — Linux process management helper"
    cat <<'EOF'

Usage:
  proc.sh list   [-s cpu|mem|name|pid] [-v]
  proc.sh search <name> [-s ...] [-v]
  proc.sh kill   <name> [-a] [-f] [--signal SIG | -9] [-v]
  proc.sh kill   -i <pid> [-f] [--signal SIG | -9]
  proc.sh info   <name>  | -i <pid>
  proc.sh top    [-n N] [-s cpu|mem] [-v]
  proc.sh count  <name>  [-v]
  proc.sh export -o out.csv|out.json [-N pattern]
  proc.sh help        (also: -h, --help)

Chart commands (require Python 3 + a chart backend):
  proc.sh stats [-C pie|top|tree] [-m cpu|memory|io|threads|fds] [-n N]
  proc.sh monitor <name1> [name2 ...] [-m cpu|memory|io|threads|fds]
  proc.sh monitor -i <pid1> [-i <pid2>] [-m cpu|memory|io|threads|fds]
  proc.sh tree  [-m cpu|memory|io|threads|fds] [-n N]
  proc.sh live  [-n N] [-m cpu|memory|io|threads|fds] [--interval S] [--duration S]
  proc.sh livetop [-n N] [-m cpu|memory|io|threads|fds] [--interval S] [--duration S]

Flags:
  -h, --help            Show this help
  -v, --verbose         Show extra columns (user, threads, etime, cmd)
  -f, --force           Skip confirmation prompts
  -a, --all             When killing multiple matches, target every one
  -s, --sort FIELD      cpu | mem | name | pid  (default: mem)
  -i, --id PID          Specific PID (repeatable for monitor)
  -n, --top N           How many entries for 'top' / chart (default: 10)
  -o, --output FILE     Export destination (.csv or .json — picks format)
  -N, --name PATTERN    Filter pattern for export
  --signal SIG          Signal name/number for kill (default: TERM)
  -9                    Shortcut for --signal KILL

Chart flags:
  -b, --backend BE      plotext | termplotlib | matplotlib  (default: plotext)
  -t, --theme TH        dark | light                        (default: dark)
  -m, --metric M        cpu|memory|io|threads|fds           (default: cpu)
  -C, --chart CH        pie | top | tree  (for stats)       (default: pie)
  --interval SEC        Sampling interval for monitor/live/livetop  (default: 2)
  --duration SEC        Total duration for monitor/live/livetop     (default: 0 = indefinite)
  --width W             Plot width in characters              (default: 100)
  --height H            Plot height in characters             (default: 25)

Pattern matching is case-insensitive substring against the process name
(comm), mirroring the PowerShell version's contains-style match.

Chart examples:
  proc.sh stats                                        # CPU pie (plotext, gruvbox dark)
  proc.sh stats -m memory                              # Memory pie
  proc.sh stats -m memory -b matplotlib -t light       # Memory pie, matplotlib, light theme
  proc.sh stats -C top -m memory -n 20                 # Top 20 by memory bar chart
  proc.sh stats -C tree -m memory                      # Memory resource tree
  proc.sh stats -C tree -m io                          # IO resource tree
  proc.sh stats -C tree -m threads                     # Thread count tree
  proc.sh stats -C tree -m fds                         # Open file descriptors tree
  proc.sh stats -b termplotlib                         # CPU pie via termplotlib
  proc.sh stats --width 120 --height 30                # Custom plot dimensions
  proc.sh monitor chrome firefox                       # Monitor chrome+firefox CPU over time
  proc.sh monitor -i 1234 -i 5678 -m memory            # Monitor PIDs by memory
  proc.sh monitor python -m io --interval 1            # IO tracking every 1s
  proc.sh monitor node --duration 60 -m cpu            # CPU for 60 seconds then stop
  proc.sh monitor chrome -b termplotlib -t light       # Monitor with termplotlib, light theme
  proc.sh tree -m memory -n 20                         # Shortcut for stats -C tree
  proc.sh live                                         # Live top-10 CPU bar chart
  proc.sh live -m memory -n 20                         # Live top-20 by memory
  proc.sh live -m io --interval 1                      # Live IO chart, 1s refresh
  proc.sh live -m threads -n 15                        # Live thread count, top 15
  proc.sh live --duration 60                           # Live CPU for 60s then stop
  proc.sh live -b termplotlib -t light                 # Live chart with termplotlib, light
  proc.sh livetop                                      # Live CPU timeline of top 10
  proc.sh livetop -m memory -n 15 --interval 3         # Memory timeline, top 15
  proc.sh livetop -n 5 --duration 60                   # 60s CPU timeline of top 5
  proc.sh livetop -m io -b matplotlib                  # IO timeline via matplotlib
EOF
}

# --- arg parsing -----------------------------------------------------------

parse_args() {
    local positional=()
    while (( $# > 0 )); do
        case "$1" in
            -h|--help|-help)     ACTION="help"; return ;;
            -v|--verbose)        VERBOSE=1 ;;
            -f|--force)          FORCE=1 ;;
            -a|--all)            ALL=1 ;;
            -9)                  SIGNAL="KILL" ;;
            -s|--sort)           shift; SORT_BY="${1-}" ;;
            -i|--id)             shift; PID_ARG="${1-}"; PID_ARGS+=("${1-}") ;;
            -n|--top)            shift; TOP_N="${1-}" ;;
            -o|--output)         shift; OUT_FILE="${1-}" ;;
            -N|--name)           shift; NAME="${1-}" ;;
            --signal)            shift; SIGNAL="${1-}" ;;
            -m|--metric)         shift; METRIC="${1-}" ;;
            -b|--backend)        shift; BACKEND="${1-}" ;;
            -t|--theme)          shift; THEME="${1-}" ;;
            -C|--chart)          shift; CHART="${1-}" ;;
            --interval)          shift; INTERVAL="${1-}" ;;
            --duration)          shift; DURATION="${1-}" ;;
            --width)             shift; PLOT_WIDTH="${1-}" ;;
            --height)            shift; PLOT_HEIGHT="${1-}" ;;
            --sort=*)            SORT_BY="${1#*=}" ;;
            --id=*)              PID_ARG="${1#*=}"; PID_ARGS+=("${1#*=}") ;;
            --top=*)             TOP_N="${1#*=}" ;;
            --output=*)          OUT_FILE="${1#*=}" ;;
            --name=*)            NAME="${1#*=}" ;;
            --signal=*)          SIGNAL="${1#*=}" ;;
            --metric=*)          METRIC="${1#*=}" ;;
            --backend=*)         BACKEND="${1#*=}" ;;
            --theme=*)           THEME="${1#*=}" ;;
            --chart=*)           CHART="${1#*=}" ;;
            --interval=*)        INTERVAL="${1#*=}" ;;
            --duration=*)        DURATION="${1#*=}" ;;
            --width=*)           PLOT_WIDTH="${1#*=}" ;;
            --height=*)          PLOT_HEIGHT="${1#*=}" ;;
            --)                  shift; positional+=("$@"); break ;;
            -*)
                write_err "Unknown option: $1"
                echo
                show_help
                exit 1
                ;;
            *)                   positional+=("$1") ;;
        esac
        shift
    done

    # First positional → action, second → name (unless -N already set it).
    (( ${#positional[@]} >= 1 )) && ACTION="${positional[0]}"
    if (( ${#positional[@]} >= 2 )) && [[ -z "$NAME" ]]; then
        NAME="${positional[1]}"
    fi
    # For monitor, collect all extra positionals as additional names.
    if (( ${#positional[@]} >= 3 )); then
        EXTRA_NAMES=("${positional[@]:2}")
    fi

    [[ -z "$ACTION" ]] && ACTION="list"
}

# --- ps helpers ------------------------------------------------------------

# Map our friendly sort name to ps's --sort syntax (leading '-' = descending).
get_sort_field() {
    case "$1" in
        cpu)  echo "-pcpu" ;;
        mem)  echo "-rss"  ;;
        name) echo "comm"  ;;
        pid)  echo "pid"   ;;
        *)    echo "-rss"  ;;
    esac
}

# Print matching PIDs, one per line. Case-insensitive substring on `comm`.
match_processes() {
    local pattern="${1-}"
    if [[ -z "$pattern" ]]; then
        ps -eo pid= 2>/dev/null
        return
    fi
    local lpat="${pattern,,}"
    ps -eo pid=,comm= 2>/dev/null \
        | awk -v pat="$lpat" 'index(tolower($2), pat) > 0 {print $1}'
}

# Render PIDs as a comma-separated list ps -p can consume.
pids_to_csv() {
    tr '\n' ',' | sed 's/,$//'
}

show_table() {
    # Args: pids-csv (or empty for all), sort-field
    local plist="$1" sort_field="$2" cols
    if (( VERBOSE )); then
        cols="pid,user,pcpu,pmem,rss,nlwp,etime,stat,comm,args"
    else
        cols="pid,pcpu,pmem,rss,comm"
    fi

    if [[ -n "$plist" ]]; then
        ps -p "$plist" -o "$cols" --sort="$sort_field"
    else
        ps -eo "$cols" --sort="$sort_field"
    fi
}

# --- confirmation ----------------------------------------------------------

confirm() {
    local msg="$1"
    (( FORCE )) && return 0
    printf '%s%s [y/N]%s ' "$C_WARN" "$msg" "$C_RESET"
    local ans=""
    read -r ans || true
    [[ "$ans" =~ ^[yY]([eE][sS])?$ ]]
}

# --- kill ------------------------------------------------------------------

stop_one() {
    local pid="$1"
    local name
    name=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ')
    [[ -z "$name" ]] && name="?"

    if kill -s "$SIGNAL" "$pid" 2>/dev/null; then
        write_ok "Killed $name (PID $pid) with SIG$SIGNAL"
    else
        write_err "Failed to kill $name (PID $pid)"
    fi
}

invoke_kill() {
    # -i takes precedence: most precise input wins.
    if [[ -n "$PID_ARG" ]]; then
        if ! kill -0 "$PID_ARG" 2>/dev/null; then
            write_err "No process with PID $PID_ARG (or no permission)."
            return
        fi
        local name
        name=$(ps -p "$PID_ARG" -o comm= | tr -d ' ')
        if confirm "Kill $name (PID $PID_ARG)?"; then
            stop_one "$PID_ARG"
        else
            write_info "Cancelled."
        fi
        return
    fi

    if [[ -z "$NAME" ]]; then
        write_err "Provide a name pattern or -i <pid> for kill."
        return
    fi

    local pids
    pids=$(match_processes "$NAME")
    if [[ -z "$pids" ]]; then
        write_warn "No processes matched '$NAME'."
        return
    fi

    local pid_array=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && pid_array+=("$line")
    done <<< "$pids"

    # Single match: straight confirm-and-kill.
    if (( ${#pid_array[@]} == 1 )); then
        local pid="${pid_array[0]}"
        local name
        name=$(ps -p "$pid" -o comm= | tr -d ' ')
        if confirm "Kill $name (PID $pid)?"; then
            stop_one "$pid"
        else
            write_info "Cancelled."
        fi
        return
    fi

    # Multiple matches: show them, then ask what to do.
    write_info_alt "Found ${#pid_array[@]} matching processes:"
    local plist
    plist=$(printf '%s\n' "${pid_array[@]}" | pids_to_csv)
    show_table "$plist" "-rss"

    if (( ALL )); then
        if confirm "Kill ALL ${#pid_array[@]} matching processes?"; then
            for p in "${pid_array[@]}"; do stop_one "$p"; done
        else
            write_info "Cancelled."
        fi
        return
    fi

    write_info "Enter PID to kill, 'all' for all, or 'q' to cancel:"
    local choice=""
    read -r choice || true

    case "$choice" in
        q|quit|Q|QUIT)
            write_info "Cancelled."
            ;;
        all|ALL)
            if confirm "Kill ALL ${#pid_array[@]} matching processes?"; then
                for p in "${pid_array[@]}"; do stop_one "$p"; done
            else
                write_info "Cancelled."
            fi
            ;;
        ''[0-9]*|[0-9]*)
            local hit=0
            for p in "${pid_array[@]}"; do
                if [[ "$p" == "$choice" ]]; then hit=1; break; fi
            done
            if (( ! hit )); then
                write_err "PID $choice is not in the matched set."
                return
            fi
            local name
            name=$(ps -p "$choice" -o comm= | tr -d ' ')
            if confirm "Kill $name (PID $choice)?"; then
                stop_one "$choice"
            else
                write_info "Cancelled."
            fi
            ;;
        *)
            write_err "Unrecognised input '$choice'."
            ;;
    esac
}

# --- info ------------------------------------------------------------------

show_info() {
    local pids=()
    if [[ -n "$PID_ARG" ]]; then
        pids=("$PID_ARG")
    elif [[ -n "$NAME" ]]; then
        while IFS= read -r p; do
            [[ -n "$p" ]] && pids+=("$p")
        done < <(match_processes "$NAME")
    else
        write_err "Provide a name pattern or -i <pid> for info."
        return
    fi

    if (( ${#pids[@]} == 0 )); then
        write_warn "No matching processes."
        return
    fi

    for pid in "${pids[@]}"; do
        if [[ ! -d "/proc/$pid" ]]; then
            write_warn "PID $pid not found."
            continue
        fi
        local name
        name=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ')
        write_info_alt "--- ${name:-?} (PID $pid) ---"
        ps -p "$pid" -o pid,user,pcpu,pmem,rss,vsz,nlwp,etime,stat,nice,pri,comm,args

        # /proc gives us things ps can't: real exe path, cwd, open-FD count.
        if [[ -r "/proc/$pid/exe" ]]; then
            local exe
            exe=$(readlink "/proc/$pid/exe" 2>/dev/null || echo "(unreadable)")
            printf '  Path: %s\n' "$exe"
        fi
        if [[ -r "/proc/$pid/cwd" ]]; then
            local cwd
            cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "(unreadable)")
            printf '  CWD:  %s\n' "$cwd"
        fi
        if [[ -d "/proc/$pid/fd" ]]; then
            local fd_count
            fd_count=$(ls "/proc/$pid/fd" 2>/dev/null | wc -l)
            printf '  FDs:  %s\n' "$fd_count"
        fi
        echo
    done
}

# --- top -------------------------------------------------------------------

show_top() {
    local sort_by="$SORT_BY"
    case "$sort_by" in cpu|mem) ;; *) sort_by="mem" ;; esac
    local sort_field
    sort_field=$(get_sort_field "$sort_by")

    write_info_alt "Top $TOP_N by $sort_by"
    # +1 to include the header row.
    show_table "" "$sort_field" | head -n $(( TOP_N + 1 ))
}

# --- count -----------------------------------------------------------------

count_processes() {
    if [[ -z "$NAME" ]]; then
        write_err "Provide a name pattern for count."
        return
    fi
    local pids count=0
    pids=$(match_processes "$NAME")
    if [[ -n "$pids" ]]; then
        count=$(printf '%s\n' "$pids" | grep -c .)
    fi
    write_ok "$count process(es) match '$NAME'"
    if (( VERBOSE )) && (( count > 0 )); then
        local plist
        plist=$(printf '%s' "$pids" | pids_to_csv)
        ps -p "$plist" -o comm= | sort | uniq -c | sort -rn
    fi
}

# --- export ----------------------------------------------------------------

export_processes() {
    if [[ -z "$OUT_FILE" ]]; then
        write_err "Provide -o <path>."
        return
    fi

    local plist=""
    if [[ -n "$NAME" ]]; then
        local pids
        pids=$(match_processes "$NAME")
        if [[ -z "$pids" ]]; then
            write_warn "No processes matched '$NAME'."
            return
        fi
        plist=$(printf '%s' "$pids" | pids_to_csv)
    fi

    local data
    if [[ -n "$plist" ]]; then
        data=$(ps -p "$plist" -o pid,pcpu,pmem,rss,etime,comm,args --no-headers)
    else
        data=$(ps -eo pid,pcpu,pmem,rss,etime,comm,args --no-headers)
    fi

    local ext="${OUT_FILE##*.}"
    case "${ext,,}" in
        csv)
            {
                echo "PID,CPU,MemPct,RSS_kB,Etime,Command,Args"
                printf '%s\n' "$data" | awk '{
                    pid=$1; cpu=$2; mem=$3; rss=$4; etime=$5; comm=$6;
                    args="";
                    for (i=7; i<=NF; i++) args = args (i>7 ? " " : "") $i;
                    gsub(/"/, "\"\"", args);   # CSV-quote embedded quotes
                    gsub(/"/, "\"\"", comm);
                    printf "%s,%s,%s,%s,%s,\"%s\",\"%s\"\n",
                        pid, cpu, mem, rss, etime, comm, args;
                }'
            } > "$OUT_FILE"
            ;;
        json)
            {
                echo "["
                printf '%s\n' "$data" | awk '
                    BEGIN { first = 1 }
                    {
                        pid=$1; cpu=$2; mem=$3; rss=$4; etime=$5; comm=$6;
                        args="";
                        for (i=7; i<=NF; i++) args = args (i>7 ? " " : "") $i;
                        gsub(/\\/, "\\\\", args); gsub(/"/, "\\\"", args);
                        gsub(/\\/, "\\\\", comm); gsub(/"/, "\\\"", comm);
                        if (!first) printf ",\n"; first = 0;
                        printf "  {\"pid\":%s,\"cpu\":%s,\"mem\":%s,\"rss\":%s,\"etime\":\"%s\",\"comm\":\"%s\",\"args\":\"%s\"}",
                            pid, cpu, mem, rss, etime, comm, args;
                    }
                    END { print "" }
                '
                echo "]"
            } > "$OUT_FILE"
            ;;
        *)
            write_err "Unsupported extension '$ext'. Use .csv or .json."
            return 1
            ;;
    esac

    local count
    count=$(printf '%s\n' "$data" | grep -c .)
    write_ok "Exported $count entries to $OUT_FILE."
}

# --- Python chart helpers --------------------------------------------------

get_python_exe() {
    local cmd
    for cmd in python3 python py; do
        if command -v "$cmd" &>/dev/null; then
            echo "$cmd"
            return 0
        fi
    done
    write_err "Python not found in PATH. Install Python 3."
    return 1
}

get_proc_stats_script() {
    if [[ -z "${my_notes_path-}" ]]; then
        write_err "Environment variable 'my_notes_path' is not set."
        return 1
    fi
    #local script="${my_notes_path}/scripts/stats/proc_stats.py"
    local script="${my_notes_path}/scripts/stats/proc_stats_linux.py"
    if [[ ! -f "$script" ]]; then
        write_err "Python script not found: $script"
        return 1
    fi
    echo "$script"
}

invoke_proc_stats() {
    local py_exe script
    py_exe=$(get_python_exe)        || return 1
    script=$(get_proc_stats_script) || return 1

    write_info "Running: $py_exe $script $*"
    "$py_exe" "$script" "$@"
}

invoke_stats() {
    local py_args=(
        --backend "$BACKEND"
        --theme   "$THEME"
        --width   "$PLOT_WIDTH"
        --height  "$PLOT_HEIGHT"
        "$CHART"
        --metric  "$METRIC"
        --top     "$TOP_N"
    )
    invoke_proc_stats "${py_args[@]}"
}

invoke_monitor() {
    local py_args=(
        --backend  "$BACKEND"
        --theme    "$THEME"
        --width    "$PLOT_WIDTH"
        --height   "$PLOT_HEIGHT"
        monitor
        --metric   "$METRIC"
        --interval "$INTERVAL"
        --duration "$DURATION"
    )

    if (( ${#PID_ARGS[@]} > 0 )); then
        py_args+=(--pids)
        for pid in "${PID_ARGS[@]}"; do
            py_args+=("$pid")
        done
    fi

    local all_names=()
    [[ -n "$NAME" ]] && all_names+=("$NAME")
    (( ${#EXTRA_NAMES[@]} > 0 )) && all_names+=("${EXTRA_NAMES[@]}")

    if (( ${#all_names[@]} > 0 )); then
        py_args+=(--names)
        for n in "${all_names[@]}"; do
            py_args+=("$n")
        done
    fi

    if (( ${#PID_ARGS[@]} == 0 )) && (( ${#all_names[@]} == 0 )); then
        write_err "Provide process name(s) or -i <pid(s)> for monitor."
        echo "  Example: proc.sh monitor chrome firefox"
        echo "  Example: proc.sh monitor -i 1234 -i 5678"
        return 1
    fi

    invoke_proc_stats "${py_args[@]}"
}

invoke_tree() {
    local py_args=(
        --backend "$BACKEND"
        --theme   "$THEME"
        --width   "$PLOT_WIDTH"
        --height  "$PLOT_HEIGHT"
        tree
        --metric  "$METRIC"
        --top     "$TOP_N"
    )
    invoke_proc_stats "${py_args[@]}"
}

invoke_live() {
    local py_args=(
        --backend  "$BACKEND"
        --theme    "$THEME"
        --width    "$PLOT_WIDTH"
        --height   "$PLOT_HEIGHT"
        live
        --metric   "$METRIC"
        --top      "$TOP_N"
        --interval "$INTERVAL"
        --duration "$DURATION"
    )
    invoke_proc_stats "${py_args[@]}"
}

invoke_livetop() {
    local py_args=(
        --backend  "$BACKEND"
        --theme    "$THEME"
        --width    "$PLOT_WIDTH"
        --height   "$PLOT_HEIGHT"
        livetop
        --metric   "$METRIC"
        --top      "$TOP_N"
        --interval "$INTERVAL"
        --duration "$DURATION"
    )
    invoke_proc_stats "${py_args[@]}"
}

# --- main dispatch ---------------------------------------------------------

parse_args "$@"

# Catch help-like inputs in any form: flags handled in parse_args; here we
# also accept 'help' as the positional action and various odd spellings.
case "${ACTION,,}" in
    help|-h|--help|-help|/?|/help|-?)
        show_help
        exit 0
        ;;
esac

case "${ACTION,,}" in
    list)
        sort_field=$(get_sort_field "$SORT_BY")
        count_all=$(ps -eo pid= --no-headers | wc -l)
        write_info_alt "Listing $count_all processes (sorted by $SORT_BY)"
        show_table "" "$sort_field"
        ;;
    search)
        if [[ -z "$NAME" ]]; then
            write_err "Provide a name pattern for search."
            exit 1
        fi
        pids=$(match_processes "$NAME")
        if [[ -z "$pids" ]]; then
            write_warn "No processes matched '$NAME'."
            exit 0
        fi
        plist=$(printf '%s' "$pids" | pids_to_csv)
        n=$(printf '%s\n' "$pids" | grep -c .)
        sort_field=$(get_sort_field "$SORT_BY")
        write_info_alt "Found $n matching '$NAME'"
        show_table "$plist" "$sort_field"
        ;;
    kill)   invoke_kill ;;
    info)   show_info ;;
    top)    show_top ;;
    count)  count_processes ;;
    export) export_processes ;;
    stats)    invoke_stats ;;
    monitor)  invoke_monitor ;;
    tree)     invoke_tree ;;
    live)     invoke_live ;;
    livetop)  invoke_livetop ;;
    *)
        write_err "Unknown action: '$ACTION'"
        echo
        show_help
        exit 1
        ;;
esac
