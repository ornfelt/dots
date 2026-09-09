#!/usr/bin/env bash

# cmake_helper.sh - launcher for the CmakeHelper GUI / CLI
#
# Usage examples:
#   .cmake_helper                          open the ImGui GUI for the current directory
#   .cmake_helper --tui                    open the Terminal UI instead
#   .cmake_helper --print                  print the cmake command for the current directory
#   .cmake_helper --print --alternatives   ... plus the variant alternatives
#   .cmake_helper --copy                   copy the cmake command to the clipboard
#   .cmake_helper --run --build            configure, then build
#   .cmake_helper --debug-cmd              print the shell one-liner instead of running it
#   .cmake_helper --help                   full option list

set -euo pipefail

if [[ -z "${code_root_dir:-}" ]]; then
    echo "Environment variable 'code_root_dir' is not set." >&2
    exit 1
fi

PROJECT_DIR="$code_root_dir/Code2/C#/my_csharp/CmakeHelper"

if [[ ! -f "$PROJECT_DIR/CmakeHelper.csproj" ]]; then
    echo "CmakeHelper.csproj not found at: $PROJECT_DIR" >&2
    exit 1
fi

# ── Find or build ────────────────────────────────────────────────────
RELEASE_EXE="$PROJECT_DIR/bin/Release/net9.0/CmakeHelper"
DEBUG_EXE="$PROJECT_DIR/bin/Debug/net9.0/CmakeHelper"

if [[ -x "$RELEASE_EXE" ]]; then
    EXE_PATH="$RELEASE_EXE"
elif [[ -x "$DEBUG_EXE" ]]; then
    EXE_PATH="$DEBUG_EXE"
else
    echo "Building CmakeHelper..." >&2
    pushd "$PROJECT_DIR" > /dev/null
    dotnet build -c Release --nologo -v quiet
    popd > /dev/null

    if [[ ! -f "$RELEASE_EXE" ]]; then
        # .NET on Linux may produce a DLL only (no native exe)
        echo "Running via dotnet run..." >&2
        dotnet run --project "$PROJECT_DIR" -c Release -- "$@"
        exit $?
    fi
    EXE_PATH="$RELEASE_EXE"
fi

# Run from the caller's directory - that is the path the patterns match against.
"$EXE_PATH" "$@"
