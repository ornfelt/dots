#!/bin/bash
#
# This script will output a QR Code made with whatever you have loaded on your clipboard
# You need qrencode C Library and xclip for this script to work
#
function err {
		echo -e "[ERROR] in line ${BASH_LINENO[0]}"
			[[ $1 ]] && echo "[ MSG ] $1"
				exit 1
			}

		function printBold {
				echo -e "\n$(tput bold)\"$1\"$(tput sgr0)\n"
			}

		hash qrencode || err "qrencode not found."
		hash xclip || err "xclip not found."

		if [[ ! -z $1 ]]; then
				# if given, use arguments as target
					TARGET="$@"
				else
						# per default, get target from clipboard.
							TARGET="$( xclip -selection c -o )" || err
								[[ ! -z $TARGET ]] || err "clipboard empty."
		fi

		qrencode "$TARGET" -o temp_code.png
		feh --scale-down --auto-zoom temp_code.png

		# Optionally remove the file immediately
		rm temp_code.png

