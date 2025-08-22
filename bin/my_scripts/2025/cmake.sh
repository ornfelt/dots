#!/usr/bin/env bash

# Usage:
# ./cmake.sh            # detect path and RUN the chosen cmake
# ./cmake.sh onlyprint  # detect path and PRINT commands (no execution)

OnlyPrint="${1:-}"
cwd="$(pwd)"
lc="${cwd,,}" # lowercase for case-insensitive checks

run_or_print() {
    local cmd="$1"
    if [[ -n "$OnlyPrint" ]]; then
        printf '%s\n' "$cmd"
    else
        echo "Executing: $cmd"
        eval "$cmd"
    fi
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

    echo "CMakeLists.txt not found at: $cmake_path ($context)"
    echo "Switching to PRINT-ONLY mode."
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

    main='cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug'
    run_or_print "$main"

    if [[ -n "$OnlyPrint" ]]; then
        echo
        echo "alternative cmake command without vcpkg:"
        echo 'cmake -B build -S . -DCMAKE_BUILD_TYPE=Release'
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
    main='cmake .. -DUSE_SDL2=ON -DUSE_SOUND=ON -DUSE_NAMIGATOR=ON -DCMAKE_BUILD_TYPE=Debug'
    alts=(
        'cmake .. -DUSE_SDL2=OFF -DUSE_SOUND=ON -DUSE_NAMIGATOR=OFF -DCMAKE_BUILD_TYPE=Release'
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

else
    test_cmakelists parent
    # Default fallback
    echo "No cmake command found for: $cwd"
    echo "Using default cmake command..."
    main='cmake ../ -DCMAKE_BUILD_TYPE=Debug'
    run_or_print "$main"
fi

