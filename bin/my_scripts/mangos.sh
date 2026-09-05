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

# Data dirs each server needs next to its binary
VMANGOS_REQUIRED_DIRS="5875 Cameras maps mmaps vmaps"
MANGOS_CLASSIC_REQUIRED_DIRS="Cameras dbc maps mmaps vmaps"
MANGOS_TBC_REQUIRED_DIRS="Buildings Cameras dbc maps"
MANGOSZERO_REQUIRED_DIRS="dbc maps mmaps vmaps"

# Reported but not treated as an error - older mangos-tbc builds ran without these
MANGOS_TBC_OPTIONAL_DIRS="mmaps vmaps"
NO_OPTIONAL_DIRS=""

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
            write_warn "$dir_name/ is missing - optional, older builds did not need it."
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

# Use `tr` instead of Bash-only `${1,,}` because this script may be
# sourced from another shell, such as zsh. The shebang is ignored when sourced.
server="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"

case "$server" in
0|z)
    write_alt "MangosZero chosen..."
    mangos_path="$HOME/mangoszero/run/bin"
    required_dirs="$MANGOSZERO_REQUIRED_DIRS"
    optional_dirs="$NO_OPTIONAL_DIRS"
    ;;

c)
    write_alt "Cmangos chosen..."
    mangos_path="$HOME/cmangos/run/bin"
    required_dirs="$MANGOS_CLASSIC_REQUIRED_DIRS"
    optional_dirs="$NO_OPTIONAL_DIRS"
    ;;

tbc)
    write_alt "Cmangos tbc chosen..."
    mangos_path="$HOME/cmangos-tbc/run/bin"
    required_dirs="$MANGOS_TBC_REQUIRED_DIRS"
    optional_dirs="$MANGOS_TBC_OPTIONAL_DIRS"
    ;;

*)
    write_alt "Vmangos chosen..."
    mangos_path="$HOME/vmangos/bin"
    required_dirs="$VMANGOS_REQUIRED_DIRS"
    optional_dirs="$NO_OPTIONAL_DIRS"
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

test_required_dirs "$mangos_path" "$required_dirs" "$optional_dirs"

if [[ "$server" == "tbc" ]]; then
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

elif [[ "$server" != "0" && "$server" != "z" && "$server" != "c" ]]; then
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
