#!/usr/bin/env python3
"""
tmux_sessions.py - pick a tmux session to attach to, or start a new one.

With no tmux sessions running this just runs `tmux` (a new default session).
Otherwise it lists every session in fzf with a preview (info, windows and the
active pane's contents) and attaches to the picked one. Inside tmux it
switches the current client instead of nesting.

Keys in the picker:
    enter    attach to the session (or create one on "+ new session")
    ctrl-n   new named session: the typed query is the name, or you are asked
    ctrl-/   toggle the preview
    esc      cancel

Usage examples:

open the picker (or start tmux when nothing is running):
tmux_sessions.py

print the sessions instead of picking:
tmux_sessions.py -l

turn off the preview window:
tmux_sessions.py --no-preview

use the built-in Python picker instead of fzf:
tmux_sessions.py --picker python
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import time

VERSION = "1.0.0"

# ── Configuration ────────────────────────────────────────────────────────────
TMUX_BIN         = os.environ.get("TMSESS_TMUX", "tmux")
FZF_BIN          = os.environ.get("TMSESS_FZF", "fzf")
PREVIEW_WINDOW   = "right,60%,border-left"
FZF_OPTS         = ["--height=90%", "--reverse", "--border", "--info=inline", "--cycle",
                    "--bind=ctrl-/:toggle-preview,ctrl-u:preview-half-page-up,"
                    "ctrl-d:preview-half-page-down"]
NAME_COL         = 16       # width of the session name column in the list
PREVIEW_PANE     = 40       # max pane lines in the preview (fewer if it doesn't fit)
NEW_KEY          = ":new"   # row key for "+ new session"; ':' can't be in a session name

# ── ANSI colors ──────────────────────────────────────────────────────────────
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
DIM = "\033[2m"
BOLD = "\033[1m"
RESET = "\033[0m"


def disable_colors() -> None:
    globals().update(RED="", GREEN="", YELLOW="", BLUE="", MAGENTA="", CYAN="",
                     DIM="", BOLD="", RESET="")


def _unicode_ok() -> bool:
    enc = (getattr(sys.stderr, "encoding", "") or "").lower()
    return "utf" in enc


# Symbols degrade to ASCII on a non-UTF-8 console (e.g. a bare Linux TTY).
_U = _unicode_ok()
S_OK, S_ERR, S_WARN, S_INFO, S_ARROW, S_DOT = (
    ("✔", "✘", "!", "i", "▸", "•") if _U else ("+", "x", "!", "i", ">", "-")
)

# All chatter goes to stderr so that `tmux_sessions.py -l > list.txt` stays clean.
def ok(msg: str) -> None:    print(f"{GREEN}{S_OK}{RESET} {msg}", file=sys.stderr)
def err(msg: str) -> None:   print(f"{RED}{S_ERR}{RESET} {msg}", file=sys.stderr)
def warn(msg: str) -> None:  print(f"{YELLOW}{S_WARN}{RESET} {msg}", file=sys.stderr)
def info(msg: str) -> None:  print(f"{BLUE}{S_INFO}{RESET} {msg}", file=sys.stderr)
def note(msg: str) -> None:  print(f"{DIM}  {msg}{RESET}", file=sys.stderr)
def head(msg: str) -> None:  print(f"{BOLD}{CYAN}{S_ARROW} {msg}{RESET}", file=sys.stderr)
def blank() -> None:         print("", file=sys.stderr)


# ── Helpers ──────────────────────────────────────────────────────────────────
def tmux(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([TMUX_BIN, *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          encoding="utf-8", errors="replace")


def age_of(epoch: float) -> str:
    secs = max(0, int(time.time() - epoch))
    for unit, size in (("d", 86400), ("h", 3600), ("m", 60)):
        if secs >= size:
            return f"{secs // size}{unit} ago"
    return "just now"


def short_path(path: str) -> str:
    home = os.path.expanduser("~")
    if path == home or path.startswith(home + os.sep):
        return "~" + path[len(home):]
    return path


def target(name: str) -> str:
    """'=' makes tmux match the session name exactly instead of by prefix."""
    return f"={name}"


def inside_tmux() -> bool:
    return bool(os.environ.get("TMUX"))


# ── Sessions ─────────────────────────────────────────────────────────────────
SESSION_FMT = "\t".join(["#{session_name}", "#{session_windows}", "#{session_attached}",
                         "#{session_created}", "#{session_activity}", "#{session_path}"])


def list_sessions() -> list[dict]:
    """Every session, most recently active first. No server means no sessions."""
    proc = tmux("list-sessions", "-F", SESSION_FMT)
    if proc.returncode != 0:
        return []
    sessions = []
    for line in proc.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) < 6:
            continue
        name, windows, attached, created, activity, path = parts[:6]
        sessions.append({
            "name": name,
            "windows": int(windows or 0),
            "attached": int(attached or 0),
            "created": float(created or 0),
            "activity": float(activity or 0),
            "path": path,
        })
    sessions.sort(key=lambda s: s["activity"], reverse=True)
    return sessions


def current_session() -> str:
    if not inside_tmux():
        return ""
    proc = tmux("display-message", "-p", "#{session_name}")
    return proc.stdout.strip() if proc.returncode == 0 else ""


def row_text(s: dict, current: str) -> str:
    name = s["name"] if len(s["name"]) <= NAME_COL else s["name"][:NAME_COL - 1] + "…"
    mark = (f"{MAGENTA}{S_DOT} current {RESET}" if s["name"] == current
            else f"{GREEN}{S_DOT} attached{RESET}" if s["attached"]
            else f"{DIM}  detached{RESET}")
    win = f"{s['windows']} win"
    return (f"{BOLD}{name.ljust(NAME_COL)}{RESET} {win:>6}  {mark}  "
            f"{DIM}{age_of(s['activity']):>9}{RESET}  {CYAN}{short_path(s['path'])}{RESET}")


def build_rows(sessions: list[dict]) -> list[tuple[str, str]]:
    """(display, key) pairs; the key is the session name or NEW_KEY."""
    current = current_session()
    rows = [(f"{GREEN}+ new session{RESET}", NEW_KEY)]
    rows += [(row_text(s, current), s["name"]) for s in sessions]
    return rows


# ── Preview ──────────────────────────────────────────────────────────────────
def render_new_preview() -> str:
    return "\n".join([
        f"{BOLD}{GREEN}+ new session{RESET}",
        "",
        f"  {CYAN}enter{RESET}   start a new session with the default name",
        f"  {CYAN}ctrl-n{RESET}  start a new session named after the query,",
        f"          or asks for a name when the query is empty",
        "",
        f"{DIM}  ctrl-n works on any row, not only this one.{RESET}",
    ])


def render_preview(name: str) -> str:
    if name == NEW_KEY:
        return render_new_preview()
    s = next((s for s in list_sessions() if s["name"] == name), None)
    if s is None:
        return f"{RED}session '{name}' no longer exists{RESET}"
    out = []
    add = out.append
    created = time.strftime("%Y-%m-%d %H:%M", time.localtime(s["created"]))
    add(f"{BOLD}{CYAN}{S_ARROW} {s['name']}{RESET}")
    add(f"  {DIM}created{RESET}  {created} ({age_of(s['created'])})")
    add(f"  {DIM}active {RESET}  {age_of(s['activity'])}")
    add(f"  {DIM}clients{RESET}  {s['attached']}")
    add(f"  {DIM}path   {RESET}  {short_path(s['path'])}")
    add("")

    fmt = "\t".join(["#{window_index}", "#{window_name}", "#{window_active}",
                     "#{window_panes}", "#{pane_current_command}", "#{pane_current_path}"])
    proc = tmux("list-windows", "-t", target(name), "-F", fmt)
    add(f"{BOLD}windows{RESET}")
    for line in proc.stdout.splitlines():
        idx, wname, active, panes, cmd, path = (line.split("\t") + [""] * 6)[:6]
        star = f"{YELLOW}*{RESET}" if active == "1" else " "
        pane_note = f" {DIM}[{panes} panes]{RESET}" if panes not in ("", "1") else ""
        add(f" {star}{idx:>2}: {BOLD}{wname}{RESET}{pane_note}  {MAGENTA}{cmd}{RESET}"
            f"  {DIM}{short_path(path)}{RESET}")
    add("")

    # Active pane of the active window, trimmed to what fits under the header.
    add(f"{BOLD}active pane{RESET} {DIM}{'─' * 30 if _U else '-' * 30}{RESET}")
    cap = tmux("capture-pane", "-p", "-e", "-J", "-t", f"{target(name)}:")
    lines = cap.stdout.rstrip("\n").splitlines()
    while lines and not lines[-1].strip():
        lines.pop()
    room = int(os.environ.get("FZF_PREVIEW_LINES", "0") or 0) - len(out)
    keep = min(PREVIEW_PANE, room) if room > 0 else PREVIEW_PANE
    out += [l + RESET for l in lines[-keep:]]
    return "\n".join(out)


# ── Pickers ──────────────────────────────────────────────────────────────────
def fzf_available() -> bool:
    return shutil.which(FZF_BIN) is not None


def pick_fzf(rows: list[tuple[str, str]], preview: bool) -> tuple[str, str, str]:
    """Returns (key pressed, picked session key, typed query)."""
    header = "enter attach  ·  ctrl-n new named session  ·  ctrl-/ preview  ·  esc cancel"
    cmd = [FZF_BIN, "--prompt", "tmux > ", "--header", header, "--ansi", "--no-multi",
           "--delimiter", "\t", "--with-nth", "1", "--nth", "1",
           "--print-query", "--expect", "ctrl-n"] + FZF_OPTS
    if preview:
        argv = [sys.executable, os.path.abspath(__file__), "--preview"]
        if not RESET:
            argv.append("--no-color")
        # {-1} must stay unquoted, fzf substitutes it with a quoted field itself.
        cmd += ["--preview", " ".join(argv) + " {-1}", "--preview-window", PREVIEW_WINDOW]
    proc = subprocess.run(cmd, input="\n".join(f"{d}\t{k}" for d, k in rows),
                          stdout=subprocess.PIPE, encoding="utf-8", errors="replace")
    lines = proc.stdout.split("\n")
    query = lines[0] if lines else ""
    key = lines[1] if len(lines) > 1 else ""
    picked = lines[2].split("\t")[-1].strip() if len(lines) > 2 and lines[2] else ""
    # 1 = no match (fine for ctrl-n with a fresh name), 130 = esc / ctrl-c.
    if proc.returncode not in (0, 1):
        return "", "", ""
    return key, picked, query


def pick_python(rows: list[tuple[str, str]]) -> tuple[str, str, str]:
    """Built-in picker: a number picks, n = new session, n <name> = named, q quits."""
    width = len(str(len(rows) - 1))
    for i, (disp, _) in enumerate(rows):
        print(f"  {CYAN}{str(i).rjust(width)}{RESET}) {disp}", file=sys.stderr)
    note("number = attach   0 = new session   n <name> = new named session   q = cancel")
    while True:
        try:
            print(f"{BOLD}tmux > {RESET}", end="", file=sys.stderr, flush=True)
            raw = input().strip()
        except (EOFError, KeyboardInterrupt):
            blank()
            return "", "", ""
        if raw in ("q", "Q", ""):
            return "", "", ""
        if raw == "n" or raw.startswith("n "):
            return "ctrl-n", "", raw[2:].strip()
        if raw.isdigit() and int(raw) < len(rows):
            return "", rows[int(raw)][1], ""
        err(f"not a choice: {raw}")


# ── Actions ──────────────────────────────────────────────────────────────────
def run_tmux(args: list[str]) -> int:
    """Replace this process with tmux when attaching, run it otherwise."""
    if inside_tmux():
        return subprocess.call([TMUX_BIN, *args])
    os.execvp(TMUX_BIN, [TMUX_BIN, *args])
    return 0  # unreachable


def attach(name: str) -> int:
    if inside_tmux():
        info(f"switching to {BOLD}{name}{RESET}")
        return run_tmux(["switch-client", "-t", target(name)])
    info(f"attaching to {BOLD}{name}{RESET}")
    return run_tmux(["attach-session", "-t", target(name)])


def ask_name() -> str | None:
    try:
        print(f"{BOLD}session name{RESET} {DIM}(empty = default){RESET}: ",
              end="", file=sys.stderr, flush=True)
        return input().strip()
    except (EOFError, KeyboardInterrupt):
        blank()
        return None


def new_session(name: str = "") -> int:
    if name:
        clean = name.replace(".", "_").replace(":", "_")
        if clean != name:
            warn(f"tmux doesn't allow '.' or ':' in names, using {BOLD}{clean}{RESET}")
            name = clean
        if tmux("has-session", "-t", target(name)).returncode == 0:
            warn(f"session {BOLD}{name}{RESET} already exists")
            return attach(name)
    label = name or "default name"
    if inside_tmux():
        # Can't attach from inside tmux: create it detached, then switch to it.
        argv = ["new-session", "-d", "-P", "-F", "#{session_name}"] + (["-s", name] if name else [])
        proc = tmux(*argv)
        if proc.returncode != 0:
            err(f"could not create session: {proc.stderr.strip()}")
            return 1
        created = proc.stdout.strip()
        ok(f"created session {BOLD}{created}{RESET}")
        return attach(created)
    ok(f"starting new session ({label})")
    return run_tmux(["new-session"] + (["-s", name] if name else []))


def print_list(sessions: list[dict]) -> None:
    current = current_session()
    for s in sessions:
        print(row_text(s, current))


# ── CLI ──────────────────────────────────────────────────────────────────────
def parse_args(argv: list[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser(prog="tmux_sessions.py",
                                 description="Pick a tmux session to attach to, or start a new one.",
                                 epilog="keys: enter attach, ctrl-n new named session, "
                                        "ctrl-/ toggle preview, esc cancel")
    ap.add_argument("-l", "--list", action="store_true", help="print the sessions and exit")
    ap.add_argument("--picker", choices=["fzf", "python", "auto"], default="auto",
                    help="which picker to use (default: fzf when installed)")
    ap.add_argument("--no-preview", dest="show_preview", action="store_false",
                    help="turn off the preview window")
    ap.add_argument("--no-color", action="store_true", help="disable ANSI colors")
    ap.add_argument("-V", "--version", action="store_true")
    # The preview re-invokes this script; this is internal.
    ap.add_argument("--preview", dest="preview_name", default=None, help=argparse.SUPPRESS)
    return ap.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.no_color or os.environ.get("NO_COLOR"):
        disable_colors()

    if args.version:
        print(f"tmux_sessions.py {VERSION}")
        return 0

    # Preview mode: called by fzf for one row.
    if args.preview_name is not None:
        try:
            print(render_preview(args.preview_name))
        except Exception as exc:                     # never let a preview kill fzf
            print(f"{RED}preview failed: {exc}{RESET}")
        return 0

    if shutil.which(TMUX_BIN) is None:
        err(f"{TMUX_BIN} is not installed")
        return 1

    sessions = list_sessions()
    if args.list:
        print_list(sessions)
        return 0

    if not sessions:
        info("no tmux sessions running")
        return new_session()

    head(f"{len(sessions)} tmux session{'s' if len(sessions) != 1 else ''} running")
    picker = args.picker
    if picker == "auto":
        picker = "fzf" if fzf_available() else "python"
    elif picker == "fzf" and not fzf_available():
        warn(f"{FZF_BIN} not found, using the built-in picker")
        picker = "python"

    rows = build_rows(sessions)
    if picker == "fzf":
        key, picked, query = pick_fzf(rows, args.show_preview)
    else:
        key, picked, query = pick_python(rows)

    if key == "ctrl-n":
        name = query.strip()
        if not name:
            name = ask_name()
            if name is None:
                warn("cancelled")
                return 130
        return new_session(name)
    if not picked:
        warn("cancelled")
        return 130
    if picked == NEW_KEY:
        return new_session()
    return attach(picked)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        blank()
        warn("cancelled")
        sys.exit(130)
