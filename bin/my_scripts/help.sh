#!/usr/bin/env bash

language="$1"

# Colors (ANSI escape codes)
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'

# Language alias map
declare -A LANGUAGE_MAP=(
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
  printf "Available code language arguments (case-insensitive):\n"

  local langs=(
    "c"
    "cs / c# / csharp"
    "cpp / c++"
    "go / golang"
    "java"
    "js / javascript"
    "ts / typescript"
    "py / python"
    "rust / rs"
  )

  for lang in "${langs[@]}"; do
    printf "  %b%s%b\n" "$MAGENTA" "$lang" "$RESET"
  done

  printf "\n"
  printf "Some useful dot commands:\n"

  printf "%b  Navigation / cd helpers:%b\n" "$DARKGRAY" "$RESET"
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
  printf "%b  Run / launcher helpers:%b\n" "$DARKGRAY" "$RESET"
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
  printf "%b  Listing helpers:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".list_colors"         "print colors"
  write_command_with_description ".list_std_colors"     "print standard colors"
  write_command_with_description ".list_files"          "list largest files recursively (CLI)"
  write_command_with_description ".list_files_gui"      "list largest files recursively via GUI"
  write_command_with_description ".list_p"              "list processes"
  write_command_with_description ".list_pm"             "list processes by memory usage"
  write_command_with_description ".list_mapped_drives"  "list mapped drives"

  printf "\n"
  printf "%b  Network helpers:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".show_wifi"            "print stored Wi-Fi settings"
  write_command_with_description ".network_devices"      "list network devices"
  write_command_with_description ".network_devices_ping" "ping common network devices"

  printf "\n"
  printf "%b  Build / tools / maintenance:%b\n" "$DARKGRAY" "$RESET"
  write_command_with_description ".cmake"          "helper script for cmake"
  write_command_with_description ".git_push"       "helper script for git push"
  write_command_with_description ".git_pull"       "helper script for git pull"
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

  printf "\n"
  printf "Useful git commands:\n\n"

  printf "%b# Display history with graph and decorate:%b\n" "$DARKGRAY" "$RESET"
  printf "%bgit log --graph --decorate%b\n" "$BLUE" "$RESET"

  printf "%b# Generate diff showing changes from latest commit:%b\n" "$DARKGRAY" "$RESET"
  printf "%bgit show HEAD > latest_changes.diff%b\n" "$BLUE" "$RESET"

  printf "%b# Generate diff showing changes from second latest commit (use HEAD^^ for third etc.):%b\n" "$DARKGRAY" "$RESET"
  printf "%bgit show HEAD^ > latest_changes.diff%b\n" "$BLUE" "$RESET"

  printf "%b# Generate diff for specified commit id, filtering on specific file type:%b\n" "$DARKGRAY" "$RESET"
  printf "%bgit show c7aa908 -- '*.go' > go_fixes.diff%b\n" "$BLUE" "$RESET"

  printf "%b# Generate diff between specific commit and now, filtering on specific file types:%b\n" "$DARKGRAY" "$RESET"
  printf "%bgit diff cbceb5a..HEAD -- '**/*.java' '*.cs' > new_java_cs_changes.diff%b\n" "$BLUE" "$RESET"

  printf "%b# Apply patch:%b\n" "$DARKGRAY" "$RESET"
  printf "%bcd \"\$code_root_dir/Code2/C#/dotnet-integration\" && git apply \$my_notes_path/notes/svea/diffs/testshop_dev.diff --verbose%b\n" "$BLUE" "$RESET"

  printf "\n"
  printf "Other useful commands:\n\n"

  printf "%b  keepawake%b\n" "$GREEN" "$RESET"
  printf "%b  vim \"\$code_root_dir/Code2/Wow/tools/my_wow/wow.conf\"%b\n" "$GREEN" "$RESET"
  printf "%b  cd \"\$my_notes_path\"; ./check_dirs.sh%b\n" "$GREEN" "$RESET"
}

# Language-specific helpers
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
  write_code_line "dotnet run --framework net9.0"
  write_code_line "dotnet run -f net7.0"
  write_code_line "dotnet run &> test.txt           # Run and capture output to test.txt"
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
  printf "\n"
  printf "%bOr:%b\n" "$YELLOW" "$RESET"
  write_code_line "npm init -y"
  printf "%b# fix package.json (add \"start\" script, etc.)%b\n" "$DARKGRAY" "$RESET"
  printf "%bThen:%b\n" "$YELLOW" "$RESET"
  write_code_line "npm run start"
  write_code_line "npm start"
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
}

# Main

if [[ -z "$language" ]]; then
  show_usage
  exit 0
fi

key="${language,,}"  # to lower-case (bash 4+)
if [[ -z "${LANGUAGE_MAP[$key]+x}" ]]; then
  printf "%bUnknown code language argument: '%s'%b\n" "$RED" "$language" "$RESET"
  printf "\n"
  show_usage
  exit 1
fi

normalized_language="${LANGUAGE_MAP[$key]}"

printf "Selected code language: "
printf "%b%s%b\n" "$MAGENTA" "$normalized_language" "$RESET"

case "$normalized_language" in
  c)           show_c_help ;;
  csharp)      show_csharp_help ;;
  cpp)         show_cpp_help ;;
  rust)        show_rust_help ;;
  java)        show_java_help ;;
  python)      show_python_help ;;
  go)          show_go_help ;;
  javascript)  show_js_help ;;
  typescript)  show_ts_help ;;
  *)           ;;  # shouldn't happen
esac

