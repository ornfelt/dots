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

-- Presets from the smear-cursor README examples. Mirrored in lua/pack/smear-cursor.lua.
local SMEAR_PRESETS = {
  NONE = 'none',                     -- don't pass any options, plugin defaults
  FASTER = 'faster',                 -- snappier smear
  SMOOTH_NO_SMEAR = 'smooth_no_smear', -- smooth rectangular cursor, no trail
  SMOOTH_CARET = 'smooth_caret',     -- smooth vertical bar cursor, no trail (guessed, see below)
  FIRE_HAZARD = 'fire_hazard',       -- orange cursor spewing particles
  HIGH_FRAMERATE = 'high_framerate', -- default smear, drawn every 7ms instead of 17ms
  BOUNCY = 'bouncy',                 -- default smear with lower damping, overshoots target
  TRANSPARENT_BG = 'transparent_bg', -- for fonts with legacy computing symbols (e.g. Cascadia Code)
  NO_GUI_COLORS = 'no_gui_colors',   -- when not using termguicolors / guicursor
}

-- Set preset to use here:
local SMEAR_PRESET = SMEAR_PRESETS.NONE
--local SMEAR_PRESET = SMEAR_PRESETS.FIRE_HAZARD

local SMEAR_PRESET_OPTS = {
  [SMEAR_PRESETS.NONE] = {},
  [SMEAR_PRESETS.FASTER] = {
    stiffness = 0.8,
    trailing_stiffness = 0.5,
    distance_stop_animating = 0.5,
  },
  [SMEAR_PRESETS.SMOOTH_NO_SMEAR] = {
    stiffness = 0.5,
    trailing_stiffness = 0.49,
    never_draw_over_target = false,
  },
  -- The README shows a "Smooth caret" demo but no options for it; this is the
  -- no-smear setup with the normal mode cursor treated as a vertical bar.
  -- Pair it with a bar cursor in guicursor.
  [SMEAR_PRESETS.SMOOTH_CARET] = {
    stiffness = 0.5,
    trailing_stiffness = 0.5,
    matrix_pixel_threshold = 0.5,
    vertical_bar_cursor = true,
  },
  [SMEAR_PRESETS.FIRE_HAZARD] = {
    cursor_color = '#ff4000',
    particles_enabled = true,
    particle_max_num = 200,
    stiffness = 0.5,
    trailing_stiffness = 0.2,
    trailing_exponent = 5,
    damping = 0.6,
    gradient_exponent = 0,
    gamma = 1,
    never_draw_over_target = true,
    hide_target_hack = true,
    particle_spread = 1,
    particles_per_second = 500,
    particles_per_length = 50,
    particle_max_lifetime = 800,
    particle_max_initial_velocity = 20,
    particle_velocity_from_cursor = 0.5,
    particle_damping = 0.15,
    particle_gravity = -50,
    min_distance_emit_particles = 0,
  },
  [SMEAR_PRESETS.HIGH_FRAMERATE] = {
    time_interval = 7,
  },
  [SMEAR_PRESETS.BOUNCY] = {
    damping = 0.65,
    damping_insert_mode = 0.65,
  },
  [SMEAR_PRESETS.TRANSPARENT_BG] = {
    legacy_computing_symbols_support = true,
  },
  [SMEAR_PRESETS.NO_GUI_COLORS] = {
    cterm_cursor_colors = { 240, 245, 250, 255 },
    cterm_bg = 235,
    hide_target_hack = true,
    never_draw_over_target = true,
  },
}

-- Plain loops rather than vim.tbl_extend so this also works in nvcs.
local function smear_preset_opts(extra)
  local opts = {}
  for k, v in pairs(SMEAR_PRESET_OPTS[SMEAR_PRESET] or {}) do
    opts[k] = v
  end
  for k, v in pairs(extra or {}) do
    opts[k] = v
  end
  return opts
end

return {
  "sphamba/smear-cursor.nvim",
  enabled = not terminal_draws_smear(),
  opts = smear_preset_opts(),
}
