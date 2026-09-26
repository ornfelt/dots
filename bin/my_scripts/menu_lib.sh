# Shared dmenu/rofi switch for the menu scripts in my_scripts (POSIX sh, so
# both sh and bash scripts can use it). Source it at the top of a script,
# before the script reads its own args:
#   . ~/.local/bin/my_scripts/menu_lib.sh
# It removes --dmenu / --rofi from the script's args and sets MENU: the flag
# wins, else $LAUNCHER (dmenu|rofi), else dmenu. ~/.xinitrc and hyprland.conf
# export LAUNCHER=rofi.
#
#   menu PROMPT [LINES [ROFI_ARGS...]]  pick a line from stdin, print it.
#                                       LINES: dmenu -l (default 20); rofi
#                                       keeps its theme's count when empty
#   menu_msg TEXT [ROFI_ARGS...]        show TEXT (rofi -e, a dmenu list)
#   menu_need                           exit with a message if $MENU is
#                                       unknown or not installed
#
# Call menu_need right after sourcing: menu usually runs inside $(...), where
# its own check can only end that subshell, not the script.

MENU_ROFI_THEME="$HOME/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

_menu_flag=
for _menu_arg do
    shift
    case $_menu_arg in
        --dmenu) _menu_flag=dmenu ;;
        --rofi) _menu_flag=rofi ;;
        *) set -- "$@" "$_menu_arg" ;;
    esac
done
unset _menu_arg

MENU="${_menu_flag:-${LAUNCHER:-dmenu}}"

menu_err() {
    echo "${0##*/}: $1" >&2
    command -v notify-send >/dev/null && notify-send "${0##*/}" "$1"
    exit 1
}

menu_need() {
    case $MENU in
        dmenu)
            command -v dmenu >/dev/null || menu_err "missing: dmenu. Build it with: cd ~/.config/dmenu && sudo make install"
            ;;
        rofi)
            command -v rofi >/dev/null || menu_err "missing: rofi. Install with: sudo apt install rofi"
            ;;
        *)
            menu_err "unknown launcher '$MENU' (use dmenu or rofi)"
            ;;
    esac
}

menu() {
    menu_need
    _menu_prompt=$1
    _menu_lines=$2
    shift
    [ $# -gt 0 ] && shift
    if [ "$MENU" = rofi ]; then
        rofi -dmenu -i -theme "$MENU_ROFI_THEME" -p "$_menu_prompt" ${_menu_lines:+-l "$_menu_lines"} "$@"
    else
        dmenu -i -l "${_menu_lines:-20}" ${_menu_prompt:+-p "$_menu_prompt"}
    fi
}

menu_msg() {
    menu_need
    _menu_text=$1
    shift
    if [ "$MENU" = rofi ]; then
        rofi -theme "$MENU_ROFI_THEME" "$@" -e "$_menu_text"
    else
        printf '%s\n' "$_menu_text" | dmenu -l "$(printf '%s\n' "$_menu_text" | wc -l)" >/dev/null
    fi
}
