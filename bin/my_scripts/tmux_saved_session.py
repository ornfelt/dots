#!/usr/bin/env python3
"""
tmux_saved_session.py - show the saved tmux-resurrect session (what prefix + .
restores): every session with its windows and the cwd of each pane.

By default it is shown as a dunst notification. Without dunst it tries any other
notification daemon (notify-send), then a tmux popup, then plain stdout. Over
ssh the notification is skipped, since it would show up on the remote machine.

Bound to prefix + S in ~/.tmux.conf (wezterm's leader + S sends that key when
tmux runs in the pane).

Usage examples:
show the last saved session (notification, popup or stdout):
tmux_saved_session.py

print it in the terminal:
tmux_saved_session.py -m print

a specific save file, or a resurrect dir (its "last" file):
tmux_saved_session.py ~/.local/share/tmux/resurrect/tmux_resurrect_20261114T132047.txt
tmux_saved_session.py --path ~/.local/share/tmux/resurrect

popup on a given tmux client (what the tmux binding does when dunst is missing):
tmux_saved_session.py -m popup --client /dev/pts/3

print the equivalent bash command instead of running:
tmux_saved_session.py --show-cmd
tmux_saved_session.py -m print --show-cmd
"""

from __future__ import annotations

import argparse
import datetime
import html
import os
import re
import shlex
import shutil
import subprocess
import sys

# ── Configuration ────────────────────────────────────────────────────────────
TMUX_BIN = os.environ.get("TMSAVED_TMUX", "tmux")
APP_NAME = "tmux-session"
NOTIFY_TITLE = "tmux saved session"
NOTIFY_ID = "7311"            # dunstify -r: a new notification replaces the old one
NOTIFY_TIMEOUT_MS = 15000
CHILD_TIMEOUT_S = 3           # a hung dbus / tmux never blocks the binding
POPUP_SIZE = "80%"
LAST_FILE = "last"
SHELLS = {"sh", "bash", "zsh", "fish", "dash", "ksh", "nu"}
RESURRECT_DIR_OPTION = "@resurrect-dir"
SAVE_NAME_RE = re.compile(r"tmux_resurrect_(\d{8}T\d{6})\.txt$")
SAVE_STAMP_FORMAT = "%Y%m%dT%H%M%S"
SHOWN_STAMP_FORMAT = "%Y-%m-%d %H:%M"
ACTIVE_MARK = "●"
BRANCH_MID = "├ "
BRANCH_LAST = "└ "
MODES = ("auto", "dunst", "notify", "popup", "print")

# Pango colours for the notification (gruvbox, like the tmux status line)
PANGO = {
    "session": "#83a598",
    "window": "#fabd2f",
    "active": "#8ec07c",
    "command": "#d3869b",
    "dim": "#928374",
}

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


def _enable_windows_ansi() -> bool:
    """Turn on virtual terminal processing so ANSI codes work in cmd/PowerShell."""
    if os.name != "nt":
        return True
    try:
        import ctypes

        kernel32 = ctypes.windll.kernel32
        handle = kernel32.GetStdHandle(-11)  # STD_OUTPUT_HANDLE
        mode = ctypes.c_uint32()
        if not kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
            return False
        return bool(kernel32.SetConsoleMode(handle, mode.value | 0x4))
    except Exception:
        return False


def write_ok(msg: str) -> None:
    print(f"{GREEN}{msg}{RESET}")


def write_err(msg: str) -> None:
    print(f"{RED}{msg}{RESET}", file=sys.stderr)


def write_warn(msg: str) -> None:
    print(f"{YELLOW}{msg}{RESET}", file=sys.stderr)


def write_info(msg: str) -> None:
    print(f"{CYAN}{msg}{RESET}")


# ── Save file ────────────────────────────────────────────────────────────────
def tmux_option(name: str) -> str:
    """A global tmux option, "" when tmux is not running or it is unset."""
    try:
        out = subprocess.run([TMUX_BIN, "show-option", "-gqv", name], capture_output=True,
                             text=True, timeout=CHILD_TIMEOUT_S)
        return out.stdout.strip() if out.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def resurrect_dir() -> str:
    """The dir tmux-resurrect saves into, worked out as its helpers.sh does."""
    home = os.path.expanduser("~")
    configured = tmux_option(RESURRECT_DIR_OPTION)
    if configured:
        return (configured.replace("$HOME", home).replace("$HOSTNAME", os.uname().nodename)
                .replace("~", home))
    legacy = os.path.join(home, ".tmux", "resurrect")
    if os.path.isdir(legacy):
        return legacy
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.join(home, ".local", "share")
    return os.path.join(data_home, "tmux", "resurrect")


def resolve_save_file(path: str | None) -> str:
    """The save file to show: the given file, the "last" file of a given dir, or
    the "last" file of the resurrect dir."""
    if path:
        path = os.path.expanduser(path)
        return os.path.join(path, LAST_FILE) if os.path.isdir(path) else path
    return os.path.join(resurrect_dir(), LAST_FILE)


def unescape_dir(field: str) -> str:
    """resurrect saves ":<dir>" with spaces escaped as "\\ "."""
    return field[1:].replace("\\ ", " ") if field.startswith(":") else field.replace("\\ ", " ")


def parse_save(path: str) -> dict:
    """Parses a resurrect save into {"sessions": [...], "client_session": ...}.
    A session is {"name", "windows": [{"index", "name", "active", "panes": [...]}]},
    a pane {"index", "dir", "active", "command"}."""
    sessions: dict[str, dict] = {}
    windows: dict[tuple[str, str], dict] = {}
    client_session = ""

    def window_for(session: str, index: str) -> dict:
        if session not in sessions:
            sessions[session] = {"name": session, "windows": []}
        key = (session, index)
        if key not in windows:
            windows[key] = {"index": index, "name": "", "active": False, "panes": []}
            sessions[session]["windows"].append(windows[key])
        return windows[key]

    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            fields = line.rstrip("\n").split("\t")
            kind = fields[0]
            if kind == "pane" and len(fields) >= 10:
                # Newer saves have the pane title as field 6 (11 fields), older ones not
                offset = 1 if len(fields) >= 11 else 0
                window = window_for(fields[1], fields[2])
                window["active"] = window["active"] or fields[3] == "1"
                full_command = fields[9 + offset][1:] if len(fields) > 9 + offset else ""
                command = full_command or fields[8 + offset]
                window["panes"].append({
                    "index": fields[5],
                    "dir": unescape_dir(fields[6 + offset]),
                    "active": fields[7 + offset] == "1",
                    "command": "" if command in SHELLS else command,
                })
            elif kind == "window" and len(fields) >= 5:
                window = window_for(fields[1], fields[2])
                window["name"] = fields[3][1:] if fields[3].startswith(":") else fields[3]
                window["active"] = fields[4] == "1"
            elif kind == "state" and len(fields) >= 2:
                client_session = fields[1]

    for session in sessions.values():
        session["windows"].sort(key=lambda w: int(w["index"]) if w["index"].isdigit() else 0)
        for window in session["windows"]:
            window["panes"].sort(key=lambda p: int(p["index"]) if p["index"].isdigit() else 0)
    return {"sessions": list(sessions.values()), "client_session": client_session}


def saved_at(path: str) -> str:
    """When the save was made: from the file name, else the file's mtime."""
    real = os.path.realpath(path)
    match = SAVE_NAME_RE.search(real)
    try:
        if match:
            stamp = datetime.datetime.strptime(match.group(1), SAVE_STAMP_FORMAT)
        else:
            stamp = datetime.datetime.fromtimestamp(os.path.getmtime(real))
        return stamp.strftime(SHOWN_STAMP_FORMAT)
    except (OSError, ValueError):
        return "?"


def tilde(path: str) -> str:
    home = os.path.expanduser("~")
    if path == home or path.startswith(home + os.sep):
        return "~" + path[len(home):]
    return path


# ── Rendering ────────────────────────────────────────────────────────────────
def plural(count: int, word: str) -> str:
    return f"{count} {word}" if count == 1 else f"{count} {word}s"


def rows(save: dict) -> list[dict]:
    """The save as display rows: a session, its windows, each window's panes."""
    out = []
    for session in save["sessions"]:
        pane_count = sum(len(w["panes"]) for w in session["windows"])
        out.append({
            "kind": "session",
            "text": f"session {session['name']}",
            "extra": f"{plural(len(session['windows']), 'window')}, {plural(pane_count, 'pane')}",
            "active": session["name"] == save["client_session"] and len(save["sessions"]) > 1,
        })
        for window in session["windows"]:
            out.append({"kind": "window", "text": f"{window['index']} {window['name']}",
                        "active": window["active"]})
            for i, pane in enumerate(window["panes"]):
                out.append({
                    "kind": "pane",
                    "branch": BRANCH_LAST if i == len(window["panes"]) - 1 else BRANCH_MID,
                    "text": tilde(pane["dir"]),
                    "command": pane["command"],
                    # Only worth marking when the window has more than one pane
                    "active": pane["active"] and len(window["panes"]) > 1,
                })
    return out


def render_markup(save: dict, path: str) -> str:
    """The notification body in Pango markup (dunst is set to markup = full)."""
    def span(color: str, text: str) -> str:
        return f'<span foreground="{PANGO[color]}">{text}</span>'

    esc = html.escape
    lines = [span("dim", esc(f"saved {saved_at(path)}"))]
    for row in rows(save):
        if row["kind"] == "session":
            line = span("session", f"<b>{esc(row['text'])}</b>") + " " + span("dim", esc(row["extra"]))
        elif row["kind"] == "window":
            line = " " + span("window", f"<b>{esc(row['text'])}</b>")
        else:
            line = "   " + span("dim", row["branch"]) + esc(row["text"])
            if row["command"]:
                line += " " + span("command", esc(f"[{row['command']}]"))
        if row["active"]:
            line += " " + span("active", ACTIVE_MARK)
        lines.append(line)
    lines.append(span("dim", esc(tilde(os.path.realpath(path)))))
    return "\n".join(lines)


def render_text(save: dict, path: str, color: bool) -> str:
    """The same tree for a terminal, ANSI coloured when `color`."""
    def c(code: str, text: str) -> str:
        return f"{code}{text}{RESET}" if color else text

    lines = [c(BOLD, NOTIFY_TITLE) + " " + c(DIM, f"(saved {saved_at(path)})"),
             c(DIM, os.path.realpath(path)), ""]
    for row in rows(save):
        if row["kind"] == "session":
            if len(lines) > 3:
                lines.append("")
            line = c(BOLD + BLUE, row["text"]) + " " + c(DIM, f"({row['extra']})")
        elif row["kind"] == "window":
            line = "  " + c(BOLD + YELLOW, row["text"])
        else:
            line = "    " + c(DIM, row["branch"]) + row["text"]
            if row["command"]:
                line += " " + c(MAGENTA, f"[{row['command']}]")
        if row["active"]:
            line += " " + c(GREEN, ACTIVE_MARK)
        lines.append(line)
    return "\n".join(lines)


# ── Output ───────────────────────────────────────────────────────────────────
def run_quiet(cmd: list[str]) -> bool:
    try:
        return subprocess.run(cmd, capture_output=True, timeout=CHILD_TIMEOUT_S).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def dunst_cmd(body: str) -> list[str]:
    return ["dunstify", "-a", APP_NAME, "-r", NOTIFY_ID, "-t", str(NOTIFY_TIMEOUT_MS),
            NOTIFY_TITLE, body]


def notify_send_cmd(body: str) -> list[str]:
    return ["notify-send", "-a", APP_NAME, "-t", str(NOTIFY_TIMEOUT_MS), NOTIFY_TITLE, body]


def popup_cmd(path: str, client: str | None) -> list[str]:
    """A tmux popup paging the coloured tree (q closes it)."""
    inner = (f"{shlex.quote(sys.executable)} {shlex.quote(os.path.abspath(__file__))} "
             f"-m print --color always {shlex.quote(path)} | less -R")
    cmd = [TMUX_BIN, "display-popup", "-E", "-w", POPUP_SIZE, "-h", POPUP_SIZE,
           "-T", f" {NOTIFY_TITLE} "]
    if client:
        cmd += ["-c", client]
    return cmd + [inner]


def over_ssh() -> bool:
    return bool(os.environ.get("SSH_CONNECTION") or os.environ.get("SSH_TTY"))


def in_tmux(client: str | None) -> bool:
    return bool(client or os.environ.get("TMUX"))


def show(mode: str, save: dict, path: str, client: str | None, color: bool) -> int:
    if mode == "print":
        print(render_text(save, path, color))
        return 0

    tried = []
    if mode in ("auto", "dunst") and not (mode == "auto" and over_ssh()):
        if shutil.which("dunstify") and run_quiet(dunst_cmd(render_markup(save, path))):
            return 0
        tried.append("dunstify")
    if mode in ("auto", "notify") and not (mode == "auto" and over_ssh()):
        if shutil.which("notify-send") and run_quiet(notify_send_cmd(render_markup(save, path))):
            return 0
        tried.append("notify-send")
    if mode in ("auto", "popup") and in_tmux(client):
        # Not run_quiet: the popup stays open until it is closed
        try:
            if subprocess.run(popup_cmd(path, client), capture_output=True).returncode == 0:
                return 0
        except OSError:
            pass
        tried.append("tmux popup")
    if mode != "auto":
        write_err(f"Could not show the session via {', '.join(tried) or mode}.")
        return 1
    print(render_text(save, path, color))
    return 0


def show_cmd(mode: str, path: str, client: str | None, invocation: str) -> str:
    """A bash command doing what this run does: an awk pass over the save file
    building the tree, then the notification / popup / plain print."""
    awk = r"""awk -F'\t' -v home="$HOME" '
  function tilde(p) { return index(p, home) == 1 ? "~" substr(p, length(home) + 1) : p }
  $1 == "window" { name[$2 FS $3] = substr($4, 2); wact[$2 FS $3] = $5 }
  $1 == "pane" {
    off = NF >= 11 ? 1 : 0; key = $2 FS $3
    if (!(key in seen)) { seen[key] = 1; order[++n] = key }
    dir = substr($(7 + off), 2); gsub(/\\ /, " ", dir)
    cmd = $(9 + off) ~ /^(sh|bash|zsh|fish|dash|ksh|nu)$/ ? "" : " [" $(9 + off) "]"
    panes[key] = panes[key] "    " tilde(dir) cmd ($(8 + off) == 1 ? " *" : "") "\n"
  }
  END {
    for (i = 1; i <= n; i++) {
      split(order[i], k, FS)
      if (i == 1 || k[1] != last) { print "session " k[1]; last = k[1] }
      printf "  %s %s%s\n%s", k[2], name[order[i]], (wact[order[i]] == 1 ? " *" : ""), panes[order[i]]
    }
  }'"""
    lines = [f"# {invocation}", f"f=$(readlink -f {shlex.quote(path)})"]
    if mode == "print":
        lines.append(f'{awk} "$f"')
    elif mode == "popup":
        popup = [TMUX_BIN, "display-popup", "-E", "-w", POPUP_SIZE, "-h", POPUP_SIZE,
                 "-T", f" {NOTIFY_TITLE} "] + (["-c", client] if client else [])
        lines.append(f"body=$({awk} \"$f\")")
        lines.append(" ".join(shlex.quote(a) for a in popup)
                     + ' "printf \'%s\\n\' \\"$body\\" | less"')
    else:
        lines.append(f"body=$({awk} \"$f\")")
        dunst = " ".join(shlex.quote(a) for a in dunst_cmd("BODY")[:-1]) + ' "$body"'
        notify = " ".join(shlex.quote(a) for a in notify_send_cmd("BODY")[:-1]) + ' "$body"'
        if mode == "dunst":
            lines.append(dunst)
        elif mode == "notify":
            lines.append(notify)
        else:
            lines.append(f"{dunst} || {notify} || printf '%s\\n' \"$body\"")
    return "\n".join(lines)


def main() -> int:
    _enable_windows_ansi()
    parser = argparse.ArgumentParser(
        description="Show the saved tmux-resurrect session (sessions, windows, pane cwds).",
        formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    parser.add_argument("file", nargs="?", help="save file or resurrect dir (default: the resurrect dir's last file)")
    parser.add_argument("-p", "--path", dest="path_opt", help="same as the positional file")
    parser.add_argument("-m", "--mode", choices=MODES, default="auto",
                        help="auto: dunst, notify-send, tmux popup, stdout (default: %(default)s)")
    parser.add_argument("-c", "--client", help="tmux client for the popup (#{client_name})")
    parser.add_argument("--color", choices=("auto", "always", "never"), default="auto",
                        help="ANSI colours for print (default: %(default)s)")
    parser.add_argument("--show-cmd", action="store_true",
                        help="print the equivalent bash command instead of running")
    args = parser.parse_args()

    path = resolve_save_file(args.path_opt or args.file)
    color = args.color == "always" or (args.color == "auto" and sys.stdout.isatty())

    if args.show_cmd:
        print(show_cmd(args.mode, path, args.client, shlex.join(sys.argv)))
        return 0

    if not os.path.exists(path):
        msg = f"No saved tmux session: {path}"
        write_err(msg)
        if in_tmux(args.client):
            run_quiet([TMUX_BIN, "display-message"] + (["-c", args.client] if args.client else []) + [msg])
        return 1

    save = parse_save(path)
    if not save["sessions"]:
        write_warn(f"No panes in {path}")
        return 1
    return show(args.mode, save, path, args.client, color)


if __name__ == "__main__":
    sys.exit(main())
