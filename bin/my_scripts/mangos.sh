#!/usr/bin/env bash

write_label() { printf '\033[90m%s\033[0m\n' "$1"; } # Dark gray
#write_cmd()  { printf '\033[36m%s\033[0m\n' "$1"; } # Cyan
write_alt()   { printf '\033[35m%s\033[0m\n' "$1"; } # Magenta
write_extra() { printf '\033[34m%s\033[0m\n' "$1"; } # Blue
write_warn()  { printf '\033[33m%s\033[0m\n' "$1"; } # Dark yellow
write_ok()    { printf '\033[32m%s\033[0m\n' "$1"; } # Green
write_err()   { printf '\033[31m%s\033[0m\n' "$1"; } # Red

#print_config_path=false
print_config_path=true

# Data dirs each server needs (Buildings/ is extractor scratch and never checked)
VMANGOS_REQUIRED_DIRS="5875 maps mmaps vmaps"
MANGOS_CLASSIC_REQUIRED_DIRS="dbc maps mmaps vmaps"
MANGOS_TBC_REQUIRED_DIRS="dbc maps"
# Current mangoszero reads tiles/ + gomodels/ (World.cpp) instead of maps/ + vmaps/
MANGOSZERO_REQUIRED_DIRS="dbc gomodels mmaps tiles"

# Reported but not treated as an error. cmangos reads Cameras/ for cinematic camera paths
# (LoadM2Cameras) but starts without it; older mangos-tbc builds ran without mmaps/vmaps.
MANGOS_CLASSIC_OPTIONAL_DIRS="Cameras"
MANGOS_TBC_OPTIONAL_DIRS="Cameras mmaps vmaps"
NO_OPTIONAL_DIRS=""

# Extracted data (finish_*_extraction.py output) is looked for here first; the binary dir is
# the fallback. Each server's dir name is set in its branch below.
LOCAL_DATA_ROOT="$HOME/Documents/local"
SERVER_CONF="mangosd.conf"

resolve_data_path() {
    # resolve_data_path <local data path> <binary path> <required dirs>
    # Sets data_path: the local extracted-data dir if it holds any of the required dirs,
    # else the binary dir.
    local local_data_path="$1"
    local exe_path="$2"
    local required_dirs="$3"
    local dir_name

    if [[ -n "$local_data_path" && -d "$local_data_path" ]]; then
        for dir_name in $(printf '%s\n' "$required_dirs"); do
            if [[ -d "$local_data_path/$dir_name" ]]; then
                write_label "Using extracted data dir: $local_data_path"
                data_path="$local_data_path"
                return 0
            fi
        done
        write_warn "$local_data_path holds none of: $required_dirs - falling back to the binary dir."
    elif [[ -n "$local_data_path" ]]; then
        write_warn "$local_data_path not found - falling back to the binary dir."
    fi

    write_label "Using data in the binary dir: $exe_path"
    data_path="$exe_path"
}

comparable_path() {
    # Absolute path without a trailing slash; realpath -m also resolves missing paths
    realpath -m -- "$1" 2>/dev/null || printf '%s\n' "${1%/}"
}

test_conf_data_dir() {
    # test_conf_data_dir <binary path> <data path>
    # The server only reads DataDir from its conf, so say so when it points elsewhere.
    local exe_path="$1"
    local data_path="$2"
    local conf_file conf_data_dir resolved

    if ! conf_file="$(find_config_file "$SERVER_CONF")"; then
        write_warn "$SERVER_CONF was not found - cannot check DataDir."
        return
    fi

    conf_data_dir="$(
        sed -n 's/^[[:space:]]*DataDir[[:space:]]*=[[:space:]]*"\{0,1\}\([^"#]*\)"\{0,1\}.*/\1/p' "$conf_file" |
            head -n 1
    )"
    conf_data_dir="$(printf '%s' "$conf_data_dir" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

    if [[ -z "$conf_data_dir" ]]; then
        write_warn "DataDir was not found in $SERVER_CONF."
        return
    fi

    if [[ "$conf_data_dir" == /* ]]; then
        resolved="$conf_data_dir"
    else
        resolved="$exe_path/$conf_data_dir"
    fi

    if [[ "$(comparable_path "$resolved")" == "$(comparable_path "$data_path")" ]]; then
        write_ok "DataDir in $SERVER_CONF points at the data dir: $conf_data_dir"
    else
        write_err "DataDir in $SERVER_CONF is \"$conf_data_dir\" but the data was found in $data_path."
    fi
}

test_required_dirs() {
    # test_required_dirs <path> <required dirs> <optional dirs>
    local path="$1"
    local required_dirs="$2"
    local optional_dirs="$3"
    local dir_name missing="" missing_count=0 required_count=0

    for dir_name in $(printf '%s\n' "$required_dirs"); do
        required_count=$((required_count + 1))

        if [[ -d "$path/$dir_name" ]]; then
            write_ok "$dir_name/ found."
        else
            write_err "$dir_name/ is missing from $path"
            missing="${missing:+$missing, }$dir_name"
            missing_count=$((missing_count + 1))
        fi
    done

    for dir_name in $(printf '%s\n' "$optional_dirs"); do
        if [[ -d "$path/$dir_name" ]]; then
            write_ok "$dir_name/ found."
        else
            write_warn "$dir_name/ is missing - optional, the server starts without it."
        fi
    done

    if (( missing_count > 0 )); then
        write_warn "$missing_count of $required_count required dir(s) missing: $missing"
    fi
}

find_config_file() {
    local file="$1"

    if [[ -f "../etc/$file" ]]; then
        printf '%s\n' "../etc/$file"
    elif [[ -f "$file" ]]; then
        printf '%s\n' "$file"
    else
        return 1
    fi
}

test_disabled_setting() {
    local file="$1"
    local setting="$2"
    local file_name="$3"
    local client_name="$4"
    local start_line="${5:-1}"
    local end_line="${6:-999999999}"
    local value

    value="$(
        awk \
            -v setting="$setting" \
            -v start_line="$start_line" \
            -v end_line="$end_line" '
            NR < start_line || NR > end_line {
                next
            }

            {
                line = $0
                sub(/^[[:space:]]*/, "", line)

                if (line ~ /^#/) {
                    next
                }

                pos = index(line, "=")
                if (!pos) {
                    next
                }

                key = substr(line, 1, pos - 1)
                value = substr(line, pos + 1)

                gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)

                if (key == setting) {
                    sub(/^[[:space:]]*/, "", value)
                    sub(/[[:space:]#].*$/, "", value)
                    print value
                    exit
                }
            }
        ' "$file"
    )"

    if [[ -z "$value" ]]; then
        write_warn "$setting was not found in $file_name."
    elif [[ "$value" == "0" ]]; then
        write_ok "$setting = 0 in $file_name - correctly disabled."
    elif [[ "$value" == "1" ]]; then
        write_err "$setting = 1 in $file_name - it needs to be disabled to use custom clients like $client_name."
    else
        write_warn "$setting has unexpected value '$value' in $file_name."
    fi
}

# Usage (no server name = vmangos):
#   mangos.sh
#   mangos.sh tbc        (same as t, mangos-tbc, mangostbc, cmangos-tbc)
#   mangos.sh classic    (same as c, cm, cmangos, mangos-classic)
#   mangos.sh zero       (same as 0, z, mz, mangos0, mangoszero)
SERVER_NAMES_HELP="vmangos (v, vm), cmangos (c, cm, classic, mangos-classic), cmangos-tbc (t, tbc, mangos-tbc), mangoszero (0, z, zero, mz, mangos0)"
DEFAULT_SERVER="vmangos"

resolve_server() {
    # resolve_server <name> - prints the server for an accepted name, matched lower-cased with
    # '-', '_', '.' and spaces dropped. Keep in sync with mangos.ps1 and update_conf_classic.py.
    # Use `tr` instead of Bash-only `${1,,}` because this script may be
    # sourced from another shell, such as zsh. The shebang is ignored when sourced.
    local key
    key="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d ' ._-')"

    case "$key" in
    v|vm|vmangos) printf '%s\n' "vmangos" ;;
    c|cm|classic|cmangos|cmangosclassic|mangosclassic) printf '%s\n' "cmangos" ;;
    t|tbc|mangostbc|cmangostbc) printf '%s\n' "cmangos-tbc" ;;
    0|z|zero|mz|mangos0|mangoszero) printf '%s\n' "mangoszero" ;;
    *) return 1 ;;
    esac
}

if [[ -z "${1:-}" ]]; then
    server="$DEFAULT_SERVER"
elif ! server="$(resolve_server "$1")"; then
    write_err "Unknown server '$1'. Accepted: $SERVER_NAMES_HELP"

    # Return when sourced; exit when executed directly.
    return 1 2>/dev/null || exit 1
fi

case "$server" in
mangoszero)
    write_alt "MangosZero chosen..."
    mangos_path="$HOME/mangoszero/run/bin"
    required_dirs="$MANGOSZERO_REQUIRED_DIRS"
    optional_dirs="$NO_OPTIONAL_DIRS"
    local_data_path="$LOCAL_DATA_ROOT/mangos_zero_linux"
    ;;

cmangos)
    write_alt "Cmangos chosen..."
    mangos_path="$HOME/cmangos/run/bin"
    required_dirs="$MANGOS_CLASSIC_REQUIRED_DIRS"
    optional_dirs="$MANGOS_CLASSIC_OPTIONAL_DIRS"
    local_data_path=""
    ;;

cmangos-tbc)
    write_alt "Cmangos tbc chosen..."
    mangos_path="$HOME/cmangos-tbc/run/bin"
    required_dirs="$MANGOS_TBC_REQUIRED_DIRS"
    optional_dirs="$MANGOS_TBC_OPTIONAL_DIRS"
    local_data_path="$LOCAL_DATA_ROOT/mangos_tbc_linux"
    ;;

vmangos)
    write_alt "Vmangos chosen..."
    mangos_path="$HOME/vmangos/bin"
    required_dirs="$VMANGOS_REQUIRED_DIRS"
    optional_dirs="$NO_OPTIONAL_DIRS"
    local_data_path="$LOCAL_DATA_ROOT/vmangos_linux"
    ;;
esac

if [[ ! -d "$mangos_path" ]]; then
    write_warn "Directory does not exist: $mangos_path"

    # Return when sourced; exit when executed directly.
    return 1 2>/dev/null || exit 1
fi

if ! cd -- "$mangos_path"; then
    write_warn "Could not enter directory: $mangos_path"

    # Return when sourced; exit when executed directly.
    return 1 2>/dev/null || exit 1
fi

write_label "Current directory: $mangos_path"

printf '\n'

resolve_data_path "$local_data_path" "$mangos_path" "$required_dirs"
test_required_dirs "$data_path" "$required_dirs" "$optional_dirs"
test_conf_data_dir "$mangos_path" "$data_path"

if [[ "$server" == "cmangos-tbc" ]]; then
    printf '\n'

    if anticheat_file="$(find_config_file "anticheat.conf")"; then
        if [[ "$print_config_path" == true ]]; then
            write_label "Config: $anticheat_file"
        fi

        anticheat_section="$(
            awk '
                /^[[:space:]]*\[AnticheatConf\]/ {
                    print NR
                    exit
                }
            ' "$anticheat_file"
        )"

        if [[ -z "$anticheat_section" ]]; then
            write_warn "[AnticheatConf] was not found in anticheat.conf."
        else
            start_line=$((anticheat_section + 1))
            end_line=$((anticheat_section + 20))

            test_disabled_setting \
                "$anticheat_file" \
                "Enable" \
                "anticheat.conf" \
                "wow_client (wc)" \
                "$start_line" \
                "$end_line"
        fi

        test_disabled_setting \
            "$anticheat_file" \
            "Warden.Enable" \
            "anticheat.conf" \
            "wow_client (wc)"
    else
        write_label "anticheat.conf was not found."
    fi

    if realmd_file="$(find_config_file "realmd.conf")"; then
        if [[ "$print_config_path" == true ]]; then
            write_label "Config: $realmd_file"
        fi

        test_disabled_setting \
            "$realmd_file" \
            "StrictVersionCheck" \
            "realmd.conf" \
            "wow_client (wc)"
    else
        write_warn "realmd.conf was not found."
    fi

    printf '\n'

elif [[ "$server" == "vmangos" ]]; then
    printf '\n'

    if realmd_file="$(find_config_file "realmd.conf")"; then
        if [[ "$print_config_path" == true ]]; then
            write_label "Config: $realmd_file"
        fi

        test_disabled_setting \
            "$realmd_file" \
            "StrictVersionCheck" \
            "realmd.conf" \
            "benilla"
    else
        write_warn "realmd.conf was not found."
    fi

    printf '\n'
fi

write_extra "$mangos_path/realmd && $mangos_path/mangosd"

# Run the commands:
#"$path/realmd" && "$path/mangosd"
