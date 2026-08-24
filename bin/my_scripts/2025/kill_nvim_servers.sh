#!/usr/bin/env bash
#
# kill_nvim_servers.sh
#
# SYNOPSIS
#   Kills the headless Neovim servers started by the wezterm integration and
#   clears their state directory, so you can start from a clean slate.
#
# DESCRIPTION
#   Servers are found by looking for running nvim processes whose command line
#   contains "--listen <address>" where the address's basename starts with
#   --pattern (default "nvim-wez-", the prefix used by ~/.wezterm/nvim_server.lua).
#
#   Plain interactive nvim sessions are never touched: they either have no
#   --listen at all, or listen on nvim's own "nvim.<pid>.0" address, neither of
#   which matches the prefix. Note that nvim 0.12 runs every server as a parent
#   plus an --embed child, so the process count is about twice the server count.
#
# USAGE
#   kill_nvim_servers.sh [state-dir] [options]
#
#   -d, --dir, --state-dir DIR  Directory holding the <name>.pid and <name>.lease
#                               files. Defaults to $WEZ_NVIM_DIR, else
#                               ~/.wezterm/nvim-servers. Can also be given
#                               positionally.
#   -s, --scope SCOPE           all      every managed server (default)
#                               pane     only per-pane servers,
#                                        nvim-wez-<wezterm pid>-<pane id>
#                               pool     only pooled servers, nvim-wez-pool-*
#                               orphans  only per-pane servers whose owning
#                                        wezterm is no longer running, which is
#                                        the safe option while you are still
#                                        using wezterm
#   -i, --instance PID          Only servers belonging to this wezterm instance.
#   -p, --pattern PREFIX        Server name prefix to match. Widen at your own risk.
#   -k, --keep-state-dir        Leave the .pid/.lease files alone.
#   -f, --force                 Do not ask for confirmation.
#   -n, --dry-run, --debug      Show what would be killed and print the
#                               equivalent commands, then stop.
#   -h, --help                  This help.
#
# EXAMPLES
#   kill_nvim_servers.sh --dry-run
#   kill_nvim_servers.sh --scope orphans --force
#   kill_nvim_servers.sh --scope pool

set -o pipefail

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
write_dim()      { echo -e "${DARKGRAY}${1}${RESET}"; }

usage() { sed -n '3,45p' "$0" | sed 's/^# \{0,1\}//'; }

# --- options --------------------------------------------------------------

STATE_DIR=""
SCOPE="all"
INSTANCE=""
PATTERN="nvim-wez-"
KEEP_STATE_DIR=0
FORCE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir|--state-dir) STATE_DIR=$2; shift 2 ;;
        -s|--scope)           SCOPE=$(echo "$2" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
        -i|--instance)        INSTANCE=$2; shift 2 ;;
        -p|--pattern)         PATTERN=$2; shift 2 ;;
        -k|--keep-state-dir)  KEEP_STATE_DIR=1; shift ;;
        -f|--force)           FORCE=1; shift ;;
        -n|--dry-run|--debug) DRY_RUN=1; shift ;;
        -h|--help)            usage; exit 0 ;;
        -*)                   write_err "Unknown option: $1"; usage; exit 2 ;;
        *)
            if [[ -z $STATE_DIR ]]; then STATE_DIR=$1
            else write_err "Unexpected argument: $1"; exit 2; fi
            shift ;;
    esac
done

case "$SCOPE" in
    all|pane|pool|orphans) ;;
    *) write_err "Invalid --scope: $SCOPE (all|pane|pool|orphans)"; exit 2 ;;
esac

if [[ -z $STATE_DIR ]]; then
    STATE_DIR="${WEZ_NVIM_DIR:-$HOME/.wezterm/nvim-servers}"
fi

write_info_alt "== kill nvim servers =="
write_dim      "   state dir : $STATE_DIR"
write_dim      "   scope     : $SCOPE$([[ -n $INSTANCE ]] && echo "  instance=$INSTANCE")"
write_dim      "   pattern   : $PATTERN*"
echo ''

# --- discover -------------------------------------------------------------

contains() { local n=$1; shift; local x; for x in "$@"; do [[ $x == "$n" ]] && return 0; done; return 1; }

wez_pids=()
while IFS= read -r p; do [[ -n $p ]] && wez_pids+=("$p"); done < <(pgrep -x wezterm-gui 2>/dev/null)

# Derived from --pattern rather than hardcoded, so overriding the prefix still
# classifies pool vs per-pane servers and still finds the owning instance
escaped=$(printf '%s' "$PATTERN" | sed 's/[][\\.^$*+?(){}|]/\\&/g')
pane_re="^${escaped}([0-9]+)-[0-9]+$"
pool_re="^${escaped}pool-([0-9]+)-[0-9]+$"

declare -A SRV_KIND SRV_INST SRV_ALIVE SRV_PIDS SRV_BYTES
names=()
pagesize=$(getconf PAGESIZE 2>/dev/null || echo 4096)

for proc in /proc/[0-9]*; do
    pid=${proc##*/}
    [[ -r $proc/cmdline ]] || continue
    comm=$(cat "$proc/comm" 2>/dev/null) || continue
    [[ $comm == nvim ]] || continue

    args=()
    while IFS= read -r -d '' a; do args+=("$a"); done < "$proc/cmdline" 2>/dev/null

    addr=""
    for ((i = 0; i < ${#args[@]}; i++)); do
        case "${args[i]}" in
            --listen)   addr=${args[i+1]}; break ;;
            --listen=*) addr=${args[i]#--listen=}; break ;;
        esac
    done
    [[ -n $addr ]] || continue

    name=${addr##*/}
    name=${name%.sock}
    [[ $name == "$PATTERN"* ]] || continue

    if [[ -z ${SRV_KIND[$name]+x} ]]; then
        kind=pane
        inst=""
        owned=1
        if [[ $name == "${PATTERN}pool-"* ]]; then
            kind=pool
            # Pool servers spawned from lua carry the instance that started
            # them, so --instance can select them too; they are still shared
            [[ $name =~ $pool_re ]] && inst=${BASH_REMATCH[1]}
        elif [[ $name =~ $pane_re ]]; then
            inst=${BASH_REMATCH[1]}
            contains "$inst" "${wez_pids[@]}" || owned=0
        fi
        SRV_KIND[$name]=$kind
        SRV_INST[$name]=$inst
        SRV_ALIVE[$name]=$owned
        SRV_PIDS[$name]=""
        SRV_BYTES[$name]=0
        names+=("$name")
    fi

    SRV_PIDS[$name]="${SRV_PIDS[$name]}${SRV_PIDS[$name]:+ }$pid"
    rss=$(awk '{print $2}' "$proc/statm" 2>/dev/null)
    SRV_BYTES[$name]=$(( SRV_BYTES[$name] + ${rss:-0} * pagesize ))
done

if [[ ${#names[@]} -gt 0 ]]; then
    mapfile -t names < <(printf '%s\n' "${names[@]}" | sort)
fi

# --- filter ---------------------------------------------------------------

targets=()
for name in "${names[@]}"; do
    case "$SCOPE" in
        pane)    [[ ${SRV_KIND[$name]} == pane ]] || continue ;;
        pool)    [[ ${SRV_KIND[$name]} == pool ]] || continue ;;
        orphans) [[ ${SRV_KIND[$name]} == pane && ${SRV_ALIVE[$name]} -eq 0 ]] || continue ;;
    esac
    if [[ -n $INSTANCE && ${SRV_INST[$name]} != "$INSTANCE" ]]; then continue; fi
    targets+=("$name")
done

# --- report ---------------------------------------------------------------

if [[ ${#names[@]} -eq 0 ]]; then
    write_ok 'No managed nvim servers are running.'
else
    # Count only the processes behind matched servers, not every listening nvim
    matched=0
    for name in "${names[@]}"; do
        set -- ${SRV_PIDS[$name]}
        matched=$(( matched + $# ))
    done
    write_info "Found ${#names[@]} managed server(s) across $matched process(es):"
    for name in "${names[@]}"; do
        if contains "$name" "${targets[@]}"; then mark='  KILL '; else mark='  keep '; fi
        if [[ ${SRV_KIND[$name]} == pool ]]; then
            owner='pool (shared)'
        elif [[ ${SRV_ALIVE[$name]} -eq 1 ]]; then
            owner="instance ${SRV_INST[$name]} (alive)"
        else
            owner="instance ${SRV_INST[$name]} (DEAD)"
        fi
        pids_csv=$(echo "${SRV_PIDS[$name]}" | tr ' ' ',')
        line=$(printf '%s%-34s %-26s pids=%-14s %6d MB' \
            "$mark" "$name" "$owner" "$pids_csv" "$(( SRV_BYTES[$name] / 1048576 ))")
        if contains "$name" "${targets[@]}"; then
            if [[ ${SRV_KIND[$name]} == pane && ${SRV_ALIVE[$name]} -eq 0 ]]; then
                write_warn "$line"
            else
                echo "$line"
            fi
        else
            write_dim "$line"
        fi
    done
fi

stale_files=()
if [[ -d $STATE_DIR ]]; then
    while IFS= read -r f; do stale_files+=("$f"); done \
        < <(find "$STATE_DIR" -type f \( -name '*.pid' -o -name '*.lease' \) 2>/dev/null)
fi

echo ''
kill_pids=()
freed=0
for name in "${targets[@]}"; do
    for pid in ${SRV_PIDS[$name]}; do kill_pids+=("$pid"); done
    freed=$(( freed + SRV_BYTES[$name] ))
done
write_info "$(printf 'Will kill %d server(s) / %d process(es), freeing about %d MB' \
    "${#targets[@]}" "${#kill_pids[@]}" "$(( freed / 1048576 ))")"
if [[ $KEEP_STATE_DIR -eq 0 ]]; then
    write_info "Will remove ${#stale_files[@]} file(s) from the state directory"
else
    write_dim 'State directory will be left alone (--keep-state-dir)'
fi

if [[ ${#targets[@]} -eq 0 && ( $KEEP_STATE_DIR -eq 1 || ${#stale_files[@]} -eq 0 ) ]]; then
    echo ''
    write_ok 'Nothing to do.'
    exit 0
fi

# --- dry run --------------------------------------------------------------

if [[ $DRY_RUN -eq 1 ]]; then
    echo ''
    write_info_alt 'Dry run, nothing was changed. Equivalent commands:'
    if [[ ${#kill_pids[@]} -gt 0 ]]; then
        echo "  kill -9 ${kill_pids[*]}"
    fi
    if [[ $KEEP_STATE_DIR -eq 0 && ${#stale_files[@]} -gt 0 ]]; then
        echo "  rm -f '$STATE_DIR'/*.pid '$STATE_DIR'/*.lease"
    fi
    exit 0
fi

# --- confirm --------------------------------------------------------------

if [[ $FORCE -eq 0 ]]; then
    echo ''
    write_warn 'Unsaved buffers in these servers will be lost (nvim swap files survive).'
    read -r -p 'Proceed? [y/N] ' answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) write_err 'Aborted.'; exit 1 ;;
    esac
fi

# --- kill -----------------------------------------------------------------

echo ''
failed=0
for name in "${targets[@]}"; do
    bad=()
    for pid in ${SRV_PIDS[$name]}; do
        kill -9 "$pid" 2>/dev/null && continue
        # Already gone counts as success; nvim's parent takes its child with it
        kill -0 "$pid" 2>/dev/null && bad+=("$pid")
    done
    if [[ ${#bad[@]} -gt 0 ]]; then
        write_err "  failed: $name (pids $(echo "${bad[*]}" | tr ' ' ','))"
        failed=$(( failed + 1 ))
    else
        write_ok "  killed: $name"
    fi
done

# --- clean up state files -------------------------------------------------

removed=0
if [[ $KEEP_STATE_DIR -eq 0 && -d $STATE_DIR ]]; then
    # Only drop files whose server is really gone, so a server we deliberately
    # kept does not lose the pid file that makes it findable
    for file in "${stale_files[@]}"; do
        base=${file##*/}
        name=${base%.*}
        if [[ -n ${SRV_KIND[$name]+x} ]] && ! contains "$name" "${targets[@]}"; then
            continue
        fi
        rm -f "$file" 2>/dev/null && removed=$(( removed + 1 ))
    done
    write_ok "  removed $removed state file(s)"
fi

echo ''
if [[ $failed -gt 0 ]]; then
    write_err "Done with $failed failure(s)."
    exit 1
fi
write_ok "$(printf 'Done. Killed %d server(s), freed about %d MB.' "${#targets[@]}" "$(( freed / 1048576 ))")"
exit 0
