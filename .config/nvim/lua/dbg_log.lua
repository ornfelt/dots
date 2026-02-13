local M = {}

local ENABLE_LOGGING = true
--local ENABLE_LOGGING = false -- no-op

-- If true: only one log line per unique file path, always keep the newest
local UNIQUE_PER_PATH = true
--local UNIQUE_PER_PATH = false

-- Max number of lines to keep in the log file (used only when not in UNIQUE_PER_PATH mode)
local MAX_LINES = 300

-- Where to log:
local log_path = vim.fn.stdpath('cache') .. '/lua_file_usage.log'

-- Append a line, with two possible behaviors:
-- 1) Normal mode: FIFO, keep last MAX_LINES lines
-- 2) UNIQUE_PER_PATH: keep only one line per unique path (latest wins)
local function append_line(line)
  local lines = {}

  -- read existing lines
  do
    local rf = io.open(log_path, 'r')
    if rf then
      for l in rf:lines() do
        table.insert(lines, l)
      end
      rf:close()
    end
  end

  if UNIQUE_PER_PATH then
    -- Build a map of path -> line index
    local path_to_index = {}

    for i, l in ipairs(lines) do
      -- lines look like: "2025-02-12 12:34:56  /path/to/file"
      -- format is: <timestamp>  <space><space><path>
      -- We only care about the path part. Split on two or more spaces.
      local path = l:match("%s%s(.+)$")
      if path then
        path_to_index[path] = i
      end
    end

    -- Extract the path from the new line
    local new_path = line:match("%s%s(.+)$")

    if new_path and path_to_index[new_path] then
      -- Overwrite existing entry for this path with the new line
      lines[path_to_index[new_path]] = line
    else
      -- No previous entry for this path, just append
      table.insert(lines, line)
    end
  else
    -- Normal FIFO behavior: append and trim to MAX_LINES
    table.insert(lines, line)

    local len = #lines
    if len > MAX_LINES then
      local start = len - MAX_LINES + 1
      local trimmed = {}
      for i = start, len do
        table.insert(trimmed, lines[i])
      end
      lines = trimmed
    end
  end

  -- rewrite file
  local wf, err = io.open(log_path, 'w')
  if not wf then
    vim.schedule(function()
      vim.notify('dbg_log: cannot open log file: ' .. tostring(err), vim.log.levels.ERROR)
    end)
    return
  end

  for _, l in ipairs(lines) do
    wf:write(l .. '\n')
  end
  wf:close()
end

-- Public function to log a file usage
function M.log_file(path)
  if not ENABLE_LOGGING then
    return
  end

  -- Normalize path:
  -- 1) trim leading/trailing whitespace
  -- 2) remove leading '@' if present (after trim)
  -- 3) replace backslashes with forward slashes
  -- 4) collapse multiple consecutive slashes into one
  if type(path) == "string" then
    -- trim
    path = path:match("^%s*(.-)%s*$") or path

    -- remove leading '@'
    path = path:gsub("^@", "")

    -- normalize slashes
    path = path:gsub("\\", "/")
    path = path:gsub("/+", "/")
  end

  local timestamp = os.date('%F %T')
  append_line(string.format('%s  %s', timestamp, path))
end

function M.get_log_path()
  return log_path
end

return M

