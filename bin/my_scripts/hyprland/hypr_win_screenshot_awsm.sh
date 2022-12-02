#! /usr/bin/bash
grim -g "$(slurp)" | xclip -selection clipboard -t image/png
