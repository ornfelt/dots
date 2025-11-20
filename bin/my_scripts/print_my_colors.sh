#!/usr/bin/env bash

# print all 256 terminal colors with their numbers

# Show all 256 foreground colors
for i in {0..255}; do
  printf "\e[38;5;%sm%3s\e[0m " "$i" "$i"
  # Newline every 16 colors
  if (( (i + 1) % 16 == 0 )); then
    printf "\n"
  fi
done

printf "\n"

