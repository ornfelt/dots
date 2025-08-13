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
    done
  fi
}

# --- match cases (case-insensitive via $lc) ---

if [[ "$lc" == *azerothcore* ]]; then
  main='cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo'
  alts=(
    'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug'
    'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release'
  )

  run_or_print "$main"
  print_alternatives "${alts[@]}"

elif [[ "$lc" == *trinitycore* ]]; then
  main='cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo'
  alts=(
    'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug'
    'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release'
  )

  run_or_print "$main"
  print_alternatives "${alts[@]}"

elif [[ "$lc" == *my_web_wow* && "$lc" == *c++* ]]; then
  main='cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug'
  run_or_print "$main"

  if [[ -n "$OnlyPrint" ]]; then
    echo
    echo "alternative cmake command without vcpkg:"
    echo 'cmake -B build -S . -DCMAKE_BUILD_TYPE=Release'
  fi

elif [[ "$lc" == *openjk* ]]; then
    main='cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local/share/openjk -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    run_or_print "$main"

elif [[ "$lc" == *jediknightgalaxies* ]]; then
    main='cmake -DCMAKE_INSTALL_PREFIX=$HOME/Downloads/ja_data -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    run_or_print "$main"

elif [[ "$lc" == *stk-code* ]]; then
    main='cmake .. -DCMAKE_BUILD_TYPE=Release -DNO_SHADERC=on'
    run_or_print "$main"

elif [[ "$lc" == *dhewm3* ]]; then
    main='cmake ../neo/'
    run_or_print "$main"

elif [[ "$lc" == *blpconverter* ]]; then
    main='cmake .. -DWITH_LIBRARY=YES'
    run_or_print "$main"

elif [[ "$lc" == *stormlib* ]]; then
    main='cmake .. -DBUILD_SHARED_LIBS=ON'
    run_or_print "$main"

elif [[ "$lc" == *mangos-classic* ]]; then
    main='cmake .. -DCMAKE_INSTALL_PREFIX=~/cmangos/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON'
    run_or_print "$main"

elif [[ "$lc" == *mangos-tbc* ]]; then
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
    main='cmake .. -DDEBUG=0 -DSUPPORTED_CLIENT_BUILD=5875 -DUSE_EXTRACTORS=1 -DCMAKE_INSTALL_PREFIX=$HOME/vmangos'
    run_or_print "$main"

elif [[ "$lc" == *server* ]]; then
    main='cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=0 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run'
    run_or_print "$main"
    if [[ -n "$OnlyPrint" ]]; then
        echo
        echo "alternative cmake command with eluna:"
        echo 'cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=1 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run'
    fi

elif [[ "$lc" == *tbc* && "$lc" == *c++* ]]; then
    main='cmake .. -DUSE_SDL2=ON -DUSE_SOUND=ON -DUSE_NAMIGATOR=ON -DCMAKE_BUILD_TYPE=Debug'
    alts=(
        'cmake .. -DUSE_SDL2=OFF -DUSE_SOUND=ON -DUSE_NAMIGATOR=OFF -DCMAKE_BUILD_TYPE=Release'
    )
    run_or_print "$main"
    print_alternatives "${alts[@]}"

else
  # Default fallback
  echo "No cmake command found for: $cwd"
  echo "Using default cmake command..."
  main='cmake ../ -DCMAKE_BUILD_TYPE=Debug'
  run_or_print "$main"
fi

