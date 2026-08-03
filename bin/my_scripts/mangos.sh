#!/usr/bin/env bash

write_label() { printf '\033[90m%s\033[0m\n' "$1"; } # Dark gray
#write_cmd()  { printf '\033[36m%s\033[0m\n' "$1"; } # Cyan
write_alt()   { printf '\033[35m%s\033[0m\n' "$1"; } # Magenta
write_extra() { printf '\033[34m%s\033[0m\n' "$1"; } # Blue
write_warn()  { printf '\033[33m%s\033[0m\n' "$1"; } # Dark yellow

# Use `tr` instead of Bash-only `${1,,}` because this script may be
# sourced from another shell, such as zsh. The shebang is ignored when sourced.
server="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"

case "$server" in
    0|z)
        write_alt "MangosZero chosen..."
        mangos_path="$HOME/mangoszero/run/bin"
        ;;

    c)
        write_alt "Cmangos chosen..."
        mangos_path="$HOME/cmangos/run/bin"
        ;;

    tbc)
        write_alt "Cmangos tbc chosen..."
        mangos_path="$HOME/cmangos-tbc/run/bin"
        ;;

    *)
        write_alt "Vmangos chosen..."
        mangos_path="$HOME/vmangos/bin"
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
write_extra "$mangos_path/realmd && $mangos_path/mangosd"

# Run the commands:
#"$path/realmd" && "$path/mangosd"

