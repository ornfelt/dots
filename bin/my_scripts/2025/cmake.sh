#!/usr/bin/env bash

# Usage:
# ./cmake.sh            # detect path and RUN the chosen cmake
# ./cmake.sh onlyprint  # detect path and PRINT commands (no execution)
# ./cmake.sh r/release  # RUN in Release mode
# ./cmake.sh r foo      # RUN in Release mode and PRINT commands (no execution)

# Use OnlyPrint if any arg is provided
#OnlyPrint="${1:-}"

# Use OnlyPrint if any arg is provided EXCEPT r/release
Arg="${1:-}"
arg_lc="${Arg,,}"

# Print-only unless argument is "r" or "release" (case-insensitive)
OnlyPrint=""
Release=""
if [[ -n "$Arg" ]]; then
    if [[ "$arg_lc" == "r" || "$arg_lc" == "release" ]]; then
        Release=1
        # If there's also another arg, enable print-only too
        [[ -n "${2:-}" ]] && OnlyPrint=1
    else
        OnlyPrint=1
    fi
fi

# build type helper
BuildType="Debug"
[[ -n "$Release" ]] && BuildType="Release"

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

# Help check (case-insensitive)
help_tokens=("h" "help" "-h" "--help")
for token in "${help_tokens[@]}"; do
    if [[ "${1,,}" == "$token" || "${2,,}" == "$token" ]]; then
        cat <<'EOF'
cmake.sh - context-aware cmake helper

Usage:
  ./cmake.sh
      Detect path and RUN the chosen cmake command.

  ./cmake.sh onlyprint
      Detect path and PRINT commands (no execution).

  ./cmake.sh r | release
      Run in Release mode.

  ./cmake.sh r foo
      Release mode + PRINT-ONLY (because a second arg exists).

  ./cmake.sh h | help | -h | --help
      Show this help.

Notes:
  - BuildType defaults to Debug unless you pass r/release.
  - The script chooses a cmake command based on your current working directory.
EOF
        exit 0
    fi
done

# Debug print (PowerShell-style)
if [[ -n "$OnlyPrint" ]]; then
    printf "%b[OnlyPrint]=ON  [BuildType]=%s%b\n" "$MAGENTA" "$BuildType" "$RESET"
else
    printf "%b[OnlyPrint]=OFF  [BuildType]=%s%b\n" "$MAGENTA" "$BuildType" "$RESET"
fi

# get current working dir
cwd="$(pwd)"
lc="${cwd,,}" # lowercase for case-insensitive checks

run_or_print() {
    local cmd="$1"
    if [[ -n "$OnlyPrint" ]]; then
        printf '%s\n' "$cmd"
    else
        printf "%bExecuting: %s%b\n" "$CYAN" "$cmd" "$RESET"
        eval "$cmd"
    fi

    printf "%bIf needed, run:%b\n" "$BLUE" "$RESET"
    printf "%bmake -j\$(nproc)%b\n" "$BLUE" "$RESET"
}

print_alternatives() {
    if [[ -n "$OnlyPrint" && $# -gt 0 ]]; then
        echo
        echo "alternative cmake commands:"
        for l in "$@"; do
            echo "$l"
            echo
        done
    fi
}

test_cmakelists() {
    local where="${1:-current}"
    local context="${2:-this project}"
    local base="$cwd"
    [[ "$where" == "parent" ]] && base="$(dirname "$cwd")"

    local cmake_path="$base/CMakeLists.txt"
    if [[ -f "$cmake_path" ]]; then
        return 0
    fi

    printf "%bCMakeLists.txt not found at: %s - %s%b\n" "$DARKYELLOW" "$cmake_path" "$context" "$RESET"

    if [[ "$where" == "parent" ]]; then
        printf "%bMaybe try:%b\n" "$DARKYELLOW" "$RESET"
        printf "%b-> mkdir build && cd build%b\n" "$DARKYELLOW" "$RESET"
        printf "%bThen run the command again!%b\n" "$DARKYELLOW" "$RESET"
    fi

    #echo "Switching to PRINT-ONLY mode." >&2
    #echo >&2
    printf "%bSwitching to PRINT-ONLY mode.%b\n" "$DARKYELLOW" "$RESET"
    echo

    OnlyPrint=1
    return 1
}

# --- match cases (case-insensitive via $lc) ---

if [[ "$lc" == *azerothcore* ]]; then
    test_cmakelists parent "azerothcore (expecting CMakeLists.txt one level up)"

    main='cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo'
    alts=(
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug'
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release'
    )

    run_or_print "$main"
    print_alternatives "${alts[@]}"

elif [[ "$lc" == *trinitycore* ]]; then
    test_cmakelists parent "trinitycore (expecting CMakeLists.txt one level up)"

    main='cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo'
    alts=(
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug'
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release'
    )

    run_or_print "$main"
    print_alternatives "${alts[@]}"

elif [[ "$lc" == *my_web_wow* && "$lc" == *c++* ]]; then
    test_cmakelists current "my_web_wow C++ (expecting CMakeLists.txt in current directory)"

    # Default: custom glm, custom optimization flags enabled
    main="cmake -B build -S . -DENABLE_CUSTOM_OPT_FLAGS=ON -DUSE_ASYNC=ON -DUSE_CUSTOM_GLM=ON -DCMAKE_BUILD_TYPE=$BuildType"
    run_or_print "$main"

    if [[ -n "$OnlyPrint" ]]; then
        echo
        echo "without compiler optimization flags:"
        echo "cmake -B build -S . -DENABLE_CUSTOM_OPT_FLAGS=OFF -DCMAKE_BUILD_TYPE=$BuildType"

        echo
        echo "without async:"
        echo "cmake -B build -S . -DUSE_ASYNC=OFF -DCMAKE_BUILD_TYPE=$BuildType"

        echo
        echo "without custom glm (use real installed glm):"
        echo "cmake -B build -S . -DUSE_CUSTOM_GLM=OFF -DCMAKE_BUILD_TYPE=$BuildType"

        echo
        echo "with debug timing and custom threadpool:"
        echo "cmake -B build -S . -DENABLE_CUSTOM_OPT_FLAGS=ON -DUSE_CUSTOM_GLM=ON -DUSE_ASYNC=ON -DWITH_DEBUG_TIMING=ON -DUSE_CUSTOM_THREADPOOL=ON -DCMAKE_BUILD_TYPE=$BuildType"
    fi

elif [[ "$lc" == *openjk* ]]; then
    test_cmakelists parent "openjk (expecting CMakeLists.txt one level up)"
    main='cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local/share/openjk -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    run_or_print "$main"

elif [[ "$lc" == *jediknightgalaxies* ]]; then
    test_cmakelists parent "jediknightgalaxies (expecting CMakeLists.txt one level up)"
    main='cmake -DCMAKE_INSTALL_PREFIX=$HOME/Downloads/ja_data -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    run_or_print "$main"

elif [[ "$lc" == *stk-code* ]]; then
    test_cmakelists parent "stk-code (expecting CMakeLists.txt one level up)"
    main='cmake .. -DCMAKE_BUILD_TYPE=Release -DNO_SHADERC=on'
    run_or_print "$main"

elif [[ "$lc" == *dhewm3* ]]; then
    main='cmake ../neo/'
    run_or_print "$main"

elif [[ "$lc" == *blpconverter* ]]; then
    test_cmakelists parent "blpconverter (expecting CMakeLists.txt one level up)"
    main='cmake .. -DWITH_LIBRARY=YES'
    run_or_print "$main"

elif [[ "$lc" == *stormlib* ]]; then
    test_cmakelists parent "stormlib (expecting CMakeLists.txt one level up)"
    main='cmake .. -DBUILD_SHARED_LIBS=ON'
    run_or_print "$main"

elif [[ "$lc" == *mangos-classic* ]]; then
    test_cmakelists parent "mangos-classic (expecting CMakeLists.txt one level up)"
    main='cmake .. -DCMAKE_INSTALL_PREFIX=~/cmangos/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON'
    run_or_print "$main"

elif [[ "$lc" == *mangos-tbc* ]]; then
    test_cmakelists parent "mangos-tbc (expecting CMakeLists.txt one level up)"
    main='cmake -S .. -B ./ -DCMAKE_INSTALL_PREFIX=~/cmangos-tbc/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON -DCMAKE_BUILD_TYPE=Release'
    alts=(
        'cmake -S .. -B ./ -DCMAKE_INSTALL_PREFIX=~/cmangos-tbc/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=1 -DBUILD_PLAYERBOTS=ON -DCMAKE_BUILD_TYPE=Debug'
    )
    run_or_print "$main"
    print_alternatives "${alts[@]}"
    if [[ -n "$OnlyPrint" ]]; then
        echo
        echo "alternative cmake command with clang:"
        echo 'cmake .. -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ ...'
    fi

elif [[ "$lc" == *core* ]]; then
    test_cmakelists parent "vmangos(core) (expecting CMakeLists.txt one level up)"
    main='cmake .. -DDEBUG=0 -DSUPPORTED_CLIENT_BUILD=5875 -DUSE_EXTRACTORS=1 -DCMAKE_INSTALL_PREFIX=$HOME/vmangos'
    run_or_print "$main"

elif [[ "$lc" == *server* ]]; then
    test_cmakelists parent "mangoszero(server) (expecting CMakeLists.txt one level up)"
    main='cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=0 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run'
    run_or_print "$main"
    if [[ -n "$OnlyPrint" ]]; then
        echo
        echo "alternative cmake command with eluna:"
        echo 'cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=1 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run'
    fi

elif [[ "$lc" == *tbc* && "$lc" == *c++* ]]; then
    test_cmakelists parent "my_wow tbc c++ (expecting CMakeLists.txt one level up)"
    main="cmake .. -DUSE_SDL2=ON -DUSE_SOUND=ON -DUSE_NAMIGATOR=OFF -DUSE_STOPWATCH_DT=ON -DCMAKE_BUILD_TYPE=$BuildType"
    alts=(
        "cmake .. -DUSE_SDL2=OFF -DUSE_SOUND=ON -DUSE_NAMIGATOR=ON -DUSE_STOPWATCH_DT=OFF -DCMAKE_BUILD_TYPE=$BuildType"
    )
    run_or_print "$main"
    print_alternatives "${alts[@]}"

elif [[ "$lc" == *neovim* ]]; then
    test_cmakelists current "neovim (expecting CMakeLists.txt in current directory)"

    # Just print for neovim (best to do manually)
    echo "Do the following:"
    echo "git checkout stable"
    echo "make CMAKE_BUILD_TYPE={Release / RelWithDebInfo}"
    echo "sudo make install"

    if grep -qiE 'debian|ubuntu' /etc/os-release; then
        echo "Note: also 'run sudo apt remove neovim -y' first!"
    fi

elif [[ "$lc" == *ioq3* ]]; then
    test_cmakelists current "ioq3 (expecting CMakeLists.txt in current directory)"

    main='cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build'
    run_or_print "$main"

    if [[ -n "$OnlyPrint" ]]; then
        echo
        echo "cmake -S . -B build -DCMAKE_BUILD_TYPE=$BuildType && cmake --build build"
    fi

elif [[ "$lc" == *torchless* ]]; then
    test_cmakelists parent "torchless (expecting CMakeLists.txt one level up)"
    main='cmake .. -DCMAKE_BUILD_TYPE=Release && cmake --build .'
    run_or_print "$main"

elif [[ "$lc" == *ollama* ]]; then
    test_cmakelists current "ollama (expecting CMakeLists.txt in current directory)"

    main='cmake -B build && cmake --build build -j $(nproc)'
    run_or_print "$main"

elif [[ "$lc" == *llama.cpp* ]]; then
    test_cmakelists current "llama.cpp (expecting CMakeLists.txt in current directory)"

    main='cmake -B build && cmake --build build --config Release -j $(nproc)'
    run_or_print "$main"

    if [[ -n "$OnlyPrint" ]]; then
        echo
        echo "cmake -B build && cmake --build build --config $BuildType"
    fi

elif [[ "$lc" == *wc_simple* ]]; then
    test_cmakelists parent "wc_simple (expecting CMakeLists.txt one level up)"

    main="cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DGFX_DLL=OFF"
    alts=(
        "cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DGFX_DLL=ON"
    )

    run_or_print "$main"
    print_alternatives "${alts[@]}"

# wildcard match:
elif [[ "$lc" == *wc_clean_mcnk* || "$lc" == *wc_clean_m2* ]]; then
# Regex match alternative:
#elif [[ "$lc" =~ wc_clean_(mcnk|m2) ]]; then

    # Determine which project we matched
    proj="wc_clean_mcnk"
    [[ "$lc" == *wc_clean_m2* ]] && proj="wc_clean_m2"

    test_cmakelists parent "$proj (expecting CMakeLists.txt one level up)"

    main="cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DGFX_DLL=OFF -DLIBWOW_DLL=OFF -DENABLE_DEBUG_RENDERING=ON -DENABLE_PERFORMANCE=OFF -DENABLE_MEMORY=OFF"
    alts=(
        "cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DGFX_DLL=ON -DLIBWOW_DLL=ON -DENABLE_DEBUG_RENDERING=ON -DENABLE_PERFORMANCE=OFF -DENABLE_MEMORY=OFF"
        "cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DGFX_DLL=ON -DLIBWOW_DLL=ON -DENABLE_DEBUG_RENDERING=ON -DENABLE_PERFORMANCE=ON -DENABLE_MEMORY=ON"
    )

    run_or_print "$main"
    print_alternatives "${alts[@]}"

elif [[ "$lc" == *wc_clean_new* ]]; then
    test_cmakelists parent "wc_clean_new (expecting CMakeLists.txt one level up)"

    main="cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DENABLE_DEBUG_RENDERING=ON -DENABLE_PERFORMANCE=OFF -DENABLE_MEMORY=OFF -DENABLE_WANDER=ON"
    alts=(
        "cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DENABLE_DEBUG_RENDERING=ON -DENABLE_PERFORMANCE=ON -DENABLE_MEMORY=OFF -DENABLE_WANDER=ON"
        "cmake .. -DCMAKE_BUILD_TYPE=$BuildType -DENABLE_DEBUG_RENDERING=ON -DENABLE_PERFORMANCE=ON -DENABLE_MEMORY=ON -DENABLE_WANDER=ON"
    )

    run_or_print "$main"
    print_alternatives "${alts[@]}"

else
    #test_cmakelists parent
    test_cmakelists parent "$(basename "$cwd")"

    # Default fallback
    printf "%bNo cmake command found for: %s%b\n" "$DARKYELLOW" "$cwd" "$RESET"
    printf "%bUsing default cmake command...%b\n" "$DARKYELLOW" "$RESET"
    main="cmake ../ -DCMAKE_BUILD_TYPE=$BuildType"
    run_or_print "$main"
fi

