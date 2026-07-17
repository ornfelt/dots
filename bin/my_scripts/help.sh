#!/usr/bin/env bash

arg="$1"
keyword="$2"

# Colors (ANSI escape codes)
RESET='\033[0m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'
DARKYELLOW='\033[93m'

# Load shared JSON data
if [[ -z "${my_notes_path:-}" ]]; then
  printf "Error: environment variable 'my_notes_path' is not set\n" >&2
  exit 1
fi

JSON_PATH="$my_notes_path/scripts/help_data.json"

if [[ ! -f "$JSON_PATH" ]]; then
  printf "Error: %s not found\n" "$JSON_PATH" >&2
  exit 1
fi

# Requires: jq
if ! command -v jq &>/dev/null; then
  printf "Error: jq is required but not installed\n" >&2
  exit 1
fi

JSON_DATA="$(cat "$JSON_PATH")"

# Helper: command + description
write_command_with_description() {
  local cmd_text="$1"
  local desc="$2"
  local color="${3:-$CYAN}"

  printf "  "
  printf "%b%s%b" "$color" "$cmd_text" "$RESET"
  if [[ -n "$desc" ]]; then
    printf " - %s\n" "$desc"
  else
    printf "\n"
  fi
}

# Helper: code line, with a shell-style comment in gray.
# A # is considered a comment when:
#   - it starts the line, optionally after whitespace, or
#   - it is preceded by whitespace
#
# The greedy regex selects the last whitespace-prefixed #.
write_code_line() {
  local text="$1"
  local command_color="${2:-$GREEN}"
  local comment_color="${3:-$DARKGRAY}"

  local before
  local comment

  # Entire line is a comment, optionally indented.
  if [[ "$text" =~ ^[[:space:]]*# ]]; then
    printf "%b%s%b\n" "$comment_color" "$text" "$RESET"

  # Inline comment. The first capture is greedy, so this uses the last
  # whitespace-prefixed # in the line.
  elif [[ "$text" =~ ^(.*[^[:space:]])([[:space:]]+#.*)$ ]]; then
    before="${BASH_REMATCH[1]}"
    comment="${BASH_REMATCH[2]}"

    printf "%b%s%b" "$command_color" "$before" "$RESET"
    printf "%b%s%b\n" "$comment_color" "$comment" "$RESET"
  else
    printf "%b%s%b\n" "$command_color" "$text" "$RESET"
  fi
}

write_clean_warning() {
  printf "%bBe careful: below command(s) hard-delete generated files/folders from the current directory.%b\n" "$DARKYELLOW" "$RESET"
}

# Helper: check if section text matches keyword (case-insensitive)
test_section_match() {
  local section_text="$1"
  local kw="$2"
  [[ -z "$kw" ]] && return 0
  local lower_section="${section_text,,}"
  local lower_kw="${kw,,}"
  [[ "$lower_section" == *"$lower_kw"* ]]
}

# Print "Filtered by keyword: ..." when keyword is provided
write_keyword_filter() {
  local kw="$1"
  if [[ -n "$kw" ]]; then
    printf "%bFiltered by keyword: %s%b\n" "$DARKGRAY" "$kw" "$RESET"
  fi
}

# Helper for path-entry keyword filtering (matches on label+path)
show_path_entry() {
  local label="$1"
  local path_val="$2"
  local kw="$3"

  if [[ -n "$kw" ]]; then
    local k="${kw,,}"
    local haystack="${label} ${path_val}"
    haystack="${haystack,,}"
    if [[ "$haystack" != *"$k"* ]]; then
      return
    fi
  fi

  printf "%b%s:%b\n" "$DARKGRAY" "$label" "$RESET"
  printf "%b%s%b\n\n" "$GREEN" "$path_val" "$RESET"
}

# Usage / main help
show_usage() {
  local args_json
  args_json="$(echo "$JSON_DATA" | jq -r '.args_display[]')"

  while IFS= read -r a; do
    printf "  %b%s%b\n" "$MAGENTA" "$a" "$RESET"
  done <<< "$args_json"

  printf "\n"
  printf "  %bOptional second arg: keyword to filter sections%b\n" "$DARKGRAY" "$RESET"
  printf "  %bExample: .help cs clean%b\n" "$DARKGRAY" "$RESET"
  printf "  %bExample: .help scripts build%b\n" "$DARKGRAY" "$RESET"
}

# Render a single item from JSON
render_item() {
  local item_json="$1"
  local kw="$2"

  local item_type
  item_type="$(echo "$item_json" | jq -r '.type')"

  case "$item_type" in
    code)
      local text
      text="$(echo "$item_json" | jq -r '.text')"
      write_code_line "$text"
      ;;
    cmd)
      local cmd_text desc
      cmd_text="$(echo "$item_json" | jq -r '.cmd')"
      desc="$(echo "$item_json" | jq -r '.desc // empty')"
      write_command_with_description "$cmd_text" "$desc"
      ;;
    header)
      local text
      text="$(echo "$item_json" | jq -r '.text')"
      printf "%b%s%b\n" "$YELLOW" "$text" "$RESET"
      ;;
    comment)
      local text
      text="$(echo "$item_json" | jq -r '.text')"
      printf "%b%s%b\n" "$DARKGRAY" "$text" "$RESET"
      ;;
    blank)
      printf "\n"
      ;;
    clean_warning)
      write_clean_warning
      ;;
    path)
      local label path_val
      label="$(echo "$item_json" | jq -r '.label')"
      path_val="$(echo "$item_json" | jq -r '.path')"
      show_path_entry "$label" "$path_val" "$kw"
      ;;
  esac
}

# Generic section renderer: reads mode from JSON, filters by platform and keyword
show_section() {
  local mode_name="$1"
  local kw="$2"

  local mode_json
  mode_json="$(echo "$JSON_DATA" | jq -c ".modes[\"$mode_name\"]")"
  if [[ "$mode_json" == "null" || -z "$mode_json" ]]; then
    return
  fi

  # Print mode title
  local title leading_blank
  title="$(echo "$mode_json" | jq -r '.title_linux // .title')"
  leading_blank="$(echo "$mode_json" | jq -r '.leading_blank')"

  if [[ "$leading_blank" == "true" ]]; then
    printf "\n"
  fi
  printf "%b%s%b\n" "$YELLOW" "$title" "$RESET"
  write_keyword_filter "$kw"
  if [[ "$leading_blank" != "true" ]]; then
    printf "\n"
  fi

  # Iterate subsections
  local sub_count
  sub_count="$(echo "$mode_json" | jq '.subsections | length')"

  for (( si=0; si<sub_count; si++ )); do
    local match_str
    match_str="$(echo "$mode_json" | jq -r ".subsections[$si].match")"

    if ! test_section_match "$match_str" "$kw"; then
      continue
    fi

    local item_count
    item_count="$(echo "$mode_json" | jq ".subsections[$si].items | length")"

    for (( ii=0; ii<item_count; ii++ )); do
      local item_json platform
      item_json="$(echo "$mode_json" | jq -c ".subsections[$si].items[$ii]")"
      platform="$(echo "$item_json" | jq -r '.platform // "both"')"

      # Filter: skip windows-only items
      if [[ "$platform" == "windows" ]]; then
        continue
      fi

      render_item "$item_json" "$kw"
    done
  done
}

# Main

# No arg -> print ONLY available args
if [[ -z "$arg" ]]; then
  show_usage
  exit 0
fi

key="${arg,,}"  # to lower-case (bash 4+)

# Look up alias in JSON
mode="$(echo "$JSON_DATA" | jq -r ".aliases[\"$key\"] // empty")"

if [[ -z "$mode" ]]; then
  # Unknown arg -> print ONLY available args (no extra text)
  show_usage
  exit 0
fi

printf "%bSelected: %s%b\n" "$MAGENTA" "$mode" "$RESET"
if [[ -n "$keyword" ]]; then
  printf "%bKeyword: %s%b\n" "$DARKYELLOW" "$keyword" "$RESET"
fi

show_section "$mode" "$keyword"
