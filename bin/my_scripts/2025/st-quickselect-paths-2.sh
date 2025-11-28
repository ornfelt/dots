#!/bin/sh

# expanded version of:
# $HOME/.local/bin/my_scripts/2025/st-quickselect-paths.sh

# Quick-select paths using WezTerm-like PCRE patterns and either copy (-c,
# default) or xdg-open (-o) the chosen path.

MODE="copy"  # default

while getopts "hoc" opt; do
  case "$opt" in
    h)
      cat <<EOF
Usage: st-quickselect-paths [-c|-o]

Reads from stdin, extracts paths using WezTerm-like PCRE patterns,
shows them in a menu (dmenu/rofi), and then:

  -c   Copy the chosen path to the clipboard (default)
  -o   xdg-open the chosen path
  -h   Show this help

Menu selection is controlled via env vars:
  ST_MENU       = dmenu (default) or rofi
EOF
      exit 0
      ;;
    c) MODE="copy" ;;
    o) MODE="open" ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

tmpfile=$(mktemp /tmp/st-quick-paths.XXXXXX)
trap 'rm -f "$tmpfile"' 0 1 15

cat > "$tmpfile"

# strip st sidebars:
sed -i 's/.*│//g' "$tmpfile"

# Combined WezTerm-like PCRE for paths:
# Unix-style paths
# Windows drive paths
# \\seusers.*.com UNC variants
# PowerShell $env:VAR\path
pattern='(?:[-._~#+/a-zA-Z0-9$])*/(?:[-._~#+/a-zA-Z0-9$]*)|[a-zA-Z]:[/\\]+(?:[-._#$:+~a-zA-Z0-9/\\ ]+)|\\\\seusers\.*\.com[/\\](?:[-._#$:+~a-zA-Z0-9/\\ ]+)|\\\\seusers\.*\.com[/\\]+(?:[-._#$:+~a-zA-Z0-9/\\ ]+)|\$env:[a-zA-Z_][A-Za-z0-9_]*[\\/]+(?:[-._~#+/a-zA-Z0-9$]*)'

matches=$(grep -aPo "$pattern" "$tmpfile" | sort -u)

[ -z "$matches" ] && exit 1

menu="${ST_MENU:-dmenu}"
prompt="Copy/open which path?"

# pick menu program dynamically
if [ "$menu" = "rofi" ]; then
  choice=$(printf '%s\n' "$matches" | rofi -theme "gruvbox-dark.rasi" -p "$prompt" -dmenu -i -l 10)
else
  # default: dmenu
  choice=$(printf '%s\n' "$matches" | dmenu -p "$prompt" -i -l 10)
fi

[ -z "$choice" ] && exit 1

case "$MODE" in
  copy)
    printf '%s' "$choice" | tr -d '\n' | xclip -selection clipboard
    ;;
  open)
    setsid xdg-open "$choice" >/dev/null 2>&1 &
    ;;
esac

