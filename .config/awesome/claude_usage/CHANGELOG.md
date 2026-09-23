# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed
- Notifications fall back to `naughty.notify` on awesome 4.3 stable; the README now states that
  stable 4.3 is untested.
- The bar text shows every per-model limit by default (`bar_windows` gains the entry `"scoped"`),
  abbreviated to the model's first letter: "5h 23% · 7d 53% · F 100%".
- While extra usage is consumed the bar shows the amount ("+3.53€") instead of a bare " $";
  set `spend_flag = " $"` for the old marker.

### Fixed
- A used-up window showed "at this pace empty in expired" in the popup; it now says "limit reached".

## [0.5.3] - 2026-09-23

### Fixed
- The per-model weekly limits (e.g. "Fable"), the weekly breakdown and the spend disappeared while a
  session was running: the fresh statusLine cache replaced every API call. The API is now asked at
  least every `interval_idle` regardless of the cache, and a statusLine state keeps those details
  from the last API answer within the same weekly cycle.

## [0.5.2] - 2026-09-23

### Fixed
- A window missing from the statusLine `rate_limits` (Claude Code drops it after its reset) now
  counts as 0 % "no usage yet" instead of showing `5h --`.
- The graphical popup shows the active session's context line (it was only in the text variant).

### Changed
- Popup default width 340 px, shorter source names ("via statusLine just now").
- Screenshots with nine hours of real history.

## [0.5.1] - 2026-09-22

### Fixed
- `toggle_popup()` places the popup next to the widget instead of the screen centre; the widget
  derives its own position from the wibox hierarchy (`geometry_hint()`).

## [0.5.0] - 2026-09-22

### Added
- Active session context window in the popup ("Active session: 41% of 1M context (Fable)"), fed by the
  statusLine helper, which now also stores `context`, `model` and `session_id`.
- `contrib/claude-usage-hook.sh`: a Claude Code hook (Notification, Stop) that makes the widget rescan
  sessions immediately and raise the "needs your attention" notification without waiting for a scan.
- Instant cache updates: with `inotify-tools` installed the widget reads the statusLine cache the moment
  it is rewritten (`watch_cache`).
- Compact mode (`compact = true`): icon only, the chip fills up like a bar; flags stay visible.
- `bar_windows` chooses the windows in the bar text, `color_window` the window that colours the chip.
- `$` marker in the bar while paid extra usage is being consumed (`spend_in_bar`).
- Pinned popups close with Escape or a click anywhere (`popup_escape`, `popup_click_away`);
  `claude_usage.toggle_popup()` pins the popup from a key binding, centred on the focused screen.

## [0.4.0] - 2026-09-22

### Added
- Forecast: samples are recorded to `~/.cache/claude-usage/history.csv`; the popup shows the burn rate
  outcome per window ("at this pace ~38% at reset" or "empty in 1h 20m"), a pacing marker on the weekly
  bar and a 24-hour sparkline.
- Running Claude Code sessions from `~/.claude/sessions`: count and states in the popup, a flag in the
  bar when a session waits for you, notifications on "needs attention" (default on) and "finished" (off).
- Adaptive polling: `interval` while a session works, `interval_idle` (15 min) otherwise, plus an early
  refresh when work starts or stops.
- A statusLine cache younger than `fresh_cache_max_age` (2 min) replaces the API call entirely.
- `cli.lua` for waybar, polybar, tmux and shell prompts (`--text`, `--json`, `--waybar`, `--lines`),
  with its own result cache and backoff so it can be called every few seconds.
- "reset due" instead of "resets in expired" for windows whose reset time has passed.

## [0.3.0] - 2026-09-22

### Added
- `claude_usage.debug()` prints versions, effective options and the current state for bug reports (no secrets).
- `example/rc.lua`, CONTRIBUTING.md, SECURITY.md, issue and pull request templates, Dependabot for the CI actions.

### Changed
- README with badges, hero image and a table of contents.

## [0.2.0] - 2026-09-22

### Added
- Claude-styled look: cairo-drawn starburst icon, chip style with terracotta/amber/red background,
  cream text; `style = "bare"` for themed bars plus `format.chip_color()`.
- Graphical popup: logo header with plan and data source, one progress bar per usage window,
  reset times, scoped model limits, extra usage, weekly breakdown and footer.
- New options `style`, `icon`, `icon_size`, `chip`, `popup_width`, `popup_colors`, `popup_radius`;
  `format.popup_rows()` and `format.plan_name()`.

### Changed
- Default warn/crit text colours now use the Claude palette (`#E39B3A`, `#C8442E`).

## [0.1.0] - 2026-09-22

### Added
- Wibar widget showing the 5-hour session and 7-day weekly Claude Code usage windows.
- Data sources: Claude Code OAuth usage endpoint, statusLine cache file, `~/.claude.json` cache.
- Exponential backoff on HTTP 429 and network errors; token is read-only, never refreshed.
- Hover popup with reset times, model-scoped weekly limits, extra usage and data age.
- Desktop notifications when a window crosses the warn/crit thresholds.
- `contrib/statusline-cache.sh` helper for the Claude Code statusLine.

[0.5.3]: https://github.com/derblub/awesome-claude-usage/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/derblub/awesome-claude-usage/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/derblub/awesome-claude-usage/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/derblub/awesome-claude-usage/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/derblub/awesome-claude-usage/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/derblub/awesome-claude-usage/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/derblub/awesome-claude-usage/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/derblub/awesome-claude-usage/releases/tag/v0.1.0
