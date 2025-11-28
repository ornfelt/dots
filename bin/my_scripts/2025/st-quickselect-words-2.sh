#!/bin/sh

# expanded version of:
# $HOME/.local/bin/my_scripts/2025/st-quickselect-words.sh

# Quick-select "words" based on WezTerm-like PCRE and either copy (-c, default)
# or xdg-open (-o) the chosen item.

MODE="copy"  # default

while getopts "hoc" opt; do
  case "$opt" in
    h)
      cat <<EOF
Usage: st-quickselect-words [-c|-o]

Reads from stdin, extracts "words" using a WezTerm-like PCRE pattern,
shows them in a menu (dmenu/rofi), and then:

  -c   Copy the chosen word to the clipboard (default)
  -o   xdg-open the chosen word (useful if it's a URL/file)
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

tmpfile=$(mktemp /tmp/st-quick-words.XXXXXX)
trap 'rm -f "$tmpfile"' 0 1 15

cat > "$tmpfile"

# strip st sidebars:
sed -i 's/.*│//g' "$tmpfile"

# WezTerm-like PCRE pattern for words:
pattern="([^│\\s]\\S*?(?=:\\d|[>\"']|\$))|([^│\\s]\\S{2,}?(?=[>\"']|\$| ))"

matches=$(grep -aPo "$pattern" "$tmpfile" | sort -u)

[ -z "$matches" ] && exit 1

menu="${ST_MENU:-dmenu}"
prompt="Copy/open which word?"

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

