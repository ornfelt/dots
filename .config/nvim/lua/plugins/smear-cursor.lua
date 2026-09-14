require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- The custom wezterm build draws a cursor trail of its own, and two trails over
-- the same cursor fight each other, so leave the trail to the terminal there and
-- load this plugin everywhere else. See lua/pack/smear-cursor.lua for why this
-- goes by WEZTERM_EXECUTABLE rather than by the version string.
--
-- Unlike the vim.pack spec in lua/pack/, lazy honours `enabled` itself, so the
-- plugin is not even loaded when the terminal has the trail covered.
local function terminal_draws_smear()
  local exe = os.getenv("WEZTERM_EXECUTABLE")
  if not exe then
    return false
  end
  exe = exe:lower():gsub("\\", "/")
  return exe:find("/target/release/", 1, true) ~= nil
    or exe:find("/target/debug/", 1, true) ~= nil
end

return {
  "sphamba/smear-cursor.nvim",
  enabled = not terminal_draws_smear(),
  opts = {},
}
