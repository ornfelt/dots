#!/usr/bin/env bash

# This script prints relevant build commands based on cwd
# see:
# {my_notes_path}/scripts/build_script_desc.txt

cwd_full="$(pwd)"
cwd="${cwd_full,,}"   # lowercase for case-insensitive matching

# Colors (ANSI escape codes)
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'
DARKYELLOW='\033[93m'
BOLD='\033[1m'

# Helpers
write_label()  { echo -e "  ${DARKGRAY}$1${RESET}"; }
write_cmd()    { echo -e "  ${CYAN}$1${RESET}"; }
write_alt()    { echo -e "  ${MAGENTA}$1${RESET}"; }
write_extra()  { echo -e "  ${BLUE}$1${RESET}"; }
write_warn()   { echo -e "${DARKYELLOW}$1${RESET}"; }
write_header() {
    echo ""
    echo -e "  ${BOLD}=== $1 ===${RESET}"
    echo ""
}

# Check that keywords appear in the path in the given order (case-insensitive).
# cwd is already lowercased, so we only need to lowercase the keywords.
path_contains_in_order() {
    local pos=0
    local kw kw_lower sub prefix
    for kw in "$@"; do
        kw_lower="${kw,,}"
        sub="${cwd:$pos}"
        if [[ "$sub" != *"$kw_lower"* ]]; then
            return 1
        fi
        prefix="${sub%%"$kw_lower"*}"
        pos=$((pos + ${#prefix} + ${#kw_lower}))
    done
    return 0
}

# Match rules
matched=0

# code2 -> go -> my_web_wow
if path_contains_in_order code2 go my_web_wow; then
    write_header "Go (my_web_wow)"
    write_label  "use this:"
    write_cmd    "go build -tags async"
    write_label  "or:"
    write_cmd    'go build -tags "async cimgui"'
    write_label  "or:"
    write_cmd    "go build -tags with_performance"
    write_label  "or:"
    write_cmd    'go build -tags "async with_performance"'
    write_label  "or:"
    write_cmd    'go build -tags "async cimgui with_performance"'
    write_label  "or:"
    write_cmd    "go build"
    write_label  "or:"
    write_alt    "go run ."
    write_label  "or:"
    write_alt    "./build.sh"
    write_label  "or:"
    write_cmd    "rm my_web_wow; go build -tags async; ./my_web_wow"
    matched=1

# code2 -> go -> tbc
elif path_contains_in_order code2 go tbc; then
    write_header "Go (tbc)"
    write_label  "use this:"
    write_cmd    "go build"
    write_label  "or:"
    write_cmd    'go build; ./my_wow *> test.txt'
    write_label  "or:"
    write_alt    "go run ."
    matched=1

# code2 -> rust -> my_web_wow
elif path_contains_in_order code2 rust my_web_wow; then
    write_header "Rust (my_web_wow)"
    write_cmd    "cargo build --features use_async"
    write_cmd    "cargo build --features with_performance"
    write_cmd    "cargo build"
    echo ""
    write_cmd    "cargo run"
    write_cmd    "cargo run --features use_async"
    write_cmd    "cargo run --features with_imgui"
    write_cmd    "cargo run --features with_performance"
    write_cmd    'cargo run --features "with_imgui use_async"'
    write_cmd    'cargo run --features "with_imgui use_async with_performance"'
    write_alt    "cargo run --release"
    write_extra  'cargo run --release *> test.txt'
    echo ""
    write_label  "override expansion (default from server/env):"
    write_cmd    "cargo run --features with_imgui -- --expansion tbc"
    echo ""
    write_label  "specific map key (default expansion):"
    write_cmd    "cargo run -- --map orgrimmar"
    write_cmd    "cargo run -- --map ragnaros"
    echo ""
    write_label  "both map and expansion:"
    write_cmd    "cargo run -- --map dragonblight --expansion wotlk"
    write_cmd    "cargo run -- --map darkshire --expansion classic"
    write_cmd    "cargo run -- --map ragnaros --expansion classic"
    matched=1

# code2 -> rust -> tbc
elif path_contains_in_order code2 rust tbc; then
    write_header "Rust (tbc)"
    write_cmd    "cargo build --features use_sound"
    write_cmd    'cargo build --features "use_sound threadsafe"'
    write_label  "or without features:"
    write_cmd    "cargo build"
    write_label  "disable all defaults, enable explicitly:"
    write_cmd    "cargo build --no-default-features --features threadsafe"
    echo ""
    write_label  "redirect output:"
    write_extra  'cargo build *> test.txt'
    write_extra  'cargo run *> test.txt'
    write_extra  'cargo run --release *> test.txt'
    echo ""
    write_label  "backtrace:"
    write_alt    "RUST_BACKTRACE=1 cargo run"
    write_alt    "RUST_BACKTRACE=full cargo run"
    echo ""
    write_label  "dt flag (default ON):"
    write_cmd    "cargo run --"
    write_cmd    "cargo run -- --use-dt"
    write_cmd    "cargo run -- --no-use-dt"
    write_cmd    "cargo run -- --use-dt=false"
    echo ""
    write_label  "with map:"
    write_cmd    "cargo run av"
    write_cmd    "cargo run help"
    write_cmd    "cargo run -- --map wsg"
    write_cmd    "cargo run -- nagrandarena --use-dt=false"
    write_cmd    "cargo run -- --map ab --no-use-dt"
    matched=1

# code2 -> webwowviewer
elif path_contains_in_order code2 webwowviewer; then
    write_header "Web WoW Viewer (npm)"
    write_label  "use this:"
    write_cmd    "npm run start"
    echo ""
    write_cmd    "npm run server"
    write_alt    "npm run build"
    write_extra  "npm run build:prod"
    echo ""
    write_label  "Also start wow mpq file server"
    matched=1

# code2 -> spelunker
elif path_contains_in_order code2 spelunker; then
    write_header "Spelunker"
    write_label "setup:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/spelunker'
    write_cmd   "./setup.sh"
    echo ""
    write_label "start wow mpq file server and do (in both spelunker-api and spelunker-web):"
    write_cmd   "source ../../.envrc && npm start"
    echo ""
    write_label "If needed for file server (if mounted) you might need:"
    write_extra "npm install express cors --no-bin-links"
    matched=1

# code2 -> azeroth-web-proxy  (must come before azeroth-web)
elif path_contains_in_order code2 azeroth-web-proxy; then
    write_header "Azeroth Web Proxy"
    write_cmd   "npm start"
    echo ""
    write_label "Also run script in my_notes via:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/azeroth-web'
    write_cmd   "./setup.sh"
    echo ""
    write_label "Also start either acore/tcore to be able to login!"
    matched=1

# code2 -> azeroth-web
elif path_contains_in_order code2 azeroth-web; then
    write_header "Azeroth Web"
    write_cmd   "npm install -g typescript"
    write_cmd   "npm run dev"
    echo ""
    write_label "Also run script in my_notes via:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/azeroth-web'
    write_cmd   "./setup.sh"
    echo ""
    write_label "Also start either acore/tcore to be able to login!"
    matched=1

# code2 -> wowser
elif path_contains_in_order code2 wowser; then
    write_header "Wowser"
    write_label "Run script in my_notes via:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/wowser'
    write_cmd   "./setup.sh"
    echo ""
    write_cmd   "npm run serve"
    write_label "NOTE: specify wow client dir after running npm run serve!"
    write_label "you may need this if client dir is wrong:"
    write_alt   "npm run reset"
    write_label "use:"
    write_extra '$wow_dir'
    echo ""
    write_label "then, in another shell:"
    write_cmd   "npm run web-dev"
    matched=1

# code2 -> my_js -> mysql
elif path_contains_in_order code2 my_js mysql; then
    write_header "my_js / MySQL"
    write_cmd "node main.js"
    matched=1

# code2 -> my_js -> navigation
elif path_contains_in_order code2 my_js navigation; then
    write_header "my_js / Navigation"
    write_cmd "node main.js"
    matched=1

# code2 -> my_js -> keybinds
elif path_contains_in_order code2 my_js keybinds; then
    write_header "my_js / Keybinds"
    write_label "do this:"
    write_cmd   "npm run dev"
    echo ""
    write_alt   "npm run start"
    matched=1

# my_notes -> orders_ts
elif path_contains_in_order my_notes orders_ts; then
    write_header "orders_ts"
    write_cmd "npm run start"
    matched=1

# my_notes -> latest-orders-ts
elif path_contains_in_order my_notes latest-orders-ts; then
    write_header "latest-orders-ts"
    write_cmd "npx tsc && node ./dist/server.js"
    matched=1

# Fallback: check files in current directory
else
    if [[ -f "worldserver.exe" && -f "authserver.exe" ]]; then
        write_header "World Server"
        write_cmd   "python overwrite.py && ./worldserver.exe"
        echo ""
        write_label "Linux gdb:"
        write_alt   "python overwrite.py && gdb -x gdb.conf --batch ./worldserver"
        matched=1

    elif [[ -f "cors_server.js" && -f "cors_server.py" ]]; then
        write_header "CORS Server"
        write_cmd  "node ./cors_server.js"
        write_alt  "python ./cors_server.py"
        matched=1
    fi
fi

# No match
if [[ $matched -eq 0 ]]; then
    echo ""
    write_warn "  [!] No build commands matched for:"
    echo -e "      ${DARKYELLOW}${cwd_full}${RESET}"
    echo ""
fi
