# claude_usage — vendored module notes

`claude_usage/` is a vendored copy of
[derblub/awesome-claude-usage](https://github.com/derblub/awesome-claude-usage),
an AwesomeWM wibar widget showing Claude Code subscription limits (the 5-hour
session window, the 7-day weekly window and per-model weekly limits).

| | |
|---|---|
| Upstream | https://github.com/derblub/awesome-claude-usage |
| Pinned commit | `9b2a26a45ed66dbd4455180fc2ba6b1d49d74304` (2026-09-23) |
| Vendored as | `claude_usage/`, `.git` removed — tracked directly in this repo |
| License | MIT (see `claude_usage/LICENSE`) |

## How it differs from upstream

**The module source is unmodified.** Every file under `claude_usage/` is
byte-identical to the upstream tree at the pinned commit. Nothing was patched,
backported or hand-edited. Verify at any time with:

```sh
git clone https://github.com/derblub/awesome-claude-usage /tmp/acu-check
rm -rf /tmp/acu-check/.git
diff -r /tmp/acu-check ~/.config/awesome/claude_usage   # expect no output
```

The only differences from a fresh clone are:

1. **`.git/` removed**, so the widget is tracked as ordinary files in this repo
   rather than as a submodule or nested checkout.
2. Nothing else. `claude_usage/.luacheckrc` is tracked like any other file.

   It briefly was not: the root `.gitignore` listed `.luacheckrc` with no
   leading slash, so it matched at *any* depth and silently swallowed the
   vendored one. That rule is inherited from lcpz/awesome-copycats
   (commit `548347e`, "git-ignore .luacheckrc; closes #221") and exists so a
   personal luacheck config at the repo root stays untracked. It is now
   anchored as `/.luacheckrc`, which keeps that intent and stops it reaching
   into subdirectories. No `git add -f` is needed.

All local behaviour changes are **configuration**, passed as options to
`claude_usage.new()` in `themes/multicolor/theme.lua`. Keeping the module
pristine means updating it is a delete-and-re-clone with no merge conflicts.

## Local configuration

Everything lives in one block in `themes/multicolor/theme.lua`, just after the
Spotify widget. Deviations from upstream defaults:

| Option | Default | Here | Why |
|---|---|---|---|
| `font` | `nil` (→ `beautiful.font`) | `theme.font` | See the ordering note below |
| `style` | `"chip"` | `"bare"` | No terracotta pill; icon and numbers drawn in Claude orange directly on the bar, matching the flat gruvbox segments around it |
| `colors.normal` | `nil` (inherit fg) | `#D97757` | The orange foreground that replaces the chip background |
| `colors.icon` | `#D97757` | `#D97757` | Unchanged; set explicitly to keep it beside `normal` |
| `colors.warn` / `.crit` | amber / red | amber / red | Unchanged; the widget still signals at 75 % and 90 % |
| `spend_in_bar` | `true` | `claude_show_spend` (`false`) | Hides the ` +30.19€` extra-usage tail; the bar is already crowded. Flip the local at the top of the block to re-enable. The popup still reports spend via `popup_show_spend` |
| `popup_placement` | `nil` | custom | Cursor-following popup, see below |
| `on_click` | `"xterm -e claude"` | `awful.util.terminal .. " -e claude"` | Uses this config's terminal (`wezterm`) |

### The `font` ordering trap

`claude_usage/widget.lua:22` resolves `opts.font or beautiful.font` **at widget
construction time**. The widget is constructed at the top level of
`theme.lua`, which runs *inside* `beautiful.init()` — before the returned theme
table is applied. So `beautiful.font` is still `nil` at that moment and
`brand.font_parts` falls back to `"sans", 10`: wrong family, wrong size, and a
too-small icon (`icon_size` defaults to `1.35 × font_size`).

Passing `font = theme.font` explicitly sidesteps the ordering and fixes the bar
text, the derived icon size and the popup fonts in one go. Anything else
constructed during theme load that reads `beautiful.*` has the same hazard.

### Cursor-following popup

Upstream anchors the popup next to the widget with `awful.placement.next_to`.
The local config overrides this through the module's `popup_placement` hook
(`claude_usage/config.lua:71` — supported but undocumented in the README; it
takes priority over the built-in placement) to put the popup centred under the
mouse, `dpi(16)` below the pointer, and track it as it moves.

The supporting parts, all in `theme.lua`:

- `claude_place_under_mouse(d, force)` — positions the popup, clamps it
  horizontally to the workarea and flips it *above* the cursor when it would
  overflow the bottom. Skips work when the pointer has not moved unless `force`.
- `claude_follow_timer` — a 0.03 s `gears.timer` that repositions while the
  popup is open. It stops itself when the popup hides **or** when the pointer
  leaves the widget (tested with `mouse.current_widgets`), so a popup pinned
  with middle-click stays put instead of chasing the cursor.
- `claude_usage` is forward-declared as a local because the timer's callback
  needs to compare against it.

## Bar placement

Inserted in the right-hand widget group in `theme.at_screen_connect`, between
`spotify_widget_with_margin` and `netdownicon`:

```
spotify → claude → net↓ net↑ → mem → cpu → weather → temp → vol → bat → clock
```

This puts it left of weather and left of the whole net/mem/cpu block that
`toggle_widget_visibility()` hides, so collapsing the bar leaves the Claude
segment visible.

## Environment notes

- Upstream targets AwesomeWM git (4.3-git, API level 4) and Lua 5.4/LuaJIT.
  This machine runs **stable 4.3 with Lua 5.3**. All module files parse under
  `luac5.3 -p`, and `claude_usage/init.lua:88` already falls back to
  `naughty.notify` when `naughty.notification` is absent. Other API-level
  differences are possible but none have surfaced.
- Requires `curl`, and Claude Code logged in with a Pro/Max subscription. The
  module reads `~/.claude/.credentials.json` read-only — it never refreshes or
  writes the token, so it cannot log you out.
- `claude_usage/cli.lua` prints the same data for a quick check outside
  AwesomeWM: `lua5.3 claude_usage/cli.lua`.

## Updating

```sh
cd ~/.config/awesome
rm -rf claude_usage
git clone https://github.com/derblub/awesome-claude-usage claude_usage
rm -rf claude_usage/.git
git add claude_usage
```

Then re-check this file's option table against the new
`claude_usage/config.lua` defaults, and update the pinned commit above.

## Checking for drift

`./gen_diffs.sh` compares the vendored tree against upstream and writes
`diff_claude_usage.diff`. Because the module is unpatched, that file should stay
**empty**; content in it means either someone edited `claude_usage/` in place or
upstream has moved on since the pin. The script prints which:

```
claude_usage is identical to https://github.com/derblub/awesome-claude-usage @ 9b2a26a
```

Unlike the other three diffs, this one cannot use a git remote — the vendored
tree comes from an unrelated repository with its files at the root rather than
under `claude_usage/` — so the script shallow-clones upstream to a temp dir and
uses `git diff --no-index`. It skips with a message when the network is down,
leaving the other diffs unaffected.
