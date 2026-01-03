#!/usr/bin/env python3
import os
import time
from datetime import datetime

# Hard-coded dirs to compare

#dir1 = "/media2/my_files/my_docs"
#dir2 = "/media/my_files/my_docs"

#dir1 = "/home/jonas/Downloads/yt/test/dir1"
#dir2 = "/home/jonas/Downloads/yt/test/dir2"

#dir1 = "/media2/Movies"
#dir2 = "/media/Movies"

#dir1 = "/media2/2025/mpq"
#dir2 = "/media/2025/mpq"

#dir1 = "/media2/my_files"
#dir2 = "/media/my_files"

#dir1 = "/media2/2024"
#dir2 = "/media/2024"

#dir1 = "/media2/2025"
#dir2 = "/media/2025"

dir1 = "/media2"
dir2 = "/media"

# Log file
target_log = "diff_check_py.log"

# Toggle for ignoring paths
IGNORE_PATH_FILTERS = True  # set to False to disable all ignoring

# Paths that cause "starts with" skip
IGNORE_PREFIXES = [
    "$RECYCLE.BIN/",
    "2024/wow/",
    ".Trash-1000/",
    "System Volume Information/",
]

# Paths that cause "contains" skip
IGNORE_CONTAINS = [
    "node_modules/",
    "llama2.c/.git",
    "llama3.2.c/.git",
    "torchless/.git",
    "llama2.c/build",
    "llama3.2.c/build",
    "torchless/build",
    "__pycache__/",
]

# Paths that cause "equals" skip
IGNORE_EQUALS = [
    "Movies",
    "recordings",
    "Magician Launcher.app",
    "Magician Launcher.exe",
    "RootCA.crt",
    "Program.puml",
    "SamsungPortableSSD_Setup_Mac_1.0.pkg",
    "SamsungPortableSSD_Setup_Win_1.0.exe",
    "Samsung Portable SSD SW for Android.txt",
]


def should_skip_path(path: str) -> bool:
    """
    Return True if this relative path should be ignored,
    following the same rules as the bash version.
    """
    if not IGNORE_PATH_FILTERS:
        return False

    # starts with prefixes
    for p in IGNORE_PREFIXES:
        if path.startswith(p):
            return True

    # contains substrings
    for p in IGNORE_CONTAINS:
        if p in path:
            return True

    # equals specific names
    for p in IGNORE_EQUALS:
        if path == p:
            return True

    return False


def collect_paths(base_dir: str) -> list[str]:
    """
    Recursively walk base_dir and collect relative paths (dirs + files),
    skipping ignored paths and pruning ignored directories.
    """
    paths: set[str] = set()

    for root, dirs, files in os.walk(base_dir):
        rel_root = os.path.relpath(root, base_dir)
        if rel_root == ".":
            rel_root = ""

        # Handle directories (and allow pruning)
        # We must modify dirs in-place to prevent os.walk from descending.
        dirs_to_keep = []
        for d in dirs:
            rel_path = os.path.join(rel_root, d) if rel_root else d
            rel_path = rel_path.replace(os.sep, "/")  # normalize to '/'
            if should_skip_path(rel_path):
                # prune this directory from traversal
                continue
            paths.add(rel_path)
            dirs_to_keep.append(d)
        dirs[:] = dirs_to_keep  # update in-place for os.walk

        # Handle files
        for f in files:
            rel_path = os.path.join(rel_root, f) if rel_root else f
            rel_path = rel_path.replace(os.sep, "/")
            if should_skip_path(rel_path):
                continue
            paths.add(rel_path)

    return sorted(paths)


def compress_paths(paths: list[str]) -> list[str]:
    """
    Mimic the awk "top-level only" logic:
    - For each path, if it is a subpath of any already-added path (prev + "/"),
      then skip it.
    """
    result: list[str] = []
    for p in sorted(paths):
        skip = False
        for prev in result:
            if p.startswith(prev + "/"):
                skip = True
                break
        if not skip:
            result.append(p)
    return result


def format_ms(ms: int) -> str:
    sec = ms // 1000
    rem = ms % 1000
    return f"{sec}.{rem:03d} seconds ({ms} ms)"


def main() -> None:
    script_start = time.perf_counter()

    # Open log file (truncate)
    with open(target_log, "w", encoding="utf-8") as log_file:

        def log(msg: str = "") -> None:
            print(msg)
            log_file.write(msg + "\n")
            log_file.flush()

        log(f"Comparison started at {datetime.now().isoformat(sep=' ', timespec='seconds')}")
        log(f"Comparing {dir1} <-> {dir2}")

        # Listing / "find" phase
        find_start = time.perf_counter()
        paths1 = collect_paths(dir1)
        paths2 = collect_paths(dir2)
        find_end = time.perf_counter()

        find_elapsed_ms = int((find_end - find_start) * 1000)
        log("")
        log(f"Listing phase (walk) took {format_ms(find_elapsed_ms)}")
        log("")

        # Compute diffs
        set1 = set(paths1)
        set2 = set(paths2)

        missing_in_2 = sorted(set1 - set2)
        missing_in_1 = sorted(set2 - set1)

        if not missing_in_2 and not missing_in_1:
            log("[ok] Both directories contain the same files and directories.")
        else:
            if missing_in_2:
                log(f"Entries in {dir1} missing in {dir2}:")
                for p in compress_paths(missing_in_2):
                    log(p)

            if missing_in_1:
                log(f"Entries in {dir2} missing in {dir1}:")
                for p in compress_paths(missing_in_1):
                    log(p)

        # Total runtime
        script_end = time.perf_counter()
        total_elapsed_ms = int((script_end - script_start) * 1000)
        log("")
        log(f"Total runtime: {format_ms(total_elapsed_ms)}")


if __name__ == "__main__":
    main()

