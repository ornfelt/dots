#!/usr/bin/env bash
# proj_summarize.sh - Language dispatcher for proj_summarize scripts

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'

write_ok()       { echo -e "${GREEN}${1}${RESET}"; }
write_err()      { echo -e "${RED}${1}${RESET}"; }
write_warn()     { echo -e "${YELLOW}${1}${RESET}"; }
write_info()     { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt() { echo -e "${MAGENTA}${1}${RESET}"; }

# --- Validate args -----------------------------------------------------------

if [[ $# -eq 0 ]]; then
    write_err "Usage: proj_summarize.sh <language> [args...]"
    write_info "Supported languages: c, cs, c#, csharp, cpp, c++, go, golang, java, js, javascript, ts, typescript, py, python, rust, rs"
    exit 1
fi

lang_input="${1}"
shift                  # remove language arg; remaining "$@" are forwarded

# --- Language map (case-insensitive) -----------------------------------------

resolve_lang() {
    case "${1,,}" in
        c)                    echo 'c'   ;;
        cs|'c#'|csharp)       echo 'cs'  ;;
        cpp|'c++')            echo 'cpp' ;;
        go|golang)            echo 'go'  ;;
        java)                 echo 'java';;
        js|javascript)        echo 'js'  ;;
        ts|typescript)        echo 'ts'  ;;
        py|python)            echo 'py'  ;;
        rs|rust)              echo 'rs'  ;;
        *)                    echo ''    ;;
    esac
}

lang_dir="$(resolve_lang "$lang_input")"

if [[ -z "$lang_dir" ]]; then
    write_err "Unknown language: '$lang_input'"
    write_info "Supported: c, cs, c#, csharp, cpp, c++, go, golang, java, js, javascript, ts, typescript, py, python, rust, rs"
    exit 1
fi

# --- Resolve my_notes_path ---------------------------------------------------

if [[ -z "$my_notes_path" ]]; then
    write_err "Environment variable 'my_notes_path' is not set."
    exit 1
fi

script_path="${my_notes_path}/scripts/files/proj_summarize/${lang_dir}/proj_summarize.sh"

if [[ ! -f "$script_path" ]]; then
    write_warn "No proj_summarize script found for language '$lang_dir'."
    write_warn "Expected: $script_path"
    exit 1
fi

# --- Dispatch ----------------------------------------------------------------

write_info "Dispatching to [${lang_dir}] -> ${script_path}"

if [[ $# -gt 0 ]]; then
    write_info_alt "Forwarding args: $*"
fi

bash "$script_path" "$@"
exit $?#!/usr/bin/env bash
# proj_summarize.sh - Language dispatcher for proj_summarize scripts

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'

write_ok()       { echo -e "${GREEN}${1}${RESET}"; }
write_err()      { echo -e "${RED}${1}${RESET}"; }
write_warn()     { echo -e "${YELLOW}${1}${RESET}"; }
write_info()     { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt() { echo -e "${MAGENTA}${1}${RESET}"; }

# --- Validate args -----------------------------------------------------------

if [[ $# -eq 0 ]]; then
    write_err "Usage: proj_summarize.sh <language> [args...]"
    write_info "Supported languages: c, cs, c#, csharp, cpp, c++, go, golang, java, js, javascript, ts, typescript, py, python, rust, rs"
    exit 1
fi

lang_input="${1}"
shift                  # remove language arg; remaining "$@" are forwarded

# --- Language map (case-insensitive) -----------------------------------------

resolve_lang() {
    case "${1,,}" in
        c)                    echo 'c'   ;;
        cs|'c#'|csharp)       echo 'cs'  ;;
        cpp|'c++')            echo 'cpp' ;;
        go|golang)            echo 'go'  ;;
        java)                 echo 'java';;
        js|javascript)        echo 'js'  ;;
        ts|typescript)        echo 'ts'  ;;
        py|python)            echo 'py'  ;;
        rs|rust)              echo 'rs'  ;;
        *)                    echo ''    ;;
    esac
}

lang_dir="$(resolve_lang "$lang_input")"

if [[ -z "$lang_dir" ]]; then
    write_err "Unknown language: '$lang_input'"
    write_info "Supported: c, cs, c#, csharp, cpp, c++, go, golang, java, js, javascript, ts, typescript, py, python, rust, rs"
    exit 1
fi

# --- Resolve my_notes_path ---------------------------------------------------

if [[ -z "$my_notes_path" ]]; then
    write_err "Environment variable 'my_notes_path' is not set."
    exit 1
fi

script_path="${my_notes_path}/scripts/files/proj_summarize/${lang_dir}/proj_summarize.sh"

if [[ ! -f "$script_path" ]]; then
    write_warn "No proj_summarize script found for language '$lang_dir'."
    write_warn "Expected: $script_path"
    exit 1
fi

# --- Dispatch ----------------------------------------------------------------

write_info "Dispatching to [${lang_dir}] -> ${script_path}"

if [[ $# -gt 0 ]]; then
    write_info_alt "Forwarding args: $*"
fi

bash "$script_path" "$@"
#exit $?
# prompt to see if user wants to keep report before exiting...
exit_code=$?

# --- Prompt to keep/delete summary file --------------------------------------

if [[ $exit_code -eq 0 ]]; then
    report_file="${lang_dir}-proj-summary.txt"
    report_path="$(pwd)/${report_file}"

    if [[ -f "$report_path" ]]; then
        #write_info "Summary file produced: $report_path"
        read -rp "Keep this summary file? Type yes/y to keep: " answer
        if [[ "${answer,,}" =~ ^(y|yes)$ ]]; then
            write_ok "Keeping summary file: $report_path"
        else
            rm -f "$report_path"
            write_warn "Deleted summary file: $report_path"
        fi
    else
        write_warn "Expected summary file was not found: $report_path"
    fi
fi

exit $exit_code
