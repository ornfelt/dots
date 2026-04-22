#!/usr/bin/env python3
"""
Prints relevant build commands based on cwd.
Python port of build.sh / build.ps1 — same logic, cross-platform.
"""

import os
import re
import sys
import platform

# ──────────────────────────────────────────────────────────────
# Platform helpers
# ──────────────────────────────────────────────────────────────

IS_WINDOWS = platform.system() == "Windows"
IS_LINUX   = not IS_WINDOWS  # close enough; handles WSL, macOS, etc.

def _enable_ansi_windows():
    """Enable VT-100 / ANSI escape codes in the Windows console."""
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        # ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        pass

if IS_WINDOWS:
    _enable_ansi_windows()

# ──────────────────────────────────────────────────────────────
# ANSI colour codes
# ──────────────────────────────────────────────────────────────

RESET      = "\033[0m"
WHITE      = "\033[97m"
BOLD       = "\033[1m"
CYAN       = "\033[36m"
MAGENTA    = "\033[35m"
BLUE       = "\033[34m"
DARKGRAY   = "\033[90m"
DARKYELLOW = "\033[93m"

# ──────────────────────────────────────────────────────────────
# Output helpers
# ──────────────────────────────────────────────────────────────

def write_label(text):
    print(f"  {DARKGRAY}{text}{RESET}")

def write_cmd(text):
    print(f"  {CYAN}{text}{RESET}")

def write_alt(text):
    print(f"  {MAGENTA}{text}{RESET}")

def write_extra(text):
    print(f"  {BLUE}{text}{RESET}")

def write_warn(text):
    print(f"{DARKYELLOW}{text}{RESET}")

def write_header(text):
    print()
    print(f"  {BOLD}{WHITE}=== {text} ==={RESET}")
    print()

def write_subheader(text):
    print()
    print(f"  {WHITE}--- {text} ---{RESET}")

# ──────────────────────────────────────────────────────────────
# Path helpers
# ──────────────────────────────────────────────────────────────

CWD_FULL = os.getcwd()
CWD      = CWD_FULL.lower()

def path_contains_in_order(*keywords):
    """Return True if all keywords appear in CWD in the given order."""
    pos = 0
    for kw in keywords:
        kw_l = kw.lower()
        idx  = CWD.find(kw_l, pos)
        if idx == -1:
            return False
        pos = idx + len(kw_l)
    return True

# ──────────────────────────────────────────────────────────────
# Comment-syntax table
# ──────────────────────────────────────────────────────────────

def get_comment_syntax(ext: str) -> dict:
    """
    Return {'single': ..., 'mstart': ..., 'mend': ...} for an extension.
    None means "not supported".
    """
    e = ext.lower()
    c_style  = {"single": "//",  "mstart": "/*",     "mend": "*/"}
    hash_only= {"single": "#",   "mstart": None,      "mend": None}
    lua_style= {"single": "--",  "mstart": "--[[",    "mend": "]]"}
    sql_style= {"single": "--",  "mstart": "/*",      "mend": "*/"}
    xml_style= {"single": None,  "mstart": "<!--",    "mend": "-->"}
    ps1_style= {"single": "#",   "mstart": "<#",      "mend": "#>"}
    rb_style = {"single": "#",   "mstart": "=begin",  "mend": "=end"}
    sh_style = {"single": "#",   "mstart": None,      "mend": None}

    c_exts = {".go",".rs",".js",".ts",".jsx",".tsx",".mjs",".cjs",
              ".c",".cpp",".cc",".h",".hpp",".cs",".java",".kt",".swift",".php"}

    if e in c_exts:   return c_style
    if e == ".py":    return hash_only
    if e == ".rb":    return rb_style
    if e == ".sh":    return sh_style
    if e == ".ps1":   return ps1_style
    if e == ".lua":   return lua_style
    if e == ".sql":   return sql_style
    if e in (".html", ".xml"): return xml_style
    return c_style  # default

# ──────────────────────────────────────────────────────────────
# Usage-example extraction
# ──────────────────────────────────────────────────────────────

MARKER_RE = re.compile(
    r'(example\s+usage|usage\s+examples)\s*:',
    re.IGNORECASE
)

def _advance_block_state(line: str, mstart: str, mend: str, in_block: bool) -> bool:
    """Track whether we're inside a multi-line comment after processing `line`."""
    if not mstart:
        return in_block
    pos = 0
    length = len(line)
    while pos <= length:
        if not in_block:
            idx = line.find(mstart, pos)
            if idx == -1:
                break
            in_block = True
            pos = idx + len(mstart)
        else:
            idx = line.find(mend, pos)
            if idx == -1:
                break
            in_block = False
            pos = idx + len(mend)
    return in_block

def _strip_leading_stars(s: str) -> str:
    """Strip leading '*' characters and one optional space (Javadoc style)."""
    while s.startswith("*"):
        s = s[1:]
    if s.startswith(" "):
        s = s[1:]
    return s

def get_usage_examples(filepath: str) -> dict:
    """
    Parse a source file and extract the first 'example usage:' /
    'usage examples:' comment block.

    Returns a dict with:
        file_exists  bool
        found        bool
        lines        list[str]
    """
    ret = {"file_exists": False, "found": False, "lines": []}

    if not os.path.isfile(filepath):
        return ret
    ret["file_exists"] = True

    _, ext = os.path.splitext(filepath)
    syn    = get_comment_syntax(ext or "")
    single = syn["single"]
    mstart = syn["mstart"]
    mend   = syn["mend"]
    has_single = bool(single)
    has_multi  = bool(mstart)

    with open(filepath, "r", encoding="utf-8", errors="replace") as fh:
        raw_lines = fh.read().splitlines()

    in_block = False
    result   = []
    n        = len(raw_lines)

    for i, line in enumerate(raw_lines):
        m = MARKER_RE.search(line)

        if not m:
            in_block = _advance_block_state(line, mstart, mend, in_block)
            continue

        marker_idx = m.start()
        marker_end = m.end()

        is_multi  = False
        is_single = False

        if in_block:
            is_multi = True
        elif has_multi:
            s_idx = line.find(mstart)
            e_idx = line.find(mend)
            if (s_idx >= 0 and s_idx < marker_idx and
                    (e_idx < 0 or e_idx > marker_idx)):
                is_multi = True

        if not is_multi and has_single:
            if line.lstrip().startswith(single):
                is_single = True

        if not (is_multi or is_single):
            in_block = _advance_block_state(line, mstart, mend, in_block)
            continue

        ret["found"] = True

        if is_multi:
            rest = line[marker_end:]

            # Block closes on the same line?
            end_pos = rest.find(mend)
            if end_pos >= 0:
                before = rest[:end_pos].strip()
                after  = rest[end_pos + len(mend):].strip()
                if before: result.append(before)
                if after:  result.append(after)
                ret["lines"] = result
                return ret
            else:
                rest_trim = rest.strip()
                if rest_trim:
                    result.append(rest_trim)

            # Subsequent lines until the block end-tag
            for j in range(i + 1, n):
                l       = raw_lines[j]
                end_pos = l.find(mend)
                if end_pos >= 0:
                    before       = l[:end_pos].lstrip()
                    before_clean = _strip_leading_stars(before).rstrip()
                    if before_clean:
                        result.append(before_clean)
                    after = l[end_pos + len(mend):].strip()
                    if after:
                        result.append(after)
                    break
                else:
                    cleaned = _strip_leading_stars(l.lstrip()).rstrip()
                    result.append(cleaned)

            ret["lines"] = result
            return ret

        if is_single:
            for j in range(i + 1, n):
                lt = raw_lines[j].lstrip()
                if lt.startswith(single):
                    stripped = lt[len(single):]
                    if stripped.startswith(" "):
                        stripped = stripped[1:]
                    result.append(stripped.rstrip())
                else:
                    break

            ret["lines"] = result
            return ret

    return ret

# ──────────────────────────────────────────────────────────────
# Render helpers
# ──────────────────────────────────────────────────────────────

def render_usage_from_file(filepath: str):
    info = get_usage_examples(filepath)

    if not info["file_exists"]:
        write_warn("  [!] File not found:")
        print(f"      {DARKYELLOW}{filepath}{RESET}")
        return
    if not info["found"]:
        write_warn("  [!] No 'example usage:' or 'usage examples:' marker found in:")
        print(f"      {DARKYELLOW}{filepath}{RESET}")
        return
    if not info["lines"]:
        write_warn("  [!] Marker found but no example content extracted from:")
        print(f"      {DARKYELLOW}{filepath}{RESET}")
        return

    for ln in info["lines"]:
        trimmed = ln.rstrip()
        if not ln.strip():
            print()
        elif trimmed.endswith(":"):
            write_label(ln)
        elif re.match(r'(?i)^note\s*:', trimmed.lstrip()):
            write_label(ln)
        elif not re.search(r'[A-Za-z]', trimmed):
            # no alphabetical chars (e.g. "---", "====") → treat as label
            write_label(ln)
        else:
            write_cmd(ln)

def _resolve_root(env_name: str) -> str | None:
    root = os.environ.get(env_name, "").strip()
    return root.rstrip("/\\") if root else None

def show_project(header: str, env_name: str, rel_path: str):
    write_header(header)
    root = _resolve_root(env_name)
    if not root:
        write_warn(f"  [!] Environment variable '${env_name}' is not set.")
        return
    filepath = os.path.join(root, *re.split(r'[/\\]', rel_path.lstrip("/\\")))
    render_usage_from_file(filepath)

def show_project_multi(header: str, env_name: str, rel_paths: list):
    write_header(header)
    root = _resolve_root(env_name)
    if not root:
        write_warn(f"  [!] Environment variable '${env_name}' is not set.")
        return
    for rel in rel_paths:
        filepath = os.path.join(root, *re.split(r'[/\\]', rel.lstrip("/\\")))
        leaf     = os.path.basename(filepath)
        write_subheader(leaf)
        render_usage_from_file(filepath)

# ──────────────────────────────────────────────────────────────
# Match rules  (same order as .sh / .ps1)
# ──────────────────────────────────────────────────────────────

def run():
    matched = False

    # ── code2 → go → my_web_wow ──────────────────────────────
    if path_contains_in_order("code2", "go", "my_web_wow"):
        show_project("Go (my_web_wow)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/go/my_web_wow/main.go")
        matched = True

    # ── code2 → go → tbc ─────────────────────────────────────
    elif path_contains_in_order("code2", "go", "tbc"):
        show_project("Go (tbc)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/go/tbc/main.go")
        matched = True

    # ── code2 → rust → my_web_wow ────────────────────────────
    elif path_contains_in_order("code2", "rust", "my_web_wow"):
        show_project("Rust (my_web_wow)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/rust/my_web_wow/src/main.rs")
        matched = True

    # ── code2 → rust → tbc ───────────────────────────────────
    elif path_contains_in_order("code2", "rust", "tbc"):
        show_project("Rust (tbc)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/rust/tbc/src/main.rs")
        matched = True

    # ── code2 → py → my_web_wow ──────────────────────────────
    elif path_contains_in_order("code2", "py", "my_web_wow"):
        show_project("Python (my_web_wow)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/python/my_web_wow/main.py")
        matched = True

    # ── code2 → py → tbc ─────────────────────────────────────
    elif path_contains_in_order("code2", "py", "tbc"):
        show_project("Python (tbc)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/python/tbc/main.py")
        matched = True

    # ── code2 → c# → my_web_wow ──────────────────────────────
    elif path_contains_in_order("code2", "c#", "my_web_wow"):
        show_project("C# (my_web_wow)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/c#/my_web_wow/my_web_wow/Program.cs")
        matched = True

    # ── code2 → c# → tbc ─────────────────────────────────────
    elif path_contains_in_order("code2", "c#", "tbc"):
        show_project("C# (tbc)", "code_root_dir",
                     "Code2/Wow/tools/my_wow/c#/tbc/tbc/Program.cs")
        matched = True

    # ── code2 → gfx → wc_testing_go  (before wc_testing) ────
    elif path_contains_in_order("code2", "gfx", "wc_testing_go"):
        show_project_multi("WC Testing (Go)", "code_root_dir", [
            "Code2/General/gfx/wc_testing_go/adt_app.go",
            "Code2/General/gfx/wc_testing_go/m2_app.go",
            "Code2/General/gfx/wc_testing_go/wdl_app.go",
            "Code2/General/gfx/wc_testing_go/wmo_app.go",
        ])
        matched = True

    # ── code2 → gfx → wc_testing_py  (before wc_testing) ────
    elif path_contains_in_order("code2", "gfx", "wc_testing_py"):
        show_project_multi("WC Testing (Python)", "code_root_dir", [
            "Code2/General/gfx/wc_testing_py/adt_app.py",
            "Code2/General/gfx/wc_testing_py/m2_app.py",
            "Code2/General/gfx/wc_testing_py/wdl_app.py",
            "Code2/General/gfx/wc_testing_py/wmo_app.py",
        ])
        matched = True

    # ── code2 → gfx → wc_testing_rs  (before wc_testing) ────
    elif path_contains_in_order("code2", "gfx", "wc_testing_rs"):
        show_project_multi("WC Testing (Rust)", "code_root_dir", [
            "Code2/General/gfx/wc_testing_rs/src/adt_app.rs",
            "Code2/General/gfx/wc_testing_rs/src/m2_app.rs",
            "Code2/General/gfx/wc_testing_rs/src/wdl_app.rs",
            "Code2/General/gfx/wc_testing_rs/src/wmo_app.rs",
        ])
        matched = True

    # ── code2 → gfx → wc_testing  (C#, plain name) ──────────
    elif path_contains_in_order("code2", "gfx", "wc_testing"):
        show_project_multi("WC Testing (C#)", "code_root_dir", [
            "Code2/General/gfx/wc_testing/AdtApp.cs",
            "Code2/General/gfx/wc_testing/M2App.cs",
            "Code2/General/gfx/wc_testing/WdlApp.cs",
            "Code2/General/gfx/wc_testing/WmoApp.cs",
        ])
        matched = True

    # ── code2 → webwowviewer  (prefer .ts, fall back to .js) ─
    elif path_contains_in_order("code2", "webwowviewer"):
        write_header("Web WoW Viewer (npm)")
        root = _resolve_root("code_root_dir")
        if not root:
            write_warn("  [!] Environment variable '$code_root_dir' is not set.")
        else:
            ts_path = os.path.join(root,
                "Code2", "Wow", "tools", "WebWoWViewer",
                "js", "application", "angular", "app_wow.ts")
            js_path = os.path.join(root,
                "Code2", "Wow", "tools", "WebWoWViewer",
                "js", "application", "angular", "app_wowjs.js")
            if os.path.isfile(ts_path):
                render_usage_from_file(ts_path)
            elif os.path.isfile(js_path):
                render_usage_from_file(js_path)
            else:
                write_warn("  [!] Neither of these files exist:")
                print(f"      {DARKYELLOW}{ts_path}{RESET}")
                print(f"      {DARKYELLOW}{js_path}{RESET}")
        matched = True

    # ── code2 → spelunker ────────────────────────────────────
    elif path_contains_in_order("code2", "spelunker"):
        write_header("Spelunker")
        write_label("setup:")
        if IS_LINUX:
            write_cmd("cd $HOME/Documents/my_notes/scripts/wow/spelunker")
            write_cmd("./setup.sh")
        else:
            write_cmd(r"cd $Env:my_notes_path/scripts/wow/spelunker")
            write_cmd("./setup.ps1")
        print()
        write_label("start wow mpq file server and do (in both spelunker-api and spelunker-web):")
        if IS_LINUX:
            write_cmd("source ../../.envrc && npm start")
        else:
            write_cmd(r"Push-Location; cd ..\..; .\load_env.ps1; Pop-Location; npm start")
        print()
        write_label("If needed for file server (if mounted) you might need:")
        write_extra("npm install express cors --no-bin-links")
        matched = True

    # ── code2 → azeroth-web-proxy  (before azeroth-web) ─────
    elif path_contains_in_order("code2", "azeroth-web-proxy"):
        write_header("Azeroth Web Proxy")
        write_cmd("npm start")
        print()
        write_label("Also run script in my_notes via:")
        if IS_LINUX:
            write_cmd("cd $HOME/Documents/my_notes/scripts/wow/azeroth-web")
            write_cmd("./setup.sh")
        else:
            write_cmd(r"cd $Env:my_notes_path/scripts/wow/azeroth-web")
            write_cmd("./setup.ps1")
        print()
        write_label("Also start either acore/tcore to be able to login!")
        matched = True

    # ── code2 → azeroth-web ───────────────────────────────────
    elif path_contains_in_order("code2", "azeroth-web"):
        write_header("Azeroth Web")
        write_cmd("npm install -g typescript")
        write_cmd("npm run dev")
        print()
        write_label("Also run script in my_notes via:")
        if IS_LINUX:
            write_cmd("cd $HOME/Documents/my_notes/scripts/wow/azeroth-web")
            write_cmd("./setup.sh")
        else:
            write_cmd(r"cd $Env:my_notes_path/scripts/wow/azeroth-web")
            write_cmd("./setup.ps1")
        print()
        write_label("Also start either acore/tcore to be able to login!")
        matched = True

    # ── code2 → wowser ───────────────────────────────────────
    elif path_contains_in_order("code2", "wowser"):
        write_header("Wowser")
        write_label("Run script in my_notes via:")
        if IS_LINUX:
            write_cmd("cd $HOME/Documents/my_notes/scripts/wow/wowser")
            write_cmd("./setup.sh")
        else:
            write_cmd(r"cd $Env:my_notes_path/scripts/wow/wowser")
            write_cmd("./setup.ps1")
        print()
        write_cmd("npm run serve")
        write_label("NOTE: specify wow client dir after running npm run serve!")
        write_label("you may need this if client dir is wrong:")
        write_alt("npm run reset")
        write_label("use:")
        write_extra("$Env:wow_dir" if IS_WINDOWS else "$wow_dir")
        print()
        write_label("then, in another shell:")
        write_cmd("npm run web-dev")
        matched = True

    # ── code2 → my_js → mysql ────────────────────────────────
    elif path_contains_in_order("code2", "my_js", "mysql"):
        show_project("my_js / MySQL", "code_root_dir",
                     "Code2/Javascript/my_js/Testing/mysql/main.js")
        matched = True

    # ── code2 → my_js → navigation → ffi-napi  (before nav) ─
    elif path_contains_in_order("code2", "my_js", "navigation", "ffi-napi"):
        show_project("my_js / Navigation (ffi-napi)", "code_root_dir",
                     "Code2/Javascript/my_js/Testing/navigation/ffi-napi/main.js")
        matched = True

    # ── code2 → my_js → navigation ───────────────────────────
    elif path_contains_in_order("code2", "my_js", "navigation"):
        show_project("my_js / Navigation", "code_root_dir",
                     "Code2/Javascript/my_js/Testing/navigation/main.js")
        matched = True

    # ── code2 → my_js → keybinds ─────────────────────────────
    elif path_contains_in_order("code2", "my_js", "keybinds"):
        write_header("my_js / Keybinds")
        write_label("do this:")
        write_cmd("npm run dev")
        print()
        write_alt("npm run start")
        matched = True

    # ── my_notes → orders_ts ─────────────────────────────────
    elif path_contains_in_order("my_notes", "orders_ts"):
        show_project("orders_ts", "my_notes_path",
                     "notes/svea/scripts/orders_ts/src/orders.ts")
        matched = True

    # ── my_notes → latest-orders-ts ──────────────────────────
    elif path_contains_in_order("my_notes", "latest-orders-ts"):
        show_project("latest-orders-ts", "my_notes_path",
                     "notes/svea/scripts/stats/latest-orders-ts/app/src/server.ts")
        matched = True

    # ── Fallback: inspect current directory ───────────────────
    else:
        files = set(os.listdir(".")) if os.path.isdir(".") else set()

        if "worldserver.exe" in files and "authserver.exe" in files:
            write_header("World Server")
            if IS_LINUX:
                write_cmd("python overwrite.py && ./worldserver.exe")
                print()
                write_label("Linux gdb:")
                write_alt("python overwrite.py && gdb -x gdb.conf --batch ./worldserver")
            else:
                write_cmd(r"python overwrite.py; .\worldserver.exe")
            matched = True

        elif "cors_server.js" in files and "cors_server.py" in files:
            write_header("CORS Server")
            write_cmd("node ./cors_server.js")
            write_alt("python ./cors_server.py")
            matched = True

    # ── No match ──────────────────────────────────────────────
    if not matched:
        print()
        write_warn("  [!] No build commands matched for:")
        print(f"      {DARKYELLOW}{CWD_FULL}{RESET}")
        print()

if __name__ == "__main__":
    run()
