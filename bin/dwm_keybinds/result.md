| Key | Function | Argument |
| :-: | :-: | :- |
|  j | ACTION##stack |  INC(+2) |
|  k | ACTION##stack |  INC(-3) |
|  h | ACTION##stack |  INC(+1) |
|  l | ACTION##stack |  INC(-1) |
| Super + grave | spawns | dmenu_run -fn 'Linux Libertine Mono' |
| Super + 0 | view |  ~0 |
| Super + Shift + 0 | tag |  ~0 |
| Super + plus | incrgaps |  +3 |
| Super + minus | incrgaps |  -3 |
| Super + Shift + plus | spawns |  |
| Super + Shift + minus | spawns |  |
| Super1 + Tab | shiftview |  +1 |
| Super1 + Shift + Tab | shiftview |  -1 |
| Super + Tab | view |   |
| Super + Tab | view |   |
| Super + q | killclient |   |
| Super + Shift + x | spawns | i3lock-fancy |
| Super + Control + x | spawns | i3lock -i ~/Downloads/lock-wallpaper.png |
| Super + w | spawns | urxvt -e ranger ~/ |
| Super + e | spawns | ~/.local/bin/my_scripts/ranger_wd.sh |
| Super + Shift + e | spawns | ~/.local/bin/my_scripts/alert_exit.sh && ~/.config/polybar/forest/scripts/powermenu.sh |
| Super + y | setmfact |  -0.05 |
| Super + o | setmfact |  +0.05 |
| Super + Shift + u | incnmaster |  +1 |
| Super + Shift + i | incnmaster |  -1 |
| Super + Shift + y | shifttag |  +1 |
| Super + Shift + o | shifttag |  -1 |
| Super + bracketleft | spawns | mpc seek -10 |
| Super + Shift + bracketleft | spawns | mpc seek -60 |
| Super + bracketright | spawns | mpc seek +10 |
| Super + Shift + bracketright | spawns | mpc seek +60 |
| Super + backslash | view |   |
| Super + x | defaultgaps |   |
| Super + z | togglegaps |   |
| Super + Shift + s | spawns | import png:-  +  xclip -selection clipboard -t image/png |
| Super + Control + s | spawns | ~/.local/bin/my_scripts/tesseract_ocr.sh |
| Super + d | spawns | rofi -show run -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi |
| Super + r | spawns | dmenu_run -fn 'Linux Libertine Mono' |
| Super + Shift + d | spawns | rofi -show run -theme ~/.config/polybar/forest/scripts/rofi/launcher.rasi |
| Super + Shift + r | spawns | rofi -show run -theme ~/.config/polybar/forest/scripts/rofi/launcher.rasi |
| Super + t | spawns | ~/.local/bin/my_scripts/script_copy.sh |
| Super + Shift + t | spawns | ~/.local/bin/my_scripts/script_helper.sh |
| Super + Shift + less | togglesticky |   |
| Super + less | setlayout |  spiral  |
| Super + s | setlayout |  bstack  |
| Super + Control + t | setlayout |  tile  |
| Super + Control + y | setlayout |  dwindle  |
| Super + Control + u | setlayout |  deck  |
| Super + Control + i | setlayout |  monocle  |
| Super + Control + o | setlayout |  centeredmaster  |
| Super + Control + p | setlayout |  centeredfloatingmaster  |
| Super + Control + aring | setlayout |  float |
| Super + f | togglefullscr |   |
| Super + g | spawns | ~/.local/bin/my_scripts/fzf_open.sh |
| Super + apostrophe | togglescratch |  0 |
| Super + Shift + apostrophe | togglescratch |  1 |
| Super + BackSpace | spawns | sysact |
| Super + Shift + BackSpace | spawns | sysact |
| Super + Return | spawns | ~/.local/bin/my_scripts/term_wd.sh |
| Super + Shift + Return | spawns |  |
| Super + c | spawns | GTK_THEME=Adwaita:dark gnome-calculator |
| Super + Control + c | spawns | GTK_THEME=Adwaita:dark gnome-calendar |
| Super + b | spawns | urxvt -e htop |
| Super + Shift + b | spawns | urxvt -e bashtop |
| Super + Control + b | spawns | urxvt -e ytop |
| Super + Shift + p | togglebar |   |
| Super + n | spawns | ~/.local/bin/my_scripts/nautilus_wd.sh |
| Super + Shift + n | spawns | nautilus -w --no-desktop |
| Super + m | spawns | spotify |
| Super + Shift + m | spawns | flatpak run org.jamovi.jamovi |
| Super + Control + m | spawns | ~/.local/bin/my_scripts/tstock.sh |
| Super + comma | spawns | mpc prev |
| Super + Shift + period | spawns | i3lock-fancy && ~/.local/bin/my_scripts/alert_exit.sh && systemctl suspend |
| Super + Shift + comma | spawns | ~/.local/bin/my_scripts/alert_exit.sh && ~/.local/bin/my_scripts/suspend.sh |
| Super + v | spawns | ~/.local/bin/my_scripts/clip_history.sh |
| Super + Shift + v | spawns | ~/.local/bin/my_scripts/qr_clip.sh |
| Super + period | spawns | ~/.local/bin/my_scripts/emojipick/emojipick |
| Super + a | spawns | urxvt -e bash -c 'tmux attach  +  +  tmux' |
| Super + section | spawns | ~/.local/bin/my_scripts/loadEww.sh |
| Super + Shift + section | toggleviewontag |   |
| Super + Left | focusmon |  -1 |
| Super + Shift + Left | tagmon |  -1 |
| Super + Right | focusmon |  +1 |
| Super + Shift + Right | tagmon |  +1 |
| Super + Page_Up | shiftview |  -1 |
| Super + Shift + Page_Up | shifttag |  -1 |
| Super + Page_Down | shiftview |  +1 |
| Super + Shift + Page_Down | shifttag |  +1 |
| Super + F1 | spawns | urxvt -e nvim |
| Super + F2 | spawns | tutorialvids |
| Super + F3 | spawns | displayselect |
| Super + F4 | spawns | TERMINAL -e pulsemixer; kill -44 $(pidof dwmblocks) |
| Super + F6 | spawns | torwrap |
| Super + F7 | spawns | td-toggle |
| Super + F8 | spawns | mw -Y |
| Super + F9 | spawns | dmenumount |
| Super + F10 | spawns | dmenuumount |
| Super + F12 | spawns | remaps & notify-send \\\"⌨️ Keyboard remapping...\\\" \\\"Re-running keyboard defaults for any newly plugged-in keyboards.\\\" |
| Super + space | zoom |   |
| Super + Shift + space | togglefloating |   |
| Print | spawns | ~/.local/bin/my_scripts/screenshot_select.sh |
| Shift + Print | spawns | ~/.local/bin/my_scripts/screenshot.sh |
| Super + Print | spawns | ~/.local/bin/my_scripts/screenshot_ocr.sh |
| AudioMute | spawns | pactl set-sink-mute @DEFAULT_SINK@ toggle ; kill -44 $(pidof dwmblocks) |
| AudioRaiseVolume | spawns | pactl set-sink-volume @DEFAULT_SINK@ +5%; kill -44 $(pidof dwmblocks) |
| AudioLowerVolume | spawns | pactl set-sink-volume @DEFAULT_SINK@ -5%; kill -44 $(pidof dwmblocks) |
| MonBrightnessUp | spawns | ~/.local/bin/my_scripts/brightness.sh +10 |
| MonBrightnessDown | spawns | ~/.local/bin/my_scripts/brightness.sh -10 |
