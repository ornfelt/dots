# Contributing

Thanks for taking a look. Bug reports, ideas and pull requests are welcome.

## Reporting a problem

Open an issue with the bug template. The most useful thing you can attach is the
widget's own debug dump, which contains no secrets:

```sh
DISPLAY=:0 awesome-client 'return require("claude_usage").debug()'
```

Add the AwesomeWM version (`awesome --version`) and the Claude Code version
(`claude --version`).

## Development setup

```sh
git clone https://github.com/derblub/awesome-claude-usage.git
cd awesome-claude-usage
make          # luacheck + tests on Lua 5.4 and LuaJIT
```

- `make test` needs `lua5.4` (or set `LUA=lua`) and optionally `luajit`; no LuaRocks packages.
- `make lint` needs [luacheck](https://github.com/lunarmodules/luacheck).
- Tests live in `spec/` and use the tiny runner in `spec/run.lua`
  (`describe`, `it`, `assert_eq`, `assert_true`, `assert_nil`, `assert_error`).
  Run one group with `lua5.4 spec/run.lua "normalize"`. Tests that need files write to
  `spec/tmp/` (created by the runner, git-ignored).
- Fixtures for the sessions directory live in `spec/fixtures/sessions/`; the tests inject a
  fake `alive` check so no real process is needed.

## Code layout

| File | Runs without awesome | Purpose |
|---|---|---|
| `init.lua` | no | public API, wires real dependencies |
| `widget.lua`, `popup.lua`, `icon.lua`, `bar.lua` | no | wibox widgets, cairo drawing (starburst, bars, sparkline) |
| `model.lua` | yes (injected deps) | scheduling, fallback chain, backoff, sessions polling, subscribers |
| `normalize.lua` | yes | raw API / statusLine / claude.json → canonical state |
| `history.lua` | yes | samples on disk, burn rate, forecast, pacing |
| `sessions.lua` | yes | `~/.claude/sessions` summary and transitions |
| `format.lua`, `brand.lua`, `timeparse.lua`, `backoff.lua`, `notify.lua`, `config.lua` | yes | pure helpers |
| `source/*.lua` | yes | credentials, curl, cache readers |
| `cli.lua` | yes | standalone entry point for waybar, polybar, tmux |
| `contrib/statusline-cache.sh` | – | Claude Code statusLine helper (rate limits, context window) |
| `contrib/claude-usage-hook.sh` | – | Claude Code hook that pokes the widget via awesome-client |

Keep the pure modules free of `require("awful")` and friends so they stay testable.
Anything that touches awesome goes through the `deps` table that `init.lua` builds.

## Style

- Tabs for indentation, 120-column lines, `luacheck` clean.
- User-visible strings, comments and docs in English.
- Never log, print or store the access token. Fixtures in `spec/fixtures/` must be anonymised.

## Releasing

1. Bump `M.version` in `config.lua` and add a section to `CHANGELOG.md`.
2. `git tag -a vX.Y.Z -m "vX.Y.Z"` and push with `--tags`.
3. `gh release create vX.Y.Z --generate-notes`.
