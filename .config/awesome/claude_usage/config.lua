-- config.lua - option defaults and merging (pure Lua).

local M = {}

M.version = "0.5.3"

local home = os.getenv("HOME") or ""
local xdg_cache = os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")

M.defaults = {
	-- Polling
	interval = 300, -- seconds between successful API fetches (minimum 120)
	initial_delay = 5, -- seconds after startup before the first fetch
	jitter = 30, -- random +/- seconds added to every interval
	timeout = 15, -- curl --max-time
	backoff = { 300, 600, 1200, 1800 }, -- delays after consecutive 429/5xx/network errors
	user_agent = "awesome-claude-usage/" .. M.version .. " (+https://github.com/derblub/awesome-claude-usage)",
	sources = { "api", "statusline", "claude_json" }, -- priority order; drop entries to disable
	api_url = "https://api.anthropic.com/api/oauth/usage",
	credentials_path = home .. "/.claude/.credentials.json",
	claude_json_path = home .. "/.claude.json",
	cache_path = xdg_cache .. "/claude-usage/rate_limits.json",
	stale_after = 3600, -- data older than this is flagged as stale
	fresh_cache_max_age = 120, -- a statusLine cache younger than this replaces an API call
	curl_cmd = "curl",

	-- Sessions (~/.claude/sessions) and adaptive polling
	sessions = true, -- watch running Claude Code sessions
	sessions_dir = home .. "/.claude/sessions",
	sessions_interval = 10, -- seconds between directory scans (local files only)
	interval_idle = 900, -- fetch interval while no session is working
	sessions_in_bar = true, -- append a flag to the bar text when a session needs attention
	attention_flag = " \u{2691}", -- U+2691 black flag
	spend_in_bar = true, -- append the extra usage spent (" +3.53€") while it is being consumed
	spend_flag = nil, -- fixed marker instead of the amount, e.g. " $"
	watch_cache = true, -- react to the statusLine cache instantly via inotifywait (if installed)
	context_max_age = 900, -- show the active session's context window while the cache is this fresh
	notify_attention = true, -- a session waits for a permission or an answer
	notify_finished = false, -- a session went from working to idle

	-- History and forecast
	history = true, -- record samples and show burn rate / forecast / pacing
	history_path = xdg_cache .. "/claude-usage/history.csv",
	sparkline_hours = 24, -- popup sparkline range

	-- Appearance
	font = nil, -- nil -> beautiful.font
	style = "chip", -- "chip": orange pill with cream text; "bare": text only, colours from the theme
	icon = "starburst", -- "starburst" (drawn), "glyph" (text), "none"
	icon_size = nil, -- px; nil -> derived from the font size
	glyph = "\u{f0e7}", -- used when icon = "glyph"
	error_glyph = "\u{f071}",
	show_glyph = true, -- only for icon = "glyph"
	format = nil, -- fun(state, fmt) -> plain text; nil for the default "5h 3% · 7d 67%"
	compact = false, -- icon only; the chip fills up like a bar (style = "chip")
	bar_windows = { "five_hour", "seven_day", "scoped" }, -- windows in the bar text; "scoped" = every per-model limit, or "scoped:<Model>"
	color_window = "max", -- which window colours the chip/text: "max", "five_hour", "seven_day", "scoped:<Model>"
	separator = " · ",
	forced_width = nil,
	align = "center",
	thresholds = { warn = 75, crit = 90, spend = nil },
	-- Text colours for style = "bare" (nil = inherit the surrounding foreground)
	colors = { normal = nil, warn = "#E39B3A", crit = "#C8442E", error = "#9C9A93", stale = nil, icon = "#D97757" },
	color_target = "text", -- "text" wraps the text in a pango span; "none" leaves colours to the theme
	-- Chip colours for style = "chip"
	chip = { normal = "#D97757", warn = "#E39B3A", crit = "#C8442E", error = "#4A4744", fg = "#FAF9F5",
		track = "#3A3835", radius = 6, padding_x = 8, padding_y = 1 },

	-- Popup
	popup = true,
	popup_placement = nil, -- fun(popup, geometry) override
	popup_width = 340, -- dpi
	popup_colors = { bg = "#1F1E1D", fg = "#FAF9F5", muted = "#9C9A93", border = "#3A3835", track = "#3A3835",
		accent = "#D97757", warn = "#E39B3A", crit = "#C8442E" },
	popup_border_width = 1,
	popup_radius = 10,
	popup_show_scoped = true,
	popup_show_spend = true,
	popup_show_breakdown = true,
	popup_escape = true, -- Escape closes a pinned popup
	popup_click_away = true, -- a click anywhere closes a pinned popup

	-- Notifications
	notify_threshold = true,
	notify_reset = false,
	notify_error = false,
	notify_timeout = 8,
	notify_icon = nil,

	-- Mouse buttons
	on_click = "xterm -e claude", -- string -> spawned with a shell; function -> called with state
	on_right_click = nil, -- default: forced refresh
	on_middle_click = nil, -- default: pin/unpin the popup
}

-- Keys whose table values are merged key by key instead of replaced.
local deep_keys = { thresholds = true, colors = true, chip = true, popup_colors = true }

local function copy(t)
	local out = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			out[k] = copy(v)
		else
			out[k] = v
		end
	end
	return out
end

--- Merge user options over the defaults.
---@param opts table|nil
---@param warn fun(msg: string)|nil
---@return table
function M.resolve(opts, warn)
	local out = copy(M.defaults)
	for k, v in pairs(opts or {}) do
		if deep_keys[k] and type(v) == "table" then
			for kk, vv in pairs(v) do
				out[k][kk] = vv
			end
		else
			out[k] = v
		end
	end
	if type(out.interval) ~= "number" or out.interval < 120 then
		if warn then
			warn("interval below 120 s hits the usage endpoint's rate limit; using 120")
		end
		out.interval = 120
	end
	if type(out.backoff) ~= "table" or #out.backoff == 0 then
		out.backoff = copy(M.defaults.backoff)
	end
	return out
end

return M
