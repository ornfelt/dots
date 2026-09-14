require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- The custom wezterm build draws a cursor trail of its own, and two trails over
-- the same cursor fight each other, so leave the trail to the terminal there and
-- set this plugin up everywhere else.
--
-- It is recognised by WEZTERM_EXECUTABLE, which wezterm exports on its own: the
-- custom build runs straight out of its cargo target directory, the installed
-- one does not. The version string cannot be used for this -- it is date plus
-- commit ("20260914-214330-10f0586c"), so it changes with every rebuild, and the
-- installed build has exactly the same shape.
--
-- os.getenv rather than vim.env so the same lines work in nvcs, which mirrors
-- this file and has no vim.env.
local function terminal_draws_smear()
  local exe = os.getenv("WEZTERM_EXECUTABLE")
  if not exe then
    return false
  end
  exe = exe:lower():gsub("\\", "/")
  return exe:find("/target/release/", 1, true) ~= nil
    or exe:find("/target/debug/", 1, true) ~= nil
end

-- lua/pack_plugins.lua runs every spec's config(), so there is no spec-level
-- switch to skip this one; the plugin's own `enabled` is what keeps it inert.
return {
  src = "https://github.com/sphamba/smear-cursor.nvim",
  config = function()
    require("smear_cursor").setup({ enabled = not terminal_draws_smear() })
  end,
}
