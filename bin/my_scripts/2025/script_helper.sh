#!/usr/bin/env bash

# script_helper.sh - launcher for the ScriptHelper GUI / CLI

set -euo pipefail

if [[ -z "${code_root_dir:-}" ]]; then
    echo "Environment variable 'code_root_dir' is not set." >&2
    exit 1
fi

PROJECT_DIR="$code_root_dir/Code2/C#/my_csharp/ScriptHelper"

if [[ ! -f "$PROJECT_DIR/ScriptHelper.csproj" ]]; then
    echo "ScriptHelper.csproj not found at: $PROJECT_DIR" >&2
    exit 1
fi

# ── Find or build ────────────────────────────────────────────────────
RELEASE_EXE="$PROJECT_DIR/bin/Release/net8.0/ScriptHelper"
DEBUG_EXE="$PROJECT_DIR/bin/Debug/net8.0/ScriptHelper"

if [[ -x "$RELEASE_EXE" ]]; then
    EXE_PATH="$RELEASE_EXE"
elif [[ -x "$DEBUG_EXE" ]]; then
    EXE_PATH="$DEBUG_EXE"
else
    echo "Building ScriptHelper..." >&2
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

"$EXE_PATH" "$@"
