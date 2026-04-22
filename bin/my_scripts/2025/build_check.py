#!/usr/bin/env python3
"""
Audits every file referenced in build.py / build.sh / build.ps1.
Checks whether each file has an 'example usage:' / 'usage examples:' marker.

ONLY_MISSING = True   → print only files that are missing the marker (or missing entirely)
ONLY_MISSING = False  → print all files, grouped by status
"""

import os
import re

# ──────────────────────────────────────────────────────────────
# Config
# ──────────────────────────────────────────────────────────────

#ONLY_MISSING: bool = False
ONLY_MISSING: bool = True

# ──────────────────────────────────────────────────────────────
# File list  (env_var, relative_path)
# For WebWowViewer the .ts is the primary; .js is the fallback.
# ──────────────────────────────────────────────────────────────

FILES = [
    # ── my_web_wow variants ───────────────────────────────────
    ("code_root_dir", "Code2/Wow/tools/my_wow/go/my_web_wow/main.go"),
    ("code_root_dir", "Code2/Wow/tools/my_wow/rust/my_web_wow/src/main.rs"),
    ("code_root_dir", "Code2/Wow/tools/my_wow/python/my_web_wow/main.py"),
    ("code_root_dir", "Code2/Wow/tools/my_wow/c#/my_web_wow/my_web_wow/Program.cs"),

    # ── tbc variants ──────────────────────────────────────────
    ("code_root_dir", "Code2/Wow/tools/my_wow/go/tbc/main.go"),
    ("code_root_dir", "Code2/Wow/tools/my_wow/rust/tbc/src/main.rs"),
    ("code_root_dir", "Code2/Wow/tools/my_wow/python/tbc/main.py"),
    ("code_root_dir", "Code2/Wow/tools/my_wow/c#/tbc/tbc/Program.cs"),

    # ── wc_testing Go ─────────────────────────────────────────
    ("code_root_dir", "Code2/General/gfx/wc_testing_go/adt_app.go"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_go/m2_app.go"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_go/wdl_app.go"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_go/wmo_app.go"),

    # ── wc_testing Python ─────────────────────────────────────
    ("code_root_dir", "Code2/General/gfx/wc_testing_py/adt_app.py"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_py/m2_app.py"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_py/wdl_app.py"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_py/wmo_app.py"),

    # ── wc_testing Rust ───────────────────────────────────────
    ("code_root_dir", "Code2/General/gfx/wc_testing_rs/src/adt_app.rs"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_rs/src/m2_app.rs"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_rs/src/wdl_app.rs"),
    ("code_root_dir", "Code2/General/gfx/wc_testing_rs/src/wmo_app.rs"),

    # ── wc_testing C# ─────────────────────────────────────────
    ("code_root_dir", "Code2/General/gfx/wc_testing/AdtApp.cs"),
    ("code_root_dir", "Code2/General/gfx/wc_testing/M2App.cs"),
    ("code_root_dir", "Code2/General/gfx/wc_testing/WdlApp.cs"),
    ("code_root_dir", "Code2/General/gfx/wc_testing/WmoApp.cs"),

    # ── WebWowViewer (.ts primary, .js fallback) ──────────────
    ("code_root_dir", "Code2/Wow/tools/WebWoWViewer/js/application/angular/app_wow.ts"),
    ("code_root_dir", "Code2/Wow/tools/WebWoWViewer/js/application/angular/app_wowjs.js"),

    # ── my_js ─────────────────────────────────────────────────
    ("code_root_dir", "Code2/Javascript/my_js/Testing/mysql/main.js"),
    ("code_root_dir", "Code2/Javascript/my_js/Testing/navigation/main.js"),
    ("code_root_dir", "Code2/Javascript/my_js/Testing/navigation/ffi-napi/main.js"),

    # ── Svea / my_notes ───────────────────────────────────────
    ("my_notes_path", "notes/svea/scripts/orders_ts/src/orders.ts"),
    ("my_notes_path", "notes/svea/scripts/stats/latest-orders-ts/app/src/server.ts"),
]

# ──────────────────────────────────────────────────────────────
# Colour helpers (no third-party deps; ANSI works on Linux +
# Windows 10+ with VT processing enabled)
# ──────────────────────────────────────────────────────────────

import platform, ctypes

def _enable_ansi_windows():
    try:
        ctypes.windll.kernel32.SetConsoleMode(
            ctypes.windll.kernel32.GetStdHandle(-11), 7)
    except Exception:
        pass

if platform.system() == "Windows":
    _enable_ansi_windows()

RESET      = "\033[0m"
BOLD       = "\033[1m"
WHITE      = "\033[97m"
GREEN      = "\033[92m"
RED        = "\033[91m"
DARKYELLOW = "\033[93m"
DARKGRAY   = "\033[90m"
CYAN       = "\033[36m"

# ──────────────────────────────────────────────────────────────
# Comment-syntax + usage-example extraction
# (same logic as build.py)
# ──────────────────────────────────────────────────────────────

def get_comment_syntax(ext: str) -> dict:
    e = ext.lower()
    c_style   = {"single": "//",  "mstart": "/*",    "mend": "*/"}
    hash_only = {"single": "#",   "mstart": None,     "mend": None}
    lua_style = {"single": "--",  "mstart": "--[[",   "mend": "]]"}
    sql_style = {"single": "--",  "mstart": "/*",     "mend": "*/"}
    xml_style = {"single": None,  "mstart": "<!--",   "mend": "-->"}
    ps1_style = {"single": "#",   "mstart": "<#",     "mend": "#>"}
    rb_style  = {"single": "#",   "mstart": "=begin", "mend": "=end"}

    c_exts = {".go",".rs",".js",".ts",".jsx",".tsx",".mjs",".cjs",
              ".c",".cpp",".cc",".h",".hpp",".cs",".java",".kt",".swift",".php"}

    if e in c_exts:          return c_style
    if e == ".py":           return hash_only
    if e == ".rb":           return rb_style
    if e in (".sh", ".bash"): return hash_only
    if e == ".ps1":          return ps1_style
    if e == ".lua":          return lua_style
    if e == ".sql":          return sql_style
    if e in (".html", ".xml"): return xml_style
    return c_style

MARKER_RE = re.compile(r'(example\s+usage|usage\s+examples)\s*:', re.IGNORECASE)

def _advance_block(line: str, mstart: str | None, mend: str | None,
                   in_block: bool) -> bool:
    if not mstart:
        return in_block
    pos = 0
    while pos <= len(line):
        if not in_block:
            idx = line.find(mstart, pos)
            if idx == -1: break
            in_block = True
            pos = idx + len(mstart)
        else:
            idx = line.find(mend, pos)
            if idx == -1: break
            in_block = False
            pos = idx + len(mend)
    return in_block

def has_usage_example(filepath: str) -> tuple[bool, bool]:
    """
    Returns (file_exists, marker_found).
    Marker is only counted if it appears inside an actual comment.
    """
    if not os.path.isfile(filepath):
        return False, False

    _, ext = os.path.splitext(filepath)
    syn    = get_comment_syntax(ext or "")
    single = syn["single"]
    mstart = syn["mstart"]
    mend   = syn["mend"]

    with open(filepath, "r", encoding="utf-8", errors="replace") as fh:
        lines = fh.read().splitlines()

    in_block = False
    for line in lines:
        m = MARKER_RE.search(line)
        if not m:
            in_block = _advance_block(line, mstart, mend, in_block)
            continue

        marker_idx = m.start()
        is_multi   = False
        is_single  = False

        if in_block:
            is_multi = True
        elif mstart:
            s_idx = line.find(mstart)
            e_idx = line.find(mend)
            if (s_idx >= 0 and s_idx < marker_idx and
                    (e_idx < 0 or e_idx > marker_idx)):
                is_multi = True

        if not is_multi and single:
            if line.lstrip().startswith(single):
                is_single = True

        if is_multi or is_single:
            return True, True

        in_block = _advance_block(line, mstart, mend, in_block)

    return True, False

# ──────────────────────────────────────────────────────────────
# Resolve full paths
# ──────────────────────────────────────────────────────────────

def resolve(env_name: str, rel: str) -> tuple[str | None, str]:
    """Return (root_or_None, full_path)."""
    root = os.environ.get(env_name, "").strip().rstrip("/\\")
    if not root:
        return None, rel   # can't resolve without env var
    parts    = re.split(r'[/\\]', rel.lstrip("/\\"))
    fullpath = os.path.join(root, *parts)
    return root, fullpath

# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────

# Status buckets
STATUS_OK      = "ok"       # file exists, marker found
STATUS_MISSING = "missing"  # file exists, no marker
STATUS_NOFILE  = "nofile"   # file does not exist (or env var unset)
STATUS_NOENV   = "noenv"    # env var not set

def audit() -> list[dict]:
    results = []
    for env_name, rel in FILES:
        root, fullpath = resolve(env_name, rel)
        if root is None:
            results.append({
                "env":    env_name,
                "rel":    rel,
                "path":   fullpath,
                "status": STATUS_NOENV,
            })
            continue

        exists, found = has_usage_example(fullpath)
        if not exists:
            status = STATUS_NOFILE
        elif found:
            status = STATUS_OK
        else:
            status = STATUS_MISSING

        results.append({
            "env":    env_name,
            "rel":    rel,
            "path":   fullpath,
            "status": status,
        })
    return results

def print_results(results: list[dict]):
    # Counters
    counts = {STATUS_OK: 0, STATUS_MISSING: 0, STATUS_NOFILE: 0, STATUS_NOENV: 0}
    for r in results:
        counts[r["status"]] += 1

    if ONLY_MISSING:
        bad = [r for r in results if r["status"] != STATUS_OK]
        if not bad:
            print(f"\n  {GREEN}{BOLD}All {len(results)} files have example usage markers.{RESET}\n")
            return

        print(f"\n  {BOLD}{WHITE}Files missing example usage ({len(bad)} of {len(results)}):{RESET}\n")
        for r in bad:
            _print_row(r)
    else:
        # Group by status for a cleaner read
        order  = [STATUS_OK, STATUS_MISSING, STATUS_NOFILE, STATUS_NOENV]
        labels = {
            STATUS_OK:      f"{GREEN}✔  Found{RESET}",
            STATUS_MISSING: f"{DARKYELLOW}✘  Marker missing{RESET}",
            STATUS_NOFILE:  f"{RED}✘  File not found{RESET}",
            STATUS_NOENV:   f"{DARKGRAY}?  Env var not set{RESET}",
        }
        for status in order:
            group = [r for r in results if r["status"] == status]
            if not group:
                continue
            print(f"\n  {BOLD}{WHITE}{labels[status]}{BOLD}{WHITE} ({len(group)}){RESET}\n")
            for r in group:
                _print_row(r)

    # Summary line
    print()
    parts = [
        f"{GREEN}{counts[STATUS_OK]} ok{RESET}",
        f"{DARKYELLOW}{counts[STATUS_MISSING]} missing marker{RESET}",
        f"{RED}{counts[STATUS_NOFILE]} file not found{RESET}",
    ]
    if counts[STATUS_NOENV]:
        parts.append(f"{DARKGRAY}{counts[STATUS_NOENV]} env unset{RESET}")
    print("  " + "  |  ".join(parts))
    print()

def _print_row(r: dict):
    status = r["status"]
    path   = r["path"]
    env    = r["env"]

    if status == STATUS_OK:
        icon  = f"{GREEN}✔{RESET}"
        label = ""
    elif status == STATUS_MISSING:
        icon  = f"{DARKYELLOW}✘{RESET}"
        label = f"  {DARKGRAY}(no marker){RESET}"
    elif status == STATUS_NOFILE:
        icon  = f"{RED}✘{RESET}"
        label = f"  {DARKGRAY}(file not found){RESET}"
    else:  # NOENV
        icon  = f"{DARKGRAY}?{RESET}"
        label = f"  {DARKGRAY}(${env} not set){RESET}"

    # Print a shortened path: just show the part after the env root if available
    root = os.environ.get(env, "").strip().rstrip("/\\")
    if root and path.startswith(root):
        display = "$" + env + path[len(root):]
    else:
        display = path

    print(f"    {icon}  {CYAN}{display}{RESET}{label}")

if __name__ == "__main__":
    results = audit()
    print_results(results)
