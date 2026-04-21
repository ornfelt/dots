#!/usr/bin/env bash

arg="$1"

# Colors (ANSI escape codes)
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'

# Unified argument alias map (languages + tools)
declare -A ARG_MAP=(
  # Languages
  [c]="c"
  [cs]="csharp"
  ["c#"]="csharp"
  [csharp]="csharp"
  [cpp]="cpp"
  ["c++"]="cpp"
  [go]="go"
  [golang]="go"
  [java]="java"
  [js]="javascript"
  [javascript]="javascript"
  [ts]="typescript"
  [typescript]="typescript"
  [py]="python"
  [python]="python"
  [rust]="rust"
  [rs]="rust"

  # Tools
  [git]="git"
  [grep]="grep"
  [gitgrep]="gitgrep"
  [ggrep]="gitgrep"
  [ripgrep]="ripgrep"
  [rgrep]="ripgrep"
  [env]="env"
  [sh]="other"
  [x]="other"
  [other]="other"
  [scripts]="scripts"
  [script]="scripts"
  [paths]="paths"
  [path]="paths"
  [p]="paths"
)

# Helper: command + description
write_command_with_description() {
  local cmd="$1"
  local desc="$2"
  local color="${3:-$CYAN}"

  printf "  "
  printf "%b%s%b" "$color" "$cmd" "$RESET"
  if [[ -n "$desc" ]]; then
    printf " - %s\n" "$desc"
  else
    printf "\n"
  fi
}

# Helper: code line, with comment (#...) in gray
write_code_line() {
  local text="$1"
  local command_color="${2:-$GREEN}"
  local comment_color="${3:-$DARKGRAY}"

  if [[ "$text" == *"#"* ]]; then
    # Split at first '#'
    local before="${text%%#*}"
    local comment="${text#*#}"   # part after first '#'
    if [[ -n "${before// }" ]]; then
      printf "%b%s%b" "$command_color" "$before" "$RESET"
    fi
    printf "%b#%s%b\n" "$comment_color" "$comment" "$RESET"
  else
    printf "%b%s%b\n" "$command_color" "$text" "$RESET"
  fi
}

# Usage / main help
show_usage() {
  printf "Available arguments (case-insensitive):\n"

  local args=(
    # Languages
    "c"
    "cs / c# / csharp"
    "cpp / c++"
    "go / golang"
    "java"
    "js / javascript"
    "ts / typescript"
    "py / python"
    "rust / rs"
    # Other groups
    "git"
    "grep"
    "gitgrep / ggrep"
    "ripgrep / rgrep"
    "env"
    "sh / x / other"
    "scripts / script"
    "paths / path / p"
  )

  for a in "${args[@]}"; do
    printf "  %b%s%b\n" "$MAGENTA" "$a" "$RESET"
  done
}

show_git_help() {
  printf "%bgit commands:%b\n\n" "$YELLOW" "$RESET"

  write_code_line 'git push https://$GITHUB_TOKEN@github.com/ornfelt/small_games'
  write_code_line 'git clone --recurse-submodules -j8 https://$GITHUB_TOKEN@github.com/ornfelt/my_wow_docs'

  printf "\n"
  write_code_line "git log --graph --decorate                    # Display history with graph and decorate"
  write_code_line "git show HEAD > latest_changes.diff           # Generate diff showing changes from latest commit"
  write_code_line "git show HEAD^ > latest_changes.diff          # Generate diff showing changes from second latest commit"
  write_code_line "git show c7aa908 -- '*.go' > go_fixes.diff    # Generate diff for a commit, filter on file type"
  write_code_line "git diff cbceb5a..HEAD -- '**/*.java' '*.cs' > new_java_cs_changes.diff  # Diff range, filter types"
  write_code_line 'cd "$code_root_dir/Code2/C#/dotnet-integration" && git apply $my_notes_path/notes/svea/diffs/testshop_dev.diff --verbose  # Apply patch'
}

show_scripts_help() {
  printf "%bdot commands / scripts:%b\n\n" "$YELLOW" "$RESET"

  printf "%bNavigation / cd helpers:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".cdh"        "cd into home dir"
  write_command_with_description ".cdc"        "cd into code_root_dir"
  write_command_with_description ".cdn"        "cd into my_notes_path"
  write_command_with_description ".cdp"        "cd into ps_profile_path"
  write_command_with_description ".docs"       "cd into Documents"
  write_command_with_description ".down"       "cd into Downloads"
  write_command_with_description ".pics"       "cd into Pictures"
  write_command_with_description ".scripts"    "cd into $HOME/.local/bin/my_scripts"
  write_command_with_description ".dots"       "cd into $HOME/Downloads/dotfiles"
  write_command_with_description ".cnf"        "cd into $HOME/.config"
  write_command_with_description ".cnfa"       "cd into $HOME/.config/awesome"
  write_command_with_description ".cnfd"       "cd into $HOME/.config/dwm"
  write_command_with_description ".cnfdb"      "cd into $HOME/.config/dwmblocks"
  write_command_with_description ".cnfh"       "cd into $HOME/.config/hypr"
  write_command_with_description ".cnfi"       "cd into $HOME/.config/i3"
  write_command_with_description ".cnfp"       "cd into $HOME/.config/picom"
  write_command_with_description ".cnfn"       "cd into $HOME/.config/nvim"
  write_command_with_description ".cnfw"       "cd into $HOME/.config/wezterm"
  write_command_with_description ".cnfl"       "cd into $HOME/.config/lf"
  write_command_with_description ".cnfr"       "cd into $HOME/.config/ranger"
  write_command_with_description ".cnfs"       "cd into $HOME/.config/st"
  write_command_with_description ".cnfy"       "cd into $HOME/.config/yazi"
  write_command_with_description ".acore"      "cd into acore dir"
  write_command_with_description ".tcore"      "cd into tcore dir"
  write_command_with_description ".wcell"      "cd into wcell dir"
  write_command_with_description ".playermap"  "cd into playermap dir and run"
  write_command_with_description ".cmangos"    "cd into cmangos dir"
  write_command_with_description ".cmangos_tbc"   "cd into cmangos tbc dir"
  write_command_with_description ".vmangos"    "cd into vmangos dir"
  write_command_with_description ".mangoszero" "cd into mangoszero dir"

  printf "\n"
  printf "%bRun / launcher helpers:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".ioq3(2)" "run ioq3 or ioq32"
  write_command_with_description ".openmw"  "run openmw"
  write_command_with_description ".stk"     "run SuperTuxKart (stk)"
  write_command_with_description ".wow"     "run World of Warcraft client"
  write_command_with_description ".wowbot"  "run wowbot"
  write_command_with_description ".llama"   "run llama"
  write_command_with_description ".cava"    "run cava visualizer"
  write_command_with_description ".wc"      "run wow client (wc)"
  write_command_with_description ".openjk"    "run OpenJK"
  write_command_with_description ".openjk_sp" "run OpenJK Jedi Academy singleplayer"
  write_command_with_description ".openjo_sp" "run OpenJK Jedi Outcast singleplayer"
  write_command_with_description ".japp"      "run JA+ (JAPlus)"
  write_command_with_description ".re3"       "run gta 3"
  write_command_with_description ".re3_vice"  "run gta vice city"
  write_command_with_description ".openjkdf2" "run Jedi Knight: Dark Forces II "
  write_command_with_description ".jkg"       "run jedi knight galaxies"
  write_command_with_description ".jk2mv"     "run modernized JK2 client and server"
  write_command_with_description ".unvanq"    "run unvanquished"
  write_command_with_description ".birdgame"  "run bird game"
  write_command_with_description ".fightgame" "run cpp fighting game"
  write_command_with_description ".craft"     "run minecraft in c"
  write_command_with_description ".pacman"    "run pacman"
  write_command_with_description ".space_shooter" "run space shooter"
  write_command_with_description ".devx"      "run devilutionx (dialo)"
  write_command_with_description ".crispy"    "run crispy doom"
  write_command_with_description ".dhewm3"    "run doom3"
  write_command_with_description ".simc"      "run simulationcraft"
  write_command_with_description ".wotlk_sim" "run wowsimwotlk"
  write_command_with_description ".opend2"    "run OpenDiablo2"
  write_command_with_description ".mw"      "my_wow: cd_and_print"
  write_command_with_description ".mww"     "my_web_wow: cd_and_print"
  write_command_with_description ".mwr"     "my_wow: run_with_args.sh with args"

  printf "\n"
  printf "%bListing helpers:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".list_colors"         "print colors"
  write_command_with_description ".list_std_colors"     "print standard colors"
  write_command_with_description ".list_files"          "list largest files recursively (CLI)"
  write_command_with_description ".list_files_gui"      "list largest files recursively via GUI"
  write_command_with_description ".list_p"              "list processes"
  write_command_with_description ".list_pm"             "list processes by memory usage"
  write_command_with_description ".list_mapped_drives"  "list mapped drives"

  printf "\n"
  printf "%bNetwork helpers:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".show_wifi"            "print stored Wi-Fi settings"
  write_command_with_description ".network_devices"      "list network devices"
  write_command_with_description ".network_devices_ping" "ping common network devices"

  printf "\n"
  printf "%bBuild / tools / maintenance:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".cmake"          "helper script for cmake"
  write_command_with_description ".git_push"       "helper script for git push"
  write_command_with_description ".git_pull"       "helper script for git pull"
  write_command_with_description ".git_ignore"     "helper script for git ignore"
  write_command_with_description ".health_check"   "health check script"
  write_command_with_description ".gen_plant"      "generate PlantUML image"
  write_command_with_description ".gen_merm"       "generate Mermaid image"

  write_command_with_description ".acore_update"   "update acore repo"
  write_command_with_description ".tcore_update"   "update tcore repo"
  write_command_with_description ".mangos_update"  "update mangos repo"
  write_command_with_description ".cmangos_update" "update cmangos repo"
  write_command_with_description ".cmangos_tbc_update" "update cmangos tbc repo"
  write_command_with_description ".vmangos_update" "update vmangos repo"
  write_command_with_description ".mangoszero_update" "update mangoszero repo"

  write_command_with_description ".clean_shada"    "clean neovim shada data"
  write_command_with_description ".wow_wtf_update" "copy WoW WTF files into wow_addons repo"
  write_command_with_description ".wow_wtf_fix"    "copy WoW WTF files from wow_addons repo to local WoW dir"
}

show_env_help() {
  printf "%bUseful environment variables:%b\n\n" "$YELLOW" "$RESET"

  printf "%bSystem / machine:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description '$HOSTNAME'        "machine hostname"
  write_command_with_description '$OSTYPE'          "OS type string (e.g. linux-gnu, darwin)"
  write_command_with_description '$MACHTYPE'        "machine type (e.g. x86_64-pc-linux-gnu)"
  write_command_with_description '$HOSTTYPE'        "CPU arch (e.g. x86_64)"

  printf "\n"
  printf "%bUser / profile:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description '$USER'            "current user name"
  write_command_with_description '$HOME'            "user home dir"
  write_command_with_description '$SHELL'           "current shell path"
  write_command_with_description '$LANG'            "locale/language setting"
  write_command_with_description '$TERM'            "terminal type"
  write_command_with_description '$DISPLAY'         "X display (e.g. :0)"

  printf "\n"
  printf "%bShell / process:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description '$PATH'            "executable search paths"
  write_command_with_description '$PWD'             "current working directory"
  write_command_with_description '$OLDPWD'          "previous working directory"
  write_command_with_description '$IFS'             "internal field separator"
  write_command_with_description '$PS1'             "primary shell prompt string"
  write_command_with_description '$EDITOR'          "default text editor"
  write_command_with_description '$VISUAL'          "default visual editor"
  write_command_with_description '$PAGER'           "default pager (e.g. less)"
  write_command_with_description '$MANPATH'         "man page search paths"
  write_command_with_description '$TMPDIR / $TMP'   "temp directory"
  write_command_with_description '$$'               "PID of current shell"
  write_command_with_description '$?'               "exit code of last command"
  write_command_with_description '$!'               "PID of last background command"
  write_command_with_description '$0'               "name of current script/shell"

  printf "\n"
  printf "%bSystem info commands:%b\n" "$DARKGRAY" "$RESET"
  write_code_line "nproc                              # CPU thread count"
  write_code_line "nproc --all                        # total logical CPUs (incl. offline)"
  write_code_line "uname -a                           # full system info"
  write_code_line "uname -r                           # kernel version"
  write_code_line "uname -m                           # machine hardware (e.g. x86_64)"
  write_code_line "uname -s                           # OS name (e.g. Linux)"
  write_code_line "uname -n                           # network hostname"
  write_code_line "lscpu                              # detailed CPU info"
  write_code_line "lscpu | grep 'CPU(s)'              # CPU count lines"
  write_code_line "lsmem                              # memory info"
  write_code_line "free -h                            # RAM usage (human-readable)"
  write_code_line "df -h                              # disk usage (human-readable)"
  write_code_line "lsblk                              # block devices"
  write_code_line "lspci                              # PCI devices (GPU, etc.)"
  write_code_line "lsusb                              # USB devices"
  write_code_line "cat /etc/os-release                # distro info"
  write_code_line "cat /proc/cpuinfo                  # raw CPU info"
  write_code_line "cat /proc/meminfo                  # raw memory info"
  write_code_line "uptime                             # system uptime and load"
  write_code_line "who                                # logged in users"
  write_code_line "id                                 # current user/group IDs"

  printf "\n"
  printf "%bPrint / inspect variables:%b\n" "$DARKGRAY" "$RESET"
  write_code_line 'echo "$HOME"                       # print a variable'
  write_code_line 'printenv                           # list all env vars'
  write_code_line 'printenv HOME                      # print specific var'
  write_code_line 'printenv | sort                    # sorted list'
  write_code_line 'printenv | grep -i path            # filter by keyword'
  write_code_line 'env                                # same as printenv'
  write_code_line 'declare -p                         # all shell vars + attrs'
}

show_other_help() {
  printf "%bOther useful commands:%b\n\n" "$YELLOW" "$RESET"
  write_code_line "keepawake"
  write_code_line 'vim "$code_root_dir/Code2/Wow/tools/my_wow/wow.conf"'
  write_code_line 'cd "$my_notes_path" && ./check_dirs.sh'
  write_code_line "pwd | xclip -selection clipboard"

  printf "\n"
  printf "%bBash file/directory operations:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bList only directories:%b\n" "$YELLOW" "$RESET"
  write_code_line "ls -d */                   # simple way"
  write_code_line "ls -l | grep \"^d\"          # using ls -l and grep"
  write_code_line "find . -maxdepth 1 -type d # using find"

  printf "\n"
  printf "%bList only files:%b\n" "$YELLOW" "$RESET"
  write_code_line "ls -p | grep -v /          # exclude dirs (those ending in /)"
  write_code_line "find . -maxdepth 1 -type f # using find"

  printf "\n"
  printf "%bFilter by keyword:%b\n" "$YELLOW" "$RESET"
  write_code_line "ls | grep keyword           # case-sensitive (default)"
  write_code_line "ls -la | grep keyword       # include hidden files and more info"
  write_code_line "ls | grep -i keyword        # case-insensitive"

  printf "\n"
  printf "%bView file content:%b\n" "$YELLOW" "$RESET"
  write_code_line "head file.txt               # first 10 lines (default)"
  write_code_line "head -n 20 file.txt         # first N lines"
  write_code_line "tail file.txt               # last 10 lines (default)"
  write_code_line "tail -n 10 file.txt         # last N lines (explicit)"

  printf "\n"
  printf "%bCount items (current dir only):%b\n" "$YELLOW" "$RESET"
  write_code_line "find . -maxdepth 1 -type f | wc -l  # count files"
  write_code_line "find . -maxdepth 1 -type d | wc -l  # count directories"
  write_code_line "ls -1 | wc -l                       # count all items"
  printf "%bCount items (recursive):%b\n" "$YELLOW" "$RESET"
  write_code_line "find . -type f | wc -l              # count all files recursively"
  write_code_line "find . -type d | wc -l              # count all directories recursively"
  write_code_line "find . | wc -l                      # count everything recursively"
}

show_paths_help() {
  printf "%bCommon config paths:%b\n\n" "$YELLOW" "$RESET"

  printf "%bnvim config path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.config/nvim/init.lua%b\n\n" "$GREEN" "$RESET"

  printf "%bnvim data dir (stdpath(\"data\")):%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.local/share/nvim%b\n\n" "$GREEN" "$RESET"

  printf "%blazy.nvim plugin location:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.local/share/nvim/lazy%b\n\n" "$GREEN" "$RESET"

  printf "%bnvim built-in package manager path (0.12+):%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.local/share/nvim/site/pack%b\n\n" "$GREEN" "$RESET"

  printf "%bwezterm config path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.wezterm.lua%b\n\n" "$GREEN" "$RESET"

  printf "%bwezterm session manager path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.config/wezterm/wezterm-session-manager/session-manager.lua%b\n\n" "$GREEN" "$RESET"

  printf "%balacritty config path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.config/alacritty/alacritty.toml%b\n\n" "$GREEN" "$RESET"

  printf "%blf config path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.config/lf/lfrc%b\n\n" "$GREEN" "$RESET"

  printf "%byazi config path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.config/yazi/keymap.toml%b\n\n" "$GREEN" "$RESET"

  printf "%bvs code config path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.config/Code/User/keybindings.json%b\n\n" "$GREEN" "$RESET"

  printf "%bvimrc path:%b\n" "$DARKGRAY" "$RESET"
  printf "%b~/.vimrc%b\n" "$GREEN" "$RESET"
}

show_grep_help() {
  printf "## grep\n\n"

  printf "Basic Recursive Search\n"
  write_code_line 'grep -r "your_search_text" .'
  printf "\n"

  printf "Non-Recursive Search\n"
  write_code_line 'grep "your_search_text" *'
  printf "\n"

  printf "Search Only in Files with Specific Extensions\n"
  write_code_line 'grep -r --include="*.txt" "your_search_text" .'
  printf "Use --include to include only .txt files.\n\n"

  printf "Multiple extensions:\n"
  write_code_line 'grep -r --include="*.txt" --include="*.md" "your_search_text" .'
  printf "\n"

  printf "Exclude Specific File Extensions\n"
  write_code_line 'grep -r --exclude="*.log" "your_search_text" .'
  printf "\n"

  printf "Exclude multiple:\n"
  write_code_line 'grep -r --exclude="*.log" --exclude="*.tmp" "your_search_text" .'
  printf "\n"

  printf "Combine Include and Exclude\n"
  printf "Only .cs files but exclude .Designer.cs ones:\n"
  write_code_line 'grep -r --include="*.cs" --exclude="*.Designer.cs" "your_search_text" .'
  printf "\n"

  printf "Search in a Specific Directory\n"
  write_code_line 'grep -r "your_search_text" path/to/directory'
  printf "\n"

  printf "Show Only File Names with Matches\n"
  write_code_line 'grep -rl "your_search_text" .'
  printf "\n"

  printf "Show Line Numbers\n"
  write_code_line 'grep -rn "your_search_text" .'
  printf "\n"

  printf "Case-Insensitive Search\n"
  write_code_line 'grep -ri "your_search_text" .'
  printf "\n"

  printf "Literal Search (no regex)\n"
  write_code_line 'grep -rF "literal_text" .'

  printf "\n"
  printf "Recursive + case-insensitive, excluding common build dirs\n"
  write_code_line 'grep -rIn --exclude-dir={build,out,node_modules,.git,bin} "your_search_text" .'
  printf "\n"

  printf "CMake: only CMakeLists.txt\n"
  printf "Original:\n"
  write_code_line 'grep -R --line-number --with-filename "your_search_text" --include="CMakeLists.txt" .'
  printf "Shortened:\n"
  write_code_line 'grep -RIn --include="CMakeLists.txt" "your_search_text" .'
  printf "\n"

  printf "CMake: only *.cmake\n"
  printf "Original:\n"
  write_code_line 'grep -R -n "your_search_text" --include="*.cmake" .'
  printf "Shortened:\n"
  write_code_line 'grep -Rn --include="*.cmake" your_search_text .'
  printf "\n"

  printf "CMake: CMakeLists.txt + *.cmake\n"
  printf "Original:\n"
  write_code_line 'grep -R -n "your_search_text" --include="CMakeLists.txt" --include="*.cmake" .'
  printf "Shortened:\n"
  write_code_line 'grep -Rn --include="CMakeLists.txt" --include="*.cmake" your_search_text .'
  printf "\n"

  printf "CMake-ish filenames: name contains \"cmake\" but NOT ending with .cmake\n"
  printf "Grep (simple):\n"
  write_code_line 'grep -Rn --include="*cmake*" --exclude="*.cmake" "your_search_text" .'
  printf "Find + grep (case-insensitive filename match):\n"
  write_code_line 'find . -type f -iname "*cmake*" ! -iname "*.cmake" -exec grep -n "your_search_text" {} +'
  printf "\n"

  printf "Context search -> save to temp file -> second grep on output -> delete temp file\n"
  write_code_line 'tmp="$(mktemp)" && grep -rIn -C 3 "FIRST" . >"$tmp" && grep -i "SECOND" "$tmp" && rm -f "$tmp"'
  printf "\n"
}

show_gitgrep_help() {
  printf "## git grep\n\n"

  printf "Basic Recursive Search\n"
  write_code_line 'git grep "your_search_text"'
  printf "\n"

  printf "Non-Recursive Search\n"
  write_code_line 'git grep "your_search_text" -- "./*"'
  printf "\n"

  printf "Search Only in Files with Specific Extensions\n"
  write_code_line 'git grep "your_search_text" -- "*.txt"'
  printf "\n"

  printf "Multiple extensions:\n"
  write_code_line 'git grep "your_search_text" -- "*.txt" "*.md"'
  printf "\n"

  printf "Exclude Specific File Extensions\n"
  write_code_line 'git grep "your_search_text" -- ":!*.log"'
  printf "\n"

  printf "Exclude multiple:\n"
  write_code_line 'git grep "your_search_text" -- ":!*.log" ":!*.tmp"'
  printf "\n"

  printf "Combine Include and Exclude\n"
  printf "Only .cs files but exclude .Designer.cs ones:\n"
  write_code_line 'git grep "your_search_text" -- "*.cs" ":!*.Designer.cs"'
  printf "\n"

  printf "Search in a Specific Directory\n"
  write_code_line 'git grep "your_search_text" -- path/to/directory'
  printf "\n"

  printf "Show Only File Names with Matches\n"
  write_code_line 'git grep -l "your_search_text"'
  printf "\n"

  printf "Show Line Numbers\n"
  write_code_line 'git grep -n "your_search_text"'
  printf "\n"

  printf "Case-Insensitive Search\n"
  write_code_line 'git grep -i "your_search_text"'
  printf "\n"

  printf "Literal Search (no regex)\n"
  write_code_line 'git grep -F "literal_text"'

  printf "\n"
  printf "Recursive + case-insensitive, excluding common build dirs\n"
  write_code_line 'git grep -i "your_search_text" -- ":(exclude)build/**" ":(exclude)out/**" ":(exclude)node_modules/**" ":(exclude).git/**" ":(exclude)bin/**"'
  printf "\n"

  printf "CMake: only CMakeLists.txt\n"
  write_code_line 'git grep "your_search_text" -- "CMakeLists.txt"'
  printf "\n"

  printf "CMake: only *.cmake\n"
  write_code_line 'git grep "your_search_text" -- "*.cmake"'
  printf "\n"

  printf "CMake: CMakeLists.txt + *.cmake\n"
  write_code_line 'git grep "your_search_text" -- "CMakeLists.txt" "*.cmake"'
  printf "\n"

  printf "CMake-ish filenames: name contains \"cmake\" but NOT ending with .cmake\n"
  write_code_line 'git grep "your_search_text" -- "*cmake*" ":(exclude)*.cmake"'
  printf "CMake-ish filenames (case-insensitive path match):\n"
  write_code_line 'git grep "your_search_text" -- ":(icase)*cmake*" ":(exclude)*.cmake"'
  printf "\n"

  printf "Context search -> save to temp file -> second grep on output -> delete temp file\n"
  write_code_line 'tmp="$(mktemp)" && git grep -in -C 3 "FIRST" -- . >"$tmp" && grep -i "SECOND" "$tmp" && rm -f "$tmp"'
  printf "\n"
}

show_ripgrep_help() {
  printf "## ripgrep\n\n"

  printf "Basic Recursive Search\n"
  write_code_line 'rg "your_search_text"'
  printf "\n"

  printf "Non-Recursive Search\n"
  write_code_line 'rg --max-depth 1 "your_search_text"'
  printf "\n"

  printf "Search Only in Files with Specific Extensions\n"
  write_code_line 'rg "your_search_text" -g "*.txt"'
  printf "Use -g (glob) to include only .txt files.\n\n"

  printf "Multiple extensions:\n"
  write_code_line 'rg "your_search_text" -g "*.txt" -g "*.md"'
  printf "You can add multiple -g filters.\n\n"

  printf "Exclude Specific File Extensions\n"
  write_code_line 'rg "your_search_text" -g "!*.log"'
  printf "The ! negates the glob, so it excludes .log files.\n\n"

  printf "Exclude multiple:\n"
  write_code_line 'rg "your_search_text" -g "!*.log" -g "!*.tmp"'
  printf "\n"

  printf "Combine Include and Exclude\n"
  printf "Only .cs files but exclude .Designer.cs ones:\n"
  write_code_line 'rg "your_search_text" -g "*.cs" -g "!*.Designer.cs"'
  printf "\n"

  printf "Search in a Specific Directory\n"
  write_code_line 'rg "your_search_text" path/to/directory'
  printf "\n"

  printf "Show Only File Names with Matches\n"
  write_code_line 'rg -l "your_search_text"'
  printf "\n"

  printf "Show Line Numbers\n"
  write_code_line 'rg -n "your_search_text"'
  printf "\n"

  printf "Case-Insensitive Search\n"
  write_code_line 'rg -i "your_search_text"'
  printf "\n"

  printf "Literal Search (no regex)\n"
  write_code_line 'rg -F "literal_text"'

  printf "\n"
  printf "Recursive + case-insensitive, excluding common build dirs\n"
  write_code_line 'rg -i "your_search_text" -g "!build/**" -g "!out/**" -g "!node_modules/**" -g "!.git/**" -g "!bin/**"'
  printf "\n"

  printf "CMake: only CMakeLists.txt\n"
  write_code_line 'rg "your_search_text" -g "CMakeLists.txt"'
  printf "\n"

  printf "CMake: only *.cmake\n"
  write_code_line 'rg "your_search_text" -g "*.cmake"'
  printf "\n"

  printf "CMake: CMakeLists.txt + *.cmake\n"
  write_code_line 'rg "your_search_text" -g "CMakeLists.txt" -g "*.cmake"'
  printf "\n"

  printf "CMake-ish filenames: name contains \"cmake\" but NOT ending with .cmake\n"
  write_code_line 'rg "your_search_text" -g "*cmake*" -g "!*.cmake"'
  printf "CMake-ish filenames (case-insensitive filename glob):\n"
  write_code_line 'rg "your_search_text" --iglob "*cmake*" --iglob "!*.cmake"'
  printf "\n"

  printf "Context search -> save to temp file -> second grep on output -> delete temp file\n"
  write_code_line 'tmp="$(mktemp)" && rg -in -C 3 "FIRST" . >"$tmp" && grep -i "SECOND" "$tmp" && rm -f "$tmp"'
  printf "\n"
}

# language helps

show_c_help() {
  printf "\n"
  printf "%bC / gcc quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "gcc --version"
  write_code_line "gcc --help"

  printf "\n"
  printf "%bCompile & run:%b\n" "$YELLOW" "$RESET"
  write_code_line "gcc -Wall -Wextra -pedantic -std=c17 -o main main.c  # Compile C program"
  write_code_line "./main  # Run binary"
  printf "\n"
  write_code_line "gcc -g -O0 -Wall -Wextra -std=c17 -o main_debug main.c  # Debug build"
}

show_csharp_help() {
  printf "\n"
  printf "%bC# / .NET quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "dotnet --version"
  write_code_line "dotnet -h"

  printf "\n"
  printf "%bCreate new projects:%b\n" "$YELLOW" "$RESET"
  write_code_line "dotnet new console -o MyConsoleApp      # Console app"
  write_code_line "dotnet new classlib -o MyLibrary        # Class library"
  write_code_line "dotnet new webapi -o MyWebApi           # ASP.NET Core Web API"
  write_code_line "dotnet new worker -o MyWorkerService    # Background worker service"

  printf "\n"
  printf "%bUseful dotnet commands:%b\n" "$YELLOW" "$RESET"
  write_code_line "dotnet --list-runtimes"
  write_code_line "dotnet --list-sdks"
  write_code_line "dotnet build"
  write_code_line "dotnet build -c Release"
  write_code_line "# Errors only, no warnings/analyzers"
  write_code_line "dotnet build -consoleLoggerParameters:ErrorsOnly -p:WarningLevel=0 -p:RunAnalyzersDuringBuild=false"
  write_code_line "dotnet run -c Release"
  write_code_line "dotnet run --framework net9.0"
  write_code_line "dotnet run -f net7.0"
  write_code_line "dotnet run &> test.txt           # Run and capture output to test.txt"
  write_code_line "dotnet test                      # Run tests (from solution dir)"

  printf "\n"
  printf "%bAdd NuGet packages:%b\n" "$YELLOW" "$RESET"
  write_code_line "dotnet add package Newtonsoft.Json                   # Add latest"
  write_code_line "dotnet add package Newtonsoft.Json --version 13.0.3  # Add specific version"
  write_code_line "dotnet add package Dapper                        # Example: Dapper (latest)"
  write_code_line "dotnet add package Serilog --version 3.1.1       # Example: Serilog (pinned)"
  write_code_line "dotnet list package                              # List installed packages"
  write_code_line "dotnet remove package Newtonsoft.Json            # Remove a package"
}

show_cpp_help() {
  printf "\n"
  printf "%bC++ / g++ quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "g++ --version"
  write_code_line "g++ --help"

  printf "\n"
  printf "%bCompile & run:%b\n" "$YELLOW" "$RESET"
  write_code_line "g++ -O2 -Wall -Wextra -std=c++20 -o main main.cpp  # Compile optimized"
  write_code_line "./main  # Run binary"
  printf "\n"
  write_code_line "g++ -g -O0 -Wall -Wextra -std=c++20 -o main_debug main.cpp  # Debug build"
}

show_rust_help() {
  printf "\n"
  printf "%bRust / cargo quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "rustc --version"
  write_code_line "cargo --version"
  write_code_line "cargo -h"

  printf "\n"
  printf "%bBasic usage:%b\n" "$YELLOW" "$RESET"
  write_code_line "cargo new TestProject               # Create new project"
  write_code_line "cd TestProject"
  write_code_line "cargo build                         # Build debug"
  write_code_line "cargo run                           # Run debug build"

  printf "\n"
  printf "%bWith logs redirected to test.txt:%b\n" "$YELLOW" "$RESET"
  write_code_line "cargo build &> test.txt             # Build and capture output"
  write_code_line "cargo run &> test.txt               # Run and capture output"
  write_code_line "cargo run --release &> test.txt     # Release run and capture output"

  printf "\n"
  printf "%bBacktraces:%b\n" "$YELLOW" "$RESET"
  write_code_line "RUST_BACKTRACE=1 cargo run          # Short backtrace"
  write_code_line "RUST_BACKTRACE=full cargo run       # Full backtrace"

  printf "\n"
  printf "%bUsage with args (dt flag):%b\n" "$YELLOW" "$RESET"
  write_code_line "cargo run --                        # default dt ON"
  write_code_line "cargo run -- --use-dt               # explicit ON"
  write_code_line "cargo run -- --no-use-dt            # OFF"
  write_code_line "cargo run -- --use-dt=false         # OFF"

  printf "\n"
  write_code_line 'export RUSTFLAGS="-Awarnings"         # Allow/suppress all Rust compiler warnings'

  printf "\n"
  printf "%bAdd / remove packages (crates):%b\n" "$YELLOW" "$RESET"
  write_code_line "cargo add serde                                 # Add latest"
  write_code_line "cargo add serde@1.0.197                         # Add specific version"
  write_code_line "cargo add serde --features derive               # Add with features"
  write_code_line "cargo add tokio --features full                 # Example: tokio (latest, all features)"
  write_code_line "cargo add anyhow@1.0.86                         # Example: anyhow (pinned)"
  write_code_line "cargo remove serde                              # Remove a crate"
}

show_java_help() {
  printf "\n"
  printf "%bJava quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "java -version"
  write_code_line "javac -version"
  write_code_line "java -h"

  printf "\n"
  printf "%bCompile & run:%b\n" "$YELLOW" "$RESET"
  write_code_line "javac Main.java                     # Compile"
  write_code_line "java Main                           # Run"
  printf "\n"
  write_code_line "javac -d out src/Main.java          # Compile into 'out' directory"
  write_code_line "java -cp out Main                   # Run with explicit classpath"

  printf "\n"
  printf "%bAdd packages (Maven):%b\n" "$YELLOW" "$RESET"
  write_code_line "mvn dependency:get -Dartifact=com.google.gson:gson:LATEST  # Fetch latest"
  write_code_line "mvn dependency:get -Dartifact=com.google.gson:gson:2.10.1  # Fetch specific version"
  printf "%b  Or add directly to pom.xml <dependencies>:%b\n" "$DARKGRAY" "$RESET"
  write_code_line "  <dependency>"
  write_code_line "    <groupId>com.google.gson</groupId>"
  write_code_line "    <artifactId>gson</artifactId>"
  write_code_line "    <version>2.10.1</version>"
  write_code_line "  </dependency>"
  printf "\n"
  printf "%bAdd packages (Gradle):%b\n" "$YELLOW" "$RESET"
  printf "%b  Add to build.gradle dependencies {}:%b\n" "$DARKGRAY" "$RESET"
  write_code_line "  implementation 'com.google.gson:gson:+'        # Latest"
  write_code_line "  implementation 'com.google.gson:gson:2.10.1'   # Specific version"
  write_code_line "mvn install                                      # Resolve + build (Maven)"
  write_code_line "gradle build                                     # Resolve + build (Gradle)"
}

show_python_help() {
  printf "\n"
  printf "%bPython quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "python --version"
  write_code_line "python -h"

  printf "\n"
  printf "%bBasic usage:%b\n" "$YELLOW" "$RESET"
  write_code_line "python main.py                      # Run script"
  write_code_line "python -m venv .venv                # Create virtual environment"
  write_code_line "source .venv/bin/activate           # Activate venv (Linux/macOS)"
  write_code_line "source .venv/Scripts/activate       # Activate venv (Windows bash/WSL)"
  printf "\n"
  write_code_line "python -m pip install -r requirements.txt  # Install dependencies"
  write_code_line "python ./main.py &> test.txt        # Run and capture output to test.txt"

  printf "\n"
  printf "%bAdd / remove packages:%b\n" "$YELLOW" "$RESET"
  write_code_line "pip install requests                            # Add latest"
  write_code_line "pip install requests==2.31.0                    # Add specific version"
  write_code_line "pip install 'requests>=2.28,<3.0'               # Add with version range"
  write_code_line "pip install flask numpy pandas                  # Install multiple at once"
  write_code_line "pip install --upgrade requests                  # Upgrade a package"
  write_code_line "pip uninstall requests                          # Remove a package"
  write_code_line "pip freeze > requirements.txt                   # Save installed packages"
}

show_go_help() {
  printf "\n"
  printf "%bGo quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "go version"
  write_code_line "go help"
  write_code_line "go help <command>                   # e.g. go help build"

  printf "\n"
  printf "%bBasic usage:%b\n" "$YELLOW" "$RESET"
  write_code_line "go mod init example.com/myapp       # Initialize module"
  write_code_line "go run main.go                      # Run directly"
  write_code_line "go build ./...                      # Build all packages"
  write_code_line "go test ./...                       # Run tests"

  printf "\n"
  printf "%bWith output redirected to test.txt:%b\n" "$YELLOW" "$RESET"
  write_code_line "go build; ./my_wow &> test.txt"
  write_code_line "go build; ./my_wow &> test.txt; vim ./test.txt"

  printf "\n"
  printf "%bAdd / remove packages:%b\n" "$YELLOW" "$RESET"
  write_code_line "go get github.com/some/package@latest          # Add latest version"
  write_code_line "go get github.com/some/package@v1.2.3          # Add specific version"
  write_code_line "go get github.com/ebitengine/purego@latest"
  write_code_line "go get github.com/ebitengine/purego@v0.8.2"
  write_code_line "go get github.com/some/package@none            # Remove a package"
  write_code_line "go mod tidy                                    # Clean up go.mod / go.sum (removes unused deps)"
}

show_js_help() {
  printf "\n"
  printf "%bJavaScript (Node) quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "node --version"
  write_code_line "node --help"
  write_code_line "npm -v"
  write_code_line "npm help"

  printf "\n"
  printf "%bDo this:%b\n" "$YELLOW" "$RESET"
  write_code_line "node main.js"
  printf "%bOr:%b\n" "$YELLOW" "$RESET"
  write_code_line "npm init -y"
  printf "%b# fix package.json (add \"start\" script, etc.)%b\n" "$DARKGRAY" "$RESET"
  printf "%bThen:%b\n" "$YELLOW" "$RESET"
  write_code_line "npm run start"
  write_code_line "npm start"

  printf "\n"
  printf "%bAdd / remove packages:%b\n" "$YELLOW" "$RESET"
  write_code_line "npm install some-package                       # Add latest"
  write_code_line "npm install some-package@1.2.3                 # Add specific version"
  write_code_line "npm install --save-dev some-package            # Add as dev dependency"
  write_code_line "npm install --save-dev some-package@1.2.3      # Dev dep, specific version"
  write_code_line "npm install axios                              # Example: axios (latest)"
  write_code_line "npm install axios@1.6.0                        # Example: axios (pinned)"
  write_code_line "npm uninstall some-package                     # Remove a package"
  write_code_line "npm uninstall --save-dev some-package          # Remove a dev dependency"
}

show_ts_help() {
  printf "\n"
  printf "%bTypeScript quick examples:%b\n" "$YELLOW" "$RESET"

  printf "\n"
  printf "%bVersion / help:%b\n" "$YELLOW" "$RESET"
  write_code_line "tsc -v"
  write_code_line "npx tsc --help"

  printf "\n"
  printf "%bDo this:%b\n" "$YELLOW" "$RESET"
  write_code_line "npm init -y                         # init npm"
  write_code_line "npm install --save-dev typescript ts-node @types/node  # install dev dependencies"
  write_code_line "npx tsc --init                      # Create tsconfig.json"
  printf "%b# tweak tsconfig.json and npm scripts, then do either of these:%b\n" "$DARKGRAY" "$RESET"
  printf "%b# Compile once + run compiled JS:%b\n" "$DARKGRAY" "$RESET"
  write_code_line "npm run build  # runs tsc -> creates dist/main.js, dist/config_reader.js"
  write_code_line "npm start      # runs node dist/main.js (via package.json script)"
  printf "%b# Dev mode (no separate build step):%b\n" "$DARKGRAY" "$RESET"
  write_code_line "npm run dev"

  printf "\n"
  printf "%bAdd / remove packages:%b\n" "$YELLOW" "$RESET"
  write_code_line "npm install some-package                          # Add latest"
  write_code_line "npm install some-package@1.2.3                    # Add specific version"
  write_code_line "npm install --save-dev @types/some-package        # Add type definitions"
  write_code_line "npm install --save-dev @types/some-package@1.2.3  # Pinned type definitions"
  write_code_line "npm install axios                                 # Example: axios (latest)"
  write_code_line "npm install --save-dev @types/node@20.0.0         # Example: pinned @types/node"
  write_code_line "npm uninstall some-package                        # Remove a package"
  write_code_line "npm uninstall --save-dev @types/some-package      # Remove type definitions"
}

# Main

# No arg -> print ONLY available args
if [[ -z "$arg" ]]; then
  show_usage
  exit 0
fi

key="${arg,,}"  # to lower-case (bash 4+)
if [[ -z "${ARG_MAP[$key]+x}" ]]; then
  # Unknown arg -> print ONLY available args (no extra text)
  show_usage
  exit 0
fi

mode="${ARG_MAP[$key]}"

printf "%bSelected: %s%b\n\n" "$MAGENTA" "$mode" "$RESET"

case "$mode" in
  # Languages
  c)           show_c_help ;;
  csharp)      show_csharp_help ;;
  cpp)         show_cpp_help ;;
  rust)        show_rust_help ;;
  java)        show_java_help ;;
  python)      show_python_help ;;
  go)          show_go_help ;;
  javascript)  show_js_help ;;
  typescript)  show_ts_help ;;

  # Other modes
  git)         show_git_help ;;
  grep)        show_grep_help ;;
  gitgrep)     show_gitgrep_help ;;
  ripgrep)     show_ripgrep_help ;;
  scripts)     show_scripts_help ;;
  env)         show_env_help ;;
  other)       show_other_help ;;
  paths)       show_paths_help ;;
esac

