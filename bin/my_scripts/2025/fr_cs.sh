#!/usr/bin/env sh

notes="$my_notes_path"

if [ -z "$notes" ]; then
    echo "Environment variable 'my_notes_path' is not set."
    exit 1
fi

project_dir="$notes/scripts/replace/cs/FindReplace"

if [ ! -d "$project_dir" ]; then
    echo "FindReplace directory does not exist:"
    echo "  $project_dir"
    exit 1
fi

if ! command -v dotnet >/dev/null 2>&1; then
    echo "dotnet was not found in PATH."
    exit 1
fi

get_exe_path() {
    for config in Release Debug; do
        bin_dir="$project_dir/bin/$config"

        if [ ! -d "$bin_dir" ]; then
            continue
        fi

        exe_path=$(
            find "$bin_dir" -type f -name "find_replace" 2>/dev/null |
                awk '
                    match($0, /\/net([0-9]+)\.0\/find_replace$/, m) {
                        print m[1] " " $0
                    }
                ' |
                sort -nr |
                head -n 1 |
                cut -d " " -f 2-
        )

        if [ -n "$exe_path" ]; then
            echo "$exe_path"
            return 0
        fi
    done

    return 1
}

exe_path="$(get_exe_path)"

if [ -z "$exe_path" ]; then
    echo "Could not find find_replace under:"
    echo "  $project_dir/bin/Release/net*/find_replace"
    echo "  $project_dir/bin/Debug/net*/find_replace"
    echo

    printf "Do you want to run 'dotnet build -c Release' now? [y/N] "
    read answer

    answer_lower=$(printf "%s" "$answer" | tr '[:upper:]' '[:lower:]')

    if [ "$answer_lower" = "y" ] || [ "$answer_lower" = "yes" ]; then
        echo "Building FindReplace in Release mode..."

        old_dir=$(pwd)

        cd "$project_dir" || {
            echo "Failed to enter project directory:"
            echo "  $project_dir"
            exit 1
        }

        dotnet build -c Release
        build_exit_code=$?

        cd "$old_dir" || exit 1

        if [ "$build_exit_code" -ne 0 ]; then
            echo "dotnet build failed with exit code $build_exit_code."
            exit "$build_exit_code"
        fi

        exe_path="$(get_exe_path)"

        if [ -z "$exe_path" ]; then
            echo "Build succeeded, but find_replace was still not found."
            echo "Checked:"
            echo "  $project_dir/bin/Release/net*/find_replace"
            echo "  $project_dir/bin/Debug/net*/find_replace"
            exit 1
        fi
    else
        echo "Build skipped. Cannot continue without find_replace."
        exit 1
    fi
fi

if [ ! -x "$exe_path" ]; then
    echo "Found find_replace, but it is not executable:"
    echo "  $exe_path"
    echo "Try:"
    echo "  chmod +x \"$exe_path\""
    exit 1
fi

echo "Running:"
echo "  $exe_path"

"$exe_path" "$@"
exit_code=$?

if [ "$exit_code" -ne 0 ]; then
    echo "find_replace failed with exit code $exit_code."
    exit "$exit_code"
fi

exit 0
