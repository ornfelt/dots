#!/usr/bin/env python3
"""
tmux_kill.py - pick one or more tmux sessions and kill them after confirming.

Lists every session in fzf with the same preview as tmux_sessions.py (info,
windows and the active pane's contents). Mark sessions with tab, press enter,
and confirm. The session you are running this from is killed last.

Keys in the picker:
    tab      mark / unmark a session (enter alone kills the highlighted one)
    ctrl-a   mark every session
    ctrl-/   toggle the preview
    esc      cancel

Usage examples:

open the picker:
tmux_kill.py

kill sessions by name without the picker (still asks to confirm):
tmux_kill.py 3 4 my_proj

skip the confirmation:
tmux_kill.py 3 4 -y

use the built-in Python picker instead of fzf:
tmux_kill.py --picker python
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys

# Shares the session listing, preview and print helpers with tmux_sessions.py.
sys.dont_write_bytecode = True   # no __pycache__ in my_scripts
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import tmux_sessions as ts  # noqa: E402

VERSION = "1.0.0"

PREVIEW_WINDOW   = ts.PREVIEW_WINDOW
FZF_OPTS         = ts.FZF_OPTS + ["--bind=ctrl-a:select-all"]


def c(name: str) -> str:
    """Color lookup at call time, so --no-color (which rewrites ts globals) applies."""
    return getattr(ts, name)


# ── Pickers ──────────────────────────────────────────────────────────────────
def pick_fzf(rows: list[tuple[str, str]], preview: bool) -> list[str]:
    header = "tab mark  ·  ctrl-a mark all  ·  enter kill  ·  ctrl-/ preview  ·  esc cancel"
    cmd = [ts.FZF_BIN, "--prompt", "kill > ", "--header", header, "--ansi", "--multi",
           "--delimiter", "\t", "--with-nth", "1", "--nth", "1"] + FZF_OPTS
    if preview:
        argv = [sys.executable, os.path.join(os.path.dirname(os.path.realpath(__file__)),
                                             "tmux_sessions.py"), "--preview"]
        if not c("RESET"):
            argv.append("--no-color")
        # {-1} must stay unquoted, fzf substitutes it with a quoted field itself.
        cmd += ["--preview", " ".join(argv) + " {-1}", "--preview-window", PREVIEW_WINDOW]
    proc = subprocess.run(cmd, input="\n".join(f"{d}\t{k}" for d, k in rows),
                          stdout=subprocess.PIPE, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        return []
    return [l.split("\t")[-1].strip() for l in proc.stdout.splitlines() if l.strip()]


def pick_python(rows: list[tuple[str, str]]) -> list[str]:
    """Built-in picker: numbers separated by spaces, a = all, q quits."""
    width = len(str(len(rows)))
    for i, (disp, _) in enumerate(rows, 1):
        print(f"  {c('CYAN')}{str(i).rjust(width)}{c('RESET')}) {disp}", file=sys.stderr)
    ts.note("numbers to kill (e.g. 1 3 4)   a = all   q = cancel")
    while True:
        try:
            print(f"{c('BOLD')}kill > {c('RESET')}", end="", file=sys.stderr, flush=True)
            raw = input().strip()
        except (EOFError, KeyboardInterrupt):
            ts.blank()
            return []
        if raw in ("q", "Q", ""):
            return []
        if raw in ("a", "A"):
            return [k for _, k in rows]
        picks = raw.replace(",", " ").split()
        if all(p.isdigit() and 1 <= int(p) <= len(rows) for p in picks):
            return list(dict.fromkeys(rows[int(p) - 1][1] for p in picks))
        ts.err(f"not a valid choice: {raw}")


# ── Actions ──────────────────────────────────────────────────────────────────
def confirm(names: list[str], current: str) -> bool:
    ts.blank()
    ts.head(f"about to kill {len(names)} session{'s' if len(names) != 1 else ''}:")
    for name in names:
        tag = f"  {c('MAGENTA')}(this session){c('RESET')}" if name == current else ""
        print(f"  {c('RED')}{ts.S_DOT}{c('RESET')} {c('BOLD')}{name}{c('RESET')}{tag}",
              file=sys.stderr)
    if current in names:
        ts.warn("the session you are in is included, it is killed last")
    try:
        print(f"{c('BOLD')}kill them? {c('RESET')}{c('DIM')}[y/N]{c('RESET')} ",
              end="", file=sys.stderr, flush=True)
        return input().strip().lower() in ("y", "yes")
    except (EOFError, KeyboardInterrupt):
        ts.blank()
        return False


def kill(names: list[str], current: str) -> int:
    # Killing the current session ends this script's pane, so it goes last.
    order = [n for n in names if n != current] + [n for n in names if n == current]
    failed = 0
    for name in order:
        if name == current:
            ts.info(f"killing the current session {c('BOLD')}{name}{c('RESET')}")
        proc = ts.tmux("kill-session", "-t", ts.target(name))
        if proc.returncode == 0:
            ts.ok(f"killed {c('BOLD')}{name}{c('RESET')}")
        else:
            ts.err(f"could not kill {c('BOLD')}{name}{c('RESET')}: {proc.stderr.strip()}")
            failed += 1
    left = len(ts.list_sessions())
    ts.note(f"{left} session{'s' if left != 1 else ''} left")
    return 1 if failed else 0


# ── CLI ──────────────────────────────────────────────────────────────────────
def parse_args(argv: list[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser(prog="tmux_kill.py",
                                 description="Pick tmux sessions and kill them after confirming.",
                                 epilog="keys: tab mark, ctrl-a mark all, enter kill, "
                                        "ctrl-/ toggle preview, esc cancel")
    ap.add_argument("names", nargs="*", help="session names to kill, skips the picker")
    ap.add_argument("-y", "--yes", action="store_true", help="don't ask for confirmation")
    ap.add_argument("--picker", choices=["fzf", "python", "auto"], default="auto",
                    help="which picker to use (default: fzf when installed)")
    ap.add_argument("--no-preview", dest="show_preview", action="store_false",
                    help="turn off the preview window")
    ap.add_argument("--no-color", action="store_true", help="disable ANSI colors")
    ap.add_argument("-V", "--version", action="store_true")
    return ap.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.no_color or os.environ.get("NO_COLOR"):
        ts.disable_colors()

    if args.version:
        print(f"tmux_kill.py {VERSION}")
        return 0

    if shutil.which(ts.TMUX_BIN) is None:
        ts.err(f"{ts.TMUX_BIN} is not installed")
        return 1

    sessions = ts.list_sessions()
    if not sessions:
        ts.info("no tmux sessions running, nothing to kill")
        return 0
    current = ts.current_session()

    if args.names:
        existing = {s["name"] for s in sessions}
        missing = [n for n in args.names if n not in existing]
        for name in missing:
            ts.warn(f"no session named {c('BOLD')}{name}{c('RESET')}")
        names = [n for n in dict.fromkeys(args.names) if n in existing]
        if not names:
            return 1
    else:
        ts.head(f"{len(sessions)} tmux session{'s' if len(sessions) != 1 else ''} running")
        picker = args.picker
        if picker == "auto":
            picker = "fzf" if ts.fzf_available() else "python"
        elif picker == "fzf" and not ts.fzf_available():
            ts.warn(f"{ts.FZF_BIN} not found, using the built-in picker")
            picker = "python"
        # Same rows as tmux_sessions.py, minus its "+ new session" entry.
        rows = [r for r in ts.build_rows(sessions) if r[1] != ts.NEW_KEY]
        names = pick_fzf(rows, args.show_preview) if picker == "fzf" else pick_python(rows)
        if not names:
            ts.warn("cancelled, nothing killed")
            return 130

    if not args.yes and not confirm(names, current):
        ts.warn("cancelled, nothing killed")
        return 130
    return kill(names, current)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        ts.blank()
        ts.warn("cancelled, nothing killed")
        sys.exit(130)
