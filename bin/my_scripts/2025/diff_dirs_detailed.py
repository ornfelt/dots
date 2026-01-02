#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

# This script compares two dirs and identify differing files (print files that
# exists in one dir but not the other and vice versa). It also compares the
# file sizes of all files (assuming they exist in both dirs).

DIR1 = Path("/media/my_files/my_docs/local")
DIR2 = Path("/media2/my_files/my_docs/local")

def list_files(root: Path) -> dict[str, int]:
    """
    Return {relative_posix_path: size_bytes} for all regular files under root.
    Symlinks are ignored (treat them as not-files).
    """
    out: dict[str, int] = {}
    for p in root.rglob("*"):
        try:
            if not p.is_file() or p.is_symlink():
                continue
            rel = p.relative_to(root).as_posix()
            out[rel] = p.stat().st_size
        except (OSError, PermissionError):
            # If you want, you can print these instead of skipping.
            continue
    return out

def main() -> int:
    if not DIR1.is_dir():
        print(f"[ERR] DIR1 does not exist or is not a directory: {DIR1}")
        return 2
    if not DIR2.is_dir():
        print(f"[ERR] DIR2 does not exist or is not a directory: {DIR2}")
        return 2

    a = list_files(DIR1)
    b = list_files(DIR2)

    a_keys = set(a.keys())
    b_keys = set(b.keys())

    only_in_a = sorted(a_keys - b_keys)
    only_in_b = sorted(b_keys - a_keys)
    in_both = sorted(a_keys & b_keys)

    if only_in_a:
        print(f"\n== Files only in {DIR1} ({len(only_in_a)}) ==")
        for rel in only_in_a:
            print(rel)

    if only_in_b:
        print(f"\n== Files only in {DIR2} ({len(only_in_b)}) ==")
        for rel in only_in_b:
            print(rel)

    size_mismatches = []
    for rel in in_both:
        sa = a[rel]
        sb = b[rel]
        if sa != sb:
            size_mismatches.append((rel, sa, sb))

    if size_mismatches:
        print(f"\n== Size mismatches ({len(size_mismatches)}) ==")
        for rel, sa, sb in size_mismatches:
            print(f"{rel}\n  {DIR1}: {sa} bytes\n  {DIR2}: {sb} bytes")
    else:
        print("\n== No size mismatches for files present in both dirs ==")

    print("\nDone.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

