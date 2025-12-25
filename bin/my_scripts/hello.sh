#! /bin/bash

#if [ -e ~/.local/bin/my_scripts/x.txt ]
#then
#	:
#else
#	pgrep -x dwm > /dev/null && neofetch --ascii_distro tux && ~/.local/bin/my_scripts/namnsdag.py
#	pgrep -x i3 > /dev/null && neofetch && ~/.local/bin/my_scripts/namnsdag.py && date +"Week: %V"
#	pgrep -x awesome > /dev/null && neofetch && ~/.local/bin/my_scripts/namnsdag.py
#	pgrep -x Hyprland > /dev/null && neofetch --ascii_distro tux
#	# neofetch
#	touch ~/.local/bin/my_scripts/x.txt
#fi

#fastfetch --list-logos
# fastfetch -l arch
# fastfetch -l linux
# fastfetch -l debian
# fastfetch -l ubuntu

STAMP="$HOME/.local/bin/my_scripts/x.txt"

print_os_fallback() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    # PRETTY_NAME is usually the nicest
    if [ -n "${PRETTY_NAME:-}" ]; then
      echo "$PRETTY_NAME"
    else
      echo "${NAME:-Linux} ${VERSION:-}"
    fi
  else
    # last resort
    uname -sr
  fi
}

run_fetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    fastfetch -l linux
  elif command -v neofetch >/dev/null 2>&1; then
    # caller decides which neofetch variant to run, so do nothing here
    return 0
  else
    print_os_fallback
  fi
}

if [ -e "$STAMP" ]; then
  :
else
  if pgrep -x dwm >/dev/null; then
    if command -v fastfetch >/dev/null 2>&1; then
      fastfetch -l linux
    elif command -v neofetch >/dev/null 2>&1; then
      neofetch --ascii_distro tux
    else
      print_os_fallback
    fi
    "$HOME/.local/bin/my_scripts/namnsdag.py"
  fi

  if pgrep -x i3 >/dev/null; then
    if command -v fastfetch >/dev/null 2>&1; then
      fastfetch -l linux
    elif command -v neofetch >/dev/null 2>&1; then
      neofetch
    else
      print_os_fallback
    fi
    "$HOME/.local/bin/my_scripts/namnsdag.py"
    date +"Week: %V"
  fi

  if pgrep -x awesome >/dev/null; then
    if command -v fastfetch >/dev/null 2>&1; then
      fastfetch -l linux
    elif command -v neofetch >/dev/null 2>&1; then
      neofetch
    else
      print_os_fallback
    fi
    "$HOME/.local/bin/my_scripts/namnsdag.py"
  fi

  if pgrep -x Hyprland >/dev/null; then
    if command -v fastfetch >/dev/null 2>&1; then
      fastfetch -l linux
    elif command -v neofetch >/dev/null 2>&1; then
      neofetch --ascii_distro tux
    else
      print_os_fallback
    fi
  fi

  touch "$STAMP"
fi

