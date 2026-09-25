#!/usr/bin/env python3
"""Live memory timecharts of the window manager and the status bar.

Called by `wm_mem.sh -p`, which also does the detection (`wm_mem.sh --pids`),
so the window manager and bar are found the same way as in its table.

Each process gets two charts side by side:
  left   RSS, PSS and anon memory in MiB, the absolute use
  right  the growth of RSS and anon since the start, zoomed in, where a
         leak shows up as a line that keeps climbing
The header gives the current values and the growth per hour. Rendered with
plotext in the gruvbox colours of proc_stats_linux.py (`proc.sh livetop`).

Colours, with the same limits as wm_mem.sh's table: green is fine, dark
yellow worth a look, red a likely problem. The header values, the axes of
each chart (the worst value in it) and the growth lines are coloured that
way; the growth chart also shows the warning/problem limits once the lines
get near them. The growth rate is only judged after 10 minutes.

USAGE:
  wm_mem_plot.py [--interval S] [--wm NAME|PID] [--bar NAME|PID|none]
                 [--history N] [--samples N]
"""

import argparse
import os
import shutil
import subprocess
import sys
import time
from collections import deque
from datetime import datetime

try:
    import plotext as plt
except ImportError:
    sys.exit("wm_mem_plot.py: plotext is not installed (pip install plotext)")

WM_MEM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wm_mem.sh")

# gruvbox dark, as in proc_stats_linux.py
BG = (40, 40, 40)
FG = (235, 219, 178)
# ── ANSI colors ─────────────────────────────────────────────────────────────
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
MAGENTA = "\033[35m"
DARKGRAY = "\033[90m"
RESET = "\033[0m"

# Levels: good, warn, bad, or None (not judged yet)
ANSI = {"good": GREEN, "warn": YELLOW, "bad": RED, None: ""}
# chart axes by level (gruvbox green, yellow, red)
AXIS = {"good": (184, 187, 38), "warn": (215, 153, 33), "bad": (251, 73, 52), None: FG}
# growth lines by level, a lighter and a darker shade so RSS and anon differ
LINE_RSS = {"good": (184, 187, 38), "warn": (250, 189, 47), "bad": (251, 73, 52), None: (184, 187, 38)}
LINE_ANON = {"good": (142, 192, 124), "warn": (254, 128, 25), "bad": (204, 36, 29), None: (142, 192, 124)}
# absolute memory lines: neutral colours, the axes carry the level
C_RSS = (131, 165, 152)   # blue
C_PSS = (168, 153, 132)   # gray
C_ANON = (211, 134, 155)  # purple
C_WARN, C_BAD = (215, 153, 33), (251, 73, 52)  # the limit lines

# Size classes, in MiB (keep in sync with wm_mem.sh): small C programs,
# desktop shells and compositors, and the rest in between
SMALL = {"dwmr", "dwm", "i3", "bspwm", "herbstluftwm", "openbox", "fluxbox", "spectrwm",
         "leftwm", "river", "dwmblocksr", "dwmblocks", "slstatus", "lemonbar", "i3status",
         "i3status-rs", "i3blocks", "somebar", "dzen2", "yambar"}
LARGE = {"gnome-shell", "kwin_x11", "kwin_wayland", "plasmashell", "Hyprland"}
RANK = {None: 0, "good": 1, "warn": 2, "bad": 3}


def level(v, good, warn):
    return "good" if v <= good else "warn" if v <= warn else "bad"


def size_limits(name):
    """Good and warning limits in MiB for the memory size of a process."""
    if name in SMALL:
        return 32, 96
    if name in LARGE:
        return 384, 1024
    return 128, 384


def growth_limits(start):
    """Growth since the start, in MiB: fine up to 2% of the size at the start
    (at least 0.5 MiB), a warning up to 10% (at least 2 MiB)."""
    return max(0.5, start * 0.02), max(2.0, start * 0.10)


def rate_level(rate, elapsed):
    """MiB/h: fine up to 0.25, a warning up to 2; not judged in the first 10
    minutes, when a few kB already make a large rate."""
    return None if elapsed < 600 else level(rate, 0.25, 2)


def worst(*levels):
    return max(levels, key=lambda lv: RANK[lv])


def read_kb(path, keys):
    """The "Key:  123 kB" values of a /proc file, in kB."""
    out = {}
    try:
        with open(path) as f:
            for line in f:
                k, _, rest = line.partition(":")
                if k in keys:
                    out[k] = int(rest.split()[0])
    except (OSError, ValueError, IndexError):
        pass
    return out


def sample(pid):
    """Memory of pid in MiB (rss, pss, anon), or None if it has exited."""
    st = read_kb(f"/proc/{pid}/status", {"VmRSS", "RssAnon"})
    if "VmRSS" not in st:
        return None
    sm = read_kb(f"/proc/{pid}/smaps_rollup", {"Pss"})
    return {
        "rss": st["VmRSS"] / 1024,
        "pss": sm.get("Pss", 0) / 1024,
        "anon": st.get("RssAnon", 0) / 1024,
    }


def detect(args):
    """{"wm": (pid, name), "bar": (pid, name)} from `wm_mem.sh --pids`."""
    cmd = [WM_MEM, "--pids"]
    if args.wm:
        cmd += ["-w", args.wm]
    if args.bar:
        cmd += ["-b", args.bar]
    found = {}
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return found
    for line in out.splitlines():
        parts = line.split(maxsplit=2)
        if len(parts) == 3 and parts[1].isdigit():
            found[parts[0]] = (int(parts[1]), parts[2])
    return found


class Target:
    """One watched process and its history."""

    def __init__(self, role, pid, name, history):
        self.role, self.pid, self.name = role, pid, name
        self.t = deque(maxlen=history)      # seconds since start
        self.v = deque(maxlen=history)      # sample dicts
        self.start = time.time()
        self.first = None                   # first sample, for the growth

    def add(self, now, s):
        if self.first is None:
            self.first = s
        self.t.append(now - self.start)
        self.v.append(s)

    def growth(self, key):
        if self.first is None:
            return 0.0
        return self.v[-1][key] - self.first[key]

    def per_hour(self, key):
        el = time.time() - self.start
        return self.growth(key) * 3600 / el if el > 0 else 0.0


def fmt_elapsed(s):
    s = int(s)
    return f"{s // 3600}h{s % 3600 // 60:02d}m" if s >= 3600 else f"{s // 60}m{s % 60:02d}s"


def xaxis(ts, interval):
    """The time axis: at least one interval wide (a single sample would give
    plotext an empty x range), with at most 6 ticks labelled like 2m30s."""
    lo, hi = ts[0], max(ts[-1], ts[0] + interval)
    plt.xlim(lo, hi)
    n = max(2, min(6, int(hi - lo) + 1))  # no two ticks on the same second
    pos = [lo + (hi - lo) * i / (n - 1) for i in range(n)]
    plt.xticks(pos, [fmt_elapsed(p) for p in pos])


def ylim(values, pad_min, floor=None):
    """Limits around the values, at least pad_min MiB high, so a flat line
    sits in the middle instead of on an edge, with room at the top for the
    legend and not below floor."""
    lo, hi = min(values), max(values)
    if hi - lo < pad_min:
        mid = (hi + lo) / 2
        lo, hi = mid - pad_min / 2, mid + pad_min / 2
    span = hi - lo
    lo, hi = lo - span * 0.1, hi + span * 0.45
    if floor is not None and lo < floor:
        lo = floor
    return lo, hi


def theme(lv):
    """gruvbox background, with the axes (and title) in the level's colour"""
    plt.canvas_color(BG)
    plt.axes_color(BG)
    plt.ticks_color(AXIS[lv])


def size_level(tg):
    good, warn = size_limits(tg.name)
    cur = tg.v[-1]
    return worst(*(level(cur[k], good, warn) for k in ("rss", "pss", "anon")))


def growth_level(tg):
    """The worst of the RSS/anon growth and, after 10 minutes, their rate."""
    good, warn = growth_limits(tg.first["rss"])
    el = time.time() - tg.start
    return {k: worst(level(tg.growth(k), good, warn), rate_level(tg.per_hour(k), el))
            for k in ("rss", "anon")}


def chart_abs(tg, interval):
    ts = list(tg.t)
    theme(size_level(tg))
    plt.title(f"{tg.name}: memory (MiB)")
    for key, label, color in (("rss", "RSS", C_RSS), ("pss", "PSS", C_PSS), ("anon", "anon", C_ANON)):
        plt.plot(ts, [v[key] for v in tg.v], label=label, color=color, marker="braille")
    allv = [v[k] for v in tg.v for k in ("rss", "pss", "anon")]
    plt.ylim(*ylim(allv + [0.0], 1.0, floor=0.0))
    xaxis(ts, interval)


def chart_growth(tg, interval):
    if tg.first is None:
        return
    ts = list(tg.t)
    lv = growth_level(tg)
    theme(worst(lv["rss"], lv["anon"]))
    plt.title(f"{tg.name}: growth since start (MiB)")
    rss = [v["rss"] - tg.first["rss"] for v in tg.v]
    anon = [v["anon"] - tg.first["anon"] for v in tg.v]
    plt.plot(ts, rss, label="RSS", color=LINE_RSS[lv["rss"]], marker="braille")
    plt.plot(ts, anon, label="anon", color=LINE_ANON[lv["anon"]], marker="braille")
    lo, hi = ylim(rss + anon + [0.0], 0.2)
    plt.ylim(lo, hi)
    # the warning and problem limits, once the lines get near them (drawing
    # them always would squash a flat line at 0)
    good, warn = growth_limits(tg.first["rss"])
    for limit, color in ((good, C_WARN), (warn, C_BAD)):
        if lo <= limit <= hi:
            plt.hline(limit, color)
    xaxis(ts, interval)


def header(targets, missing, interval):
    lines = [f"{CYAN}wm_mem -p{RESET}  every {interval}s  "
             f"{DARKGRAY}{datetime.now():%a %d %b %H:%M:%S}  (Ctrl-C to quit){RESET}   "
             f"{GREEN}fine{RESET} {YELLOW}worth a look{RESET} {RED}likely a problem{RESET}"]
    for tg in targets:
        cur = tg.v[-1]
        good, warn = size_limits(tg.name)
        ggood, gwarn = growth_limits(tg.first["rss"])
        el = time.time() - tg.start
        grow, rate = tg.growth("anon"), tg.per_hour("anon")

        def c(v, lv, fmt):
            return f"{ANSI[lv]}{v:{fmt}}{RESET}"

        lines.append(
            f"  {tg.role:>3} {MAGENTA}{tg.name:<12}{RESET} pid {tg.pid:<8}"
            f" RSS {c(cur['rss'], level(cur['rss'], good, warn), '7.2f')}"
            f"  PSS {c(cur['pss'], level(cur['pss'], good, warn), '7.2f')}"
            f"  anon {c(cur['anon'], level(cur['anon'], good, warn), '7.2f')} MiB"
            f"  anon {c(grow, level(grow, ggood, gwarn), '+.2f')} MiB"
            f" ({c(rate, rate_level(rate, el), '+.2f')}/h)"
            f"  {DARKGRAY}{fmt_elapsed(el)}{RESET}")
    for m in missing:
        lines.append(f"  {YELLOW}{m}{RESET}")
    return "\n".join(lines)


def render(targets, missing, interval):
    cols, rows = shutil.get_terminal_size((120, 40))
    head = header(targets, missing, interval)
    height = max(rows - head.count("\n") - 3, 10)
    # clear the whole figure: clear_figure() and clf() only clear the active
    # subplot, and a subplot's old data and limits would carry over
    plt.main()
    plt.clear_figure()
    if targets:
        plt.subplots(len(targets), 2)
        plt.plotsize(cols, height)  # the whole grid; before selecting a subplot
        for i, tg in enumerate(targets, 1):
            plt.subplot(i, 1)
            chart_abs(tg, interval)
            plt.subplot(i, 2)
            chart_growth(tg, interval)
        chart = plt.build()
    else:
        chart = ""
    # home + clear below instead of `clear`, so the screen doesn't flicker
    sys.stdout.write("\033[H\033[J" + head + "\n\n" + chart + "\n")
    sys.stdout.flush()


def main():
    ap = argparse.ArgumentParser(description=(__doc__ or "").split("\n")[0])
    ap.add_argument("--interval", "-i", type=float, default=5)
    ap.add_argument("--wm", "-w", help="window manager name or PID")
    ap.add_argument("--bar", "-b", help="bar name or PID, or none")
    ap.add_argument("--history", type=int, default=2000, help="samples kept per chart (default 2000)")
    ap.add_argument("--samples", type=int, default=0, help="stop after N samples (default: run until Ctrl-C)")
    args = ap.parse_args()
    if args.interval <= 0:
        ap.error("--interval must be positive")

    targets = {}   # role -> Target
    n = 0
    try:
        while True:
            # (re)detect when something is missing or has exited, e.g. after
            # a restart of the window manager or the bar
            if len(targets) < 2 or any(sample(tg.pid) is None for tg in targets.values()):
                found = detect(args)
                for role, (pid, name) in found.items():
                    tg = targets.get(role)
                    if tg is None or tg.pid != pid:
                        targets[role] = Target(role, pid, name, args.history)
                for role in list(targets):
                    if role not in found:
                        del targets[role]

            now = time.time()
            for tg in list(targets.values()):
                s = sample(tg.pid)
                if s is None:
                    del targets[tg.role]
                else:
                    tg.add(now, s)

            order = [targets[r] for r in ("wm", "bar") if r in targets]
            missing = []
            if "wm" not in targets:
                missing.append("no window manager found (try -w NAME|PID)")
            if "bar" not in targets and args.bar != "none":
                missing.append("no separate bar process found (awesome, somewm and qtile draw theirs "
                               "themselves; try -b NAME|PID)")
            render(order, missing, args.interval)

            n += 1
            if args.samples and n >= args.samples:
                break
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print()


if __name__ == "__main__":
    main()
