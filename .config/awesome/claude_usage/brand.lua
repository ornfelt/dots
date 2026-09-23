-- brand.lua - Claude-inspired palette and font helpers (pure Lua).

local M = {}

-- Warm palette in the spirit of claude.ai: terracotta accent, cream text, charcoal surfaces.
M.palette = {
	orange = "#D97757", -- primary accent
	orange_deep = "#C15F3C",
	amber = "#E39B3A", -- warn
	red = "#C8442E", -- crit
	cream = "#FAF9F5", -- text on dark / on orange
	ivory = "#F0EEE6",
	muted = "#9C9A93", -- secondary text
	slate = "#141413", -- darkest
	charcoal = "#1F1E1D", -- popup surface
	graphite = "#2B2A27", -- raised surface
	line = "#3A3835", -- borders, bar tracks
	error = "#4A4744", -- chip while nothing works
}

--- Split a Pango font description into family and size: "Hack Nerd Font 10" -> "Hack Nerd Font", 10.
---@param font string|nil
---@return string family
---@return number size
function M.font_parts(font)
	local s = tostring(font or "")
	local family, size = s:match("^(.-)%s+([%d%.]+)$")
	if not family or family == "" then
		return (s ~= "" and s or "sans"), 10
	end
	return family, tonumber(size) or 10
end

--- Build a font description from a base font with a different size and optional weight.
---@param font string|nil base font, e.g. beautiful.font
---@param size number
---@param weight string|nil e.g. "Bold"
---@return string
function M.font(font, size, weight)
	local family = M.font_parts(font)
	return family .. (weight and (" " .. weight) or "") .. " " .. tostring(size)
end

--- Level -> colour, using the palette unless overridden.
---@param level "normal"|"warn"|"crit"|"error"
---@param overrides table|nil { normal, warn, crit, error }
function M.level_color(level, overrides)
	overrides = overrides or {}
	if level == "crit" then
		return overrides.crit or M.palette.red
	elseif level == "warn" then
		return overrides.warn or M.palette.amber
	elseif level == "error" then
		return overrides.error or M.palette.error
	end
	return overrides.normal or M.palette.orange
end

return M
