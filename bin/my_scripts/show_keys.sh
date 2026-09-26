#!/usr/bin/env bash

# dwm/dwmc/dwmr: build the key list from the "bind <key>: <what>" comments in
# the running variant's config each time, so it can't go stale the way the
# copied ~/.local/bin/dwm_keybinds/keys did
dwm_keys() {
	if pgrep -x dwmr >/dev/null; then conf=~/.config/dwmr/config.toml
	elif pgrep -x dwmc >/dev/null; then conf=~/.config/dwmc/config.h
	else conf=~/.config/dwm/config.h
	fi
	out="${XDG_CACHE_HOME:-$HOME/.cache}/dwm_keys.txt"
	mkdir -p "$(dirname "$out")"
	# C: /* bind mod-q: killclient */   toml: # /* bind mod-q: killclient */
	binds=$(sed -nE 's|^\s*(# )?/\* bind ([^:]+): (.*) \*/\s*$|\2\t\3|p' "$conf")
	{
		echo "Keybinds from $conf"
		echo
		echo "Keys"
		echo "----"
		grep -v "button" <<< "$binds" | awk -F '\t' '{ printf "%-26s %s\n", $1, $2 }'
		echo
		echo "Mouse"
		echo "-----"
		grep "button" <<< "$binds" | awk -F '\t' '{ printf "%-32s %s\n", $1, $2 }'
	} > "$out"
}

# i3: build the key list from the bindsym lines of the i3 config each time,
# top-level keys first, then each mode's keys
i3_keys() {
	conf=~/.config/i3/config
	out="${XDG_CACHE_HOME:-$HOME/.cache}/i3_keys.txt"
	mkdir -p "$(dirname "$out")"
	{
		echo "Keybinds from $conf"
		echo
		awk '
		function keyname(k,   n, parts, i, p, s) {
			n = split(k, parts, "+")
			for (i = 1; i <= n; i++) {
				p = parts[i]
				if (p == "$mod" || p == "Mod4") p = "mod"
				else if (p == "Mod1") p = "alt"
				else if (p == "Shift") p = "shift"
				else if (p == "Control" || p == "Ctrl") p = "ctrl"
				s = s (i > 1 ? "-" : "") p
			}
			return s
		}
		/^[[:space:]]*mode "/ {
			match($0, /"[^"]*"/)
			mode = substr($0, RSTART + 1, RLENGTH - 2)
			modes[++nm] = mode
			next
		}
		/^[[:space:]]*}/ { mode = ""; next }
		/^[[:space:]]*bindsym[[:space:]]/ {
			line = $0
			sub(/^[[:space:]]*bindsym[[:space:]]+/, "", line)
			while (line ~ /^--/) sub(/^--[^[:space:]]+[[:space:]]+/, "", line)
			key = line; sub(/[[:space:]].*/, "", key)
			cmd = line; sub(/^[^[:space:]]+[[:space:]]+/, "", cmd)
			sub(/--no-startup-id /, "", cmd)
			gsub(/~\/\.local\/bin\/my_scripts\//, "", cmd)
			entry = sprintf("%-26s %s", keyname(key), cmd)
			if (mode == "") keys[++nk] = entry
			else modekeys[mode, ++cnt[mode]] = entry
		}
		END {
			print "Keys"; print "----"
			for (i = 1; i <= nk; i++) print keys[i]
			for (j = 1; j <= nm; j++) {
				m = modes[j]
				print ""; print "Mode \"" m "\""; print "----"
				for (i = 1; i <= cnt[m]; i++) print modekeys[m, i]
			}
		}' "$conf"
	} > "$out"
}

# The terminal to open the list in; wezterm if the caller didn't pass one
term="${2:-wezterm}"

case $1 in
	"dwm") dwm_keys; $term -e nvim -R "$out" ;;
	"i3") i3_keys; $term -e nvim -R "$out" ;;
	"hyprland") $term -e bash -c 'nvim ~/.config/hypr/hyprland.conf;' ;;
esac

