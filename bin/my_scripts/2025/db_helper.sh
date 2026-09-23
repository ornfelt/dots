#!/usr/bin/env bash

# db_helper.sh - launcher for the DbHelper GUI / CLI

set -euo pipefail

if [[ -z "${code_root_dir:-}" ]]; then
    echo "Environment variable 'code_root_dir' is not set." >&2
    exit 1
fi

PROJECT_DIR="$code_root_dir/Code2/C#/my_csharp/DbHelper"

if [[ ! -f "$PROJECT_DIR/DbHelper.csproj" ]]; then
    echo "DbHelper.csproj not found at: $PROJECT_DIR" >&2
    exit 1
fi

# ── Pick target framework ────────────────────────────────────────────
# Uses the csproj's TargetFramework when its runtime is installed, otherwise
# the highest .NET major that has both a runtime and an SDK able to build it.
if ! command -v dotnet > /dev/null; then
    echo "dotnet not found in PATH." >&2
    exit 1
fi

RUNTIME_MAJORS=$(dotnet --list-runtimes | awk '$1 == "Microsoft.NETCore.App" { split($2, v, "."); print v[1] }' | sort -rnu)
MAX_SDK_MAJOR=$(dotnet --list-sdks | awk '{ split($1, v, "."); print v[1] }' | sort -rn | head -n 1)

if [[ -z "$RUNTIME_MAJORS" || -z "$MAX_SDK_MAJOR" ]]; then
    echo "No usable .NET runtime/SDK found (runtimes: ${RUNTIME_MAJORS:-none}, max sdk: ${MAX_SDK_MAJOR:-none})." >&2
    exit 1
fi

CSPROJ_TFM=$(sed -n 's:.*<TargetFramework>\(net[0-9.]*\)</TargetFramework>.*:\1:p' "$PROJECT_DIR/DbHelper.csproj" | head -n 1)
CSPROJ_MAJOR=$(echo "$CSPROJ_TFM" | sed -n 's/^net\([0-9]*\).*/\1/p')

TFM=""
if [[ -n "$CSPROJ_MAJOR" ]] && (( CSPROJ_MAJOR <= MAX_SDK_MAJOR )) && grep -qx "$CSPROJ_MAJOR" <<< "$RUNTIME_MAJORS"; then
    TFM="$CSPROJ_TFM"
else
    for major in $RUNTIME_MAJORS; do
        if (( major <= MAX_SDK_MAJOR )); then
            TFM="net${major}.0"
            break
        fi
    done
fi

if [[ -z "$TFM" ]]; then
    echo "No installed .NET runtime can be built by the installed SDKs (max sdk: $MAX_SDK_MAJOR)." >&2
    exit 1
fi

BUILD_ARGS=(-c Release --nologo -v quiet)
if [[ "$TFM" != "$CSPROJ_TFM" ]]; then
    echo "csproj targets '${CSPROJ_TFM:-?}' which is not available, using $TFM" >&2
    BUILD_ARGS+=(-p:TargetFramework="$TFM")
fi

# ── Find or build ────────────────────────────────────────────────────
RELEASE_EXE="$PROJECT_DIR/bin/Release/$TFM/DbHelper"
DEBUG_EXE="$PROJECT_DIR/bin/Debug/$TFM/DbHelper"

if [[ -x "$RELEASE_EXE" ]]; then
    EXE_PATH="$RELEASE_EXE"
elif [[ -x "$DEBUG_EXE" ]]; then
    EXE_PATH="$DEBUG_EXE"
else
    echo "Building DbHelper..." >&2
    pushd "$PROJECT_DIR" > /dev/null
    dotnet build "${BUILD_ARGS[@]}"
    popd > /dev/null

    if [[ ! -f "$RELEASE_EXE" ]]; then
        # .NET on Linux may produce a DLL only (no native exe)
        echo "Running via dotnet run..." >&2
        dotnet run --project "$PROJECT_DIR" "${BUILD_ARGS[@]}" -- "$@"
        exit $?
    fi
    EXE_PATH="$RELEASE_EXE"
fi

"$EXE_PATH" "$@"
