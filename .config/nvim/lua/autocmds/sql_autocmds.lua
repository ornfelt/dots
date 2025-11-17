local myconfig = require("myconfig")

local code_root_dir = myconfig.code_root_dir

-- Autocommands for SQL files

-- Read Program.cs and appsettings file and extract engine and env values
local function read_envs_from_appsettings()
  if not code_root_dir then
    print("Environment variable 'code_root_dir' is not set.")
    return nil
  end

  local appsettings_path = code_root_dir .. "/Code2/SQL/my_sql/SqlExec/SqlExec/appsettings.json"

  local file = io.open(appsettings_path, "r")
  if not file then
    -- Check alternative path
    appsettings_path = code_root_dir .. "/Code2/Sql/my_sql/SqlExec/SqlExec/appsettings.json"
    file = io.open(appsettings_path, "r")

    if not file then
      print("appsettings.json file not found at either of the paths.")
      return nil
    end
  end

  local envs = {}
  local in_connection_strings = false

  for line in file:lines() do
    line = line:match("^%s*(.-)%s*$")

    if line:match('"ConnectionStrings"%s*:%s*{') then
      in_connection_strings = true
    elseif in_connection_strings and line:match("}%s*,?") then
      -- End of the "ConnectionStrings" block
      break
    elseif in_connection_strings then
      -- Match environment keys in ConnectionStrings block
      local env = line:match('"%s*([%w_]+)%s*"%s*:') -- Extract keys
      if env then
        table.insert(envs, env:lower())
      end
    end
  end

  file:close()

  local unique_envs = {}
  local seen_envs = {}
  local engine_prefixes = { "oracle_", "mysql_", "sql_server_", "sqlite_", "postgresql_" }
  local suffixes = { "_local", "_localhost", "_dev", "_test", "_uat", "_stage", "_prod" }

  for _, env in ipairs(envs) do
    -- Remove engine prefixes
    local original_env = env
    for _, prefix in ipairs(engine_prefixes) do
      if env:sub(1, #prefix) == prefix then
        env = env:sub(#prefix + 1)
        break
      end
    end

    -- Remove suffixes
    for _, suffix in ipairs(suffixes) do
      if env:sub(-#suffix) == suffix then
        env = env:sub(1, -(#suffix + 1))
        break
      end
    end

    -- Avoid duplicates
    if env and not seen_envs[env] then
      seen_envs[env] = true
      table.insert(unique_envs, original_env)
    end
  end

  -- Sort envs alphabetically for consistency
  --table.sort(envs)
  -- return envs

  return unique_envs
end

-- Helper function to read engines and envs
local function read_program_cs()
  if not code_root_dir then
    print("Environment variable 'code_root_dir' is not set.")
    return nil
  end

  local program_cs_path = code_root_dir .. "/Code2/Sql/my_sql/SqlExec/SqlExec/Program.cs"

  local file = io.open(program_cs_path, "r")
  if not file then
    program_cs_path = code_root_dir .. "/Code2/SQL/my_sql/SqlExec/SqlExec/Program.cs"
    file = io.open(program_cs_path, "r")

    if not file then
      print("Program.cs file not found at either of the paths.")
      return nil
    end
  end

  -- Extract engine values
  local engines = {}
  table.insert(engines, "sql_server") -- Default engine
  engines["sql_server"] = true
  for line in file:lines() do
    -- Match engine values
    local engine = line:match('engine:%s*(%w+)')
    if engine and not engines[engine] then
      table.insert(engines, engine:lower())
      engines[engine] = true
    end
  end

  file:close()

  -- Extract envs from appsettings.json
  local envs = read_envs_from_appsettings()
  if not envs then
    return table.concat(engines, ", "), nil
  end

  -- Return comma-separated lists
  return table.concat(engines, ", "), table.concat(envs, ", ")
end

-- Function to insert the engine and env values into the current buffer
function insert_engine_env_values()
  local engines, envs = read_program_cs()
  if not engines or not envs then
    return
  end

  -- Prepare lines to insert
  local engine_line = "--engine: " .. engines
  local env_line = "--env: " .. envs
  local blank_line = ""

  -- Move cursor to the end of current line
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })

  -- Insert lines into buffer (no extra newline at start)
  vim.api.nvim_put({ engine_line, env_line, blank_line }, "c", true, true)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sql",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_keymap(bufnr, "i", "cnfa<Tab>", "<cmd>lua insert_engine_env_values()<CR>", { noremap = true, silent = true })
  end
})

local function get_notes_path()
  if not code_root_dir then
    print("Environment variable 'code_root_dir' is not set.")
    return nil
  end
  return code_root_dir .. "/Code2/SQL/my_sql/config/dbs"
end

local function parse_db_files(path)
  local db_data = {}
  local engine_env_map = {}

  -- Iterate through all files in dir
  local files = vim.fn.glob(path .. "/*.txt", false, true)
  for _, file in ipairs(files) do
    local tables = {}
    local env = nil

    -- Read file
    for line in io.lines(file) do
      if not env then
        -- First line is env
        --env = line:lower()
        -- Detect and remove BOM if present
        if line:byte(1) == 0xEF and line:byte(2) == 0xBB and line:byte(3) == 0xBF then
          line = line:sub(4) -- Remove the BOM (first three bytes)
        end
        env = line:lower() -- Store the environment
      else
        table.insert(tables, line:lower())
      end
    end

    -- Infer engine from filename
    local db_name = file:match("([^/\\]+)%.txt$"):lower()
    local engine = db_name:match("^(%w+)_")
    if engine == "sqlserver" then
      engine = "sql_server"
    end

    -- Map engine and environment to file name
    db_data[db_name] = tables
    engine_env_map[db_name] = { engine = engine, env = env }
  end

  return db_data, engine_env_map
end

local function extract_tables_from_buffer()
  local tables = {}
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for _, line in ipairs(buffer_lines) do
    -- Extract all occurrences of "from <table_name>" case-insensitively
    --for table_name in line:lower():gmatch("from%s+([%w_]+)") do
    -- Make sure we get schema as well...
    --for table_name in line:lower():gmatch("from%s+([%w_%.]+)") do
    --  tables[table_name] = true
    --end
    -- Make it work for this select format: So [db].[schema].[MyTable] -> MyTable
    -- Fallback via full_match for basic table name support
    for full_match in line:lower():gmatch("from%s+([%w_%.%[%]-]+)") do
      local last_part = full_match:match(".*%.%[?([%w_%-]+)%]?%s*$") or full_match
      tables[last_part] = true
    end
  end

  -- Return unique table names
  local result = {}
  for table_name, _ in pairs(tables) do
    table.insert(result, table_name)
  end
  return result
end

local function find_matching_databases(tables, db_data)
  local db_matches = {}

  for db_name, db_tables in pairs(db_data) do
    for _, table_name in ipairs(tables) do
      if vim.tbl_contains(db_tables, table_name) then
        if not db_matches[table_name] then
          db_matches[table_name] = {}
        end
        table.insert(db_matches[table_name], db_name)
      end
    end
  end

  return db_matches
end

local function determine_engine_env(matches, engine_env_map)
  local engines_set, envs_set = {}, {}
  local engines_list, envs_list = {}, {}

  for _, db_names in pairs(matches) do
    for _, db_name in ipairs(db_names) do
      local details = engine_env_map[db_name]
      if details then
        if not engines_set[details.engine] then
          engines_set[details.engine] = true
          table.insert(engines_list, details.engine)
        end
        if not envs_set[details.env] then
          envs_set[details.env] = true
          -- table.insert(envs_list, details.env)
          if details.env == "s1" then
            table.insert(envs_list, (details.env .. "_dev"))
          else
            table.insert(envs_list, (details.env .. "_local"))
          end
        end
      end
    end
  end

  return table.concat(engines_list, ", "), table.concat(envs_list, ", ")
end

local function print_results(matches, engine_env_map)
  for table_name, db_names in pairs(matches) do
    for _, db_name in ipairs(db_names) do
      local details = engine_env_map[db_name]
      print(string.format(
        "Table: %s, DB: %s, Engine: %s, Env: %s",
        table_name, db_name, details.engine, details.env
      ))
    end
  end
end

function insert_engine_env_from_db()
  local db_path = get_notes_path()
  if not db_path then
    return
  end

  local db_data, engine_env_map = parse_db_files(db_path)
  local tables = extract_tables_from_buffer()

  if myconfig.should_debug_print() then
    print("[debug] Tables found in buffer:")
    for _, tbl in ipairs(tables) do
      print(" - " .. tbl)
    end
  end

  local matches = find_matching_databases(tables, db_data)

  if myconfig.should_debug_print() then
    print_results(matches, engine_env_map)
  end

  local engines, envs = determine_engine_env(matches, engine_env_map)

  if not engines or engines == "" then
    print("No matching databases found.")
    return
  end

  local engine_line = "--engine: " .. engines
  local env_line = "--env: " .. envs
  local blank_line = ""

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })

  vim.api.nvim_put({ engine_line, env_line, blank_line }, "c", true, true)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sql",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_keymap(bufnr, "i", "cnf<Tab>", "<cmd>lua insert_engine_env_from_db()<CR>", { noremap = true, silent = true })
  end,
})

-- cnfd
local function extract_engine_env_from_buffer()
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local engine, env = nil, nil
  local suffixes = { "_local", "_localhost", "_dev", "_test", "_uat", "_stage", "_prod" }

  for _, line in ipairs(buffer_lines) do
    if not engine then
      engine = line:match("^%-%-engine:%s*([%w_]+)")
    end
    if not env then
      env = line:match("^%-%-env:%s*([%w_]+)")
      -- Only get value before '_'
      -- env = line:match("^%-%-env:%s*([%w]+)")
      -- Remove suffixes
      if env then
        for _, suffix in ipairs(suffixes) do
          if env:sub(-#suffix) == suffix then
            env = env:sub(1, -(#suffix + 1))
            break
          end
        end
      end
    end
    if engine and env then
      break
    end
  end

  return engine, env
end

local function find_file_for_env(env, db_data, engine_env_map)
  for db_name, _ in pairs(engine_env_map) do
    -- if engine_env_map[db_name].env:lower():find(env:lower(), 1, true) then
    if engine_env_map[db_name].env:lower() == env:lower() then
      return db_name
    end
  end
  return nil
end

local function generate_select_statements(file, engine)
  local statements = {}
  local is_first_line = true -- Skip first line since it's the env...

  for line in io.lines(file) do
    if is_first_line then
      is_first_line = false
      goto continue
    end

    -- if not line:match("^[%w_]+$") then
    if not line:match("^[%w_.]+$") then
      goto continue
    end
    local table_name = line:lower()

    -- Generate appropriate SQL statement
    local select_statement
    if engine == "mysql" or engine == "sqlite" or engine == "postgresql" then
      select_statement = string.format("select * from %s limit 100;", table_name)
    elseif engine == "sql_server" then
      select_statement = string.format("select top 100 * from %s;", table_name)
    elseif engine == "oracle" then
      select_statement = string.format("select * from %s where rownum <= 100;", table_name)
    else
      print(string.format("Unsupported engine: %s", engine))
      goto continue
    end

    if select_statement then
      table.insert(statements, select_statement)
    end
    ::continue::
  end

  return statements
end

function insert_select_statements_from_db()
  local db_path = get_notes_path()
  if not db_path then
    return
  end

  local db_data, engine_env_map = parse_db_files(db_path)

  local use_debug_print = myconfig.should_debug_print()

  -- Extract engine and env from the buffer
  local engine, env = extract_engine_env_from_buffer()
  if not engine or not env then
    print("Engine or environment not found in the current buffer.")
    return
  end

  -- Find file corresponding to env
  local db_name = find_file_for_env(env, db_data, engine_env_map)
  if use_debug_print then
    print("db_name: " .. db_name)
  end

  if not db_name then
    print("No matching database file found for the environment:", env)
    return
  end

  local file_path = db_path .. "/" .. db_name .. ".txt"
  if use_debug_print then
    print("file_path: " .. file_path)
  end

  local statements = generate_select_statements(file_path, engine)
  if #statements == 0 then
    print("No table data found in the database file.")
    return
  end

  -- Insert select statements into buffer
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })

  vim.api.nvim_put(statements, "c", true, true)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sql",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_keymap(bufnr, "i", "cnfd<Tab>", "<cmd>lua insert_select_statements_from_db()<CR>", { noremap = true, silent = true })
  end,
})

-- Simple sql queries
local function get_engine()
  local default_engine = "mysql" -- Default to MySQL
  local lines = vim.api.nvim_buf_get_lines(0, 0, 3, false) -- Read first 3 lines
  for _, line in ipairs(lines) do
    local engine = line:match("^%-%-engine:%s*([%w_]+)")
    if engine then
      return engine:lower()
    end
  end
  return default_engine
end

function func_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return {
      "CREATE FUNCTION x () RETURNS INT BEGIN RETURN 1; END;",
      "SELECT x();"
    }
  elseif engine == "sql_server" then
    return {
      "CREATE FUNCTION x () RETURNS INT AS BEGIN RETURN 1; END;",
      "SELECT dbo.x();"
    }
  elseif engine == "oracle" then
    return {
      "CREATE FUNCTION x RETURN NUMBER IS BEGIN RETURN 1; END;",
      "BEGIN DBMS_OUTPUT.PUT_LINE(x); END;"
    }
  else
    return {
      "DELIMITER //",
      "CREATE FUNCTION x () RETURNS INT NO SQL BEGIN RETURN 1; END //",
      "DELIMITER ;",
      "SELECT x();"
    }
  end
end

function proc_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return {
      "-- SQLite does not support stored procedures"
    }
  elseif engine == "sql_server" then
    return {
      "CREATE PROCEDURE x AS BEGIN PRINT 'Hello'; END;",
      "EXEC x;"
    }
  elseif engine == "oracle" then
    return {
      "CREATE PROCEDURE x IS BEGIN NULL; END;",
      "BEGIN x; END;"
    }
  else
    return {
      "DELIMITER //",
      "CREATE PROCEDURE x () BEGIN SELECT 'Hello'; END //",
      "DELIMITER ;",
      "CALL x();"
    }
  end
end

function view_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return {
      "CREATE VIEW x AS SELECT 1 AS col;",
      "SELECT * FROM x;"
    }
  elseif engine == "sql_server" then
    return {
      "CREATE VIEW x AS SELECT 1 AS col;",
      "SELECT * FROM x;"
    }
  elseif engine == "oracle" then
    return {
      "CREATE OR REPLACE VIEW x AS SELECT 1 AS col;",
      "SELECT * FROM x;"
    }
  else
    return {
      "CREATE VIEW x AS SELECT 1 AS col;",
      "SELECT * FROM x;"
    }
  end
end

function sout_mapping()
  local engine = get_engine()
  --print("Detected Engine:", engine)

  if engine == "sqlite" then
    return { "PRAGMA x = 42;", "PRAGMA s = 'Hello';", "SELECT x, s;" }
  elseif engine == "sql_server" then
    return { "DECLARE @x INT = 42;", "DECLARE @s NVARCHAR(50) = 'Hello';", "SELECT @x AS x, @s AS s;" }
  elseif engine == "oracle" then
    return {
      "DECLARE x NUMBER := 42;",
      "DECLARE s VARCHAR2(50) := 'Hello';",
      "BEGIN DBMS_OUTPUT.PUT_LINE(x || ' ' || s); END;"
    }
  else
    return { "SET @x = 42;", "SET @s = 'Hello';", "SELECT @x AS x, @s AS s;" }
  end
end

function souti_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return { "PRAGMA intVar = 100;", "SELECT intVar;" }
  elseif engine == "sql_server" then
    return { "DECLARE @intVar INT = 100;", "SELECT @intVar AS intVar;" }
  elseif engine == "oracle" then
    return {
      "DECLARE intVar NUMBER := 100;",
      "BEGIN DBMS_OUTPUT.PUT_LINE(intVar); END;"
    }
  else
    return { "SET @intVar = 100;", "SELECT @intVar AS intVar;" }
  end
end

function souts_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return { "PRAGMA strVar = 'World';", "SELECT strVar;" }
  elseif engine == "sql_server" then
    return { "DECLARE @strVar NVARCHAR(50) = 'World';", "SELECT @strVar AS strVar;" }
  elseif engine == "oracle" then
    return {
      "DECLARE strVar VARCHAR2(50) := 'World';",
      "BEGIN DBMS_OUTPUT.PUT_LINE(strVar); END;"
    }
  else
    return { "SET @strVar = 'World';", "SELECT @strVar AS strVar;" }
  end
end

function soutb_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return { "PRAGMA boolVar = TRUE;", "SELECT boolVar;" }
  elseif engine == "sql_server" then
    return { "DECLARE @boolVar BIT = 1;", "SELECT @boolVar AS boolVar;" }
  elseif engine == "oracle" then
    return {
      "DECLARE boolVar BOOLEAN := TRUE;",
      "BEGIN DBMS_OUTPUT.PUT_LINE(boolVar); END;"
    }
  else
    return { "SET @boolVar = TRUE;", "SELECT @boolVar AS boolVar;" }
  end
end

function soutf_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return { "PRAGMA floatVar = 3.14;", "SELECT floatVar;" }
  elseif engine == "sql_server" then
    return { "DECLARE @floatVar FLOAT = 3.14;", "SELECT @floatVar AS floatVar;" }
  elseif engine == "oracle" then
    return {
      "DECLARE floatVar NUMBER := 3.14;",
      "BEGIN DBMS_OUTPUT.PUT_LINE(floatVar); END;"
    }
  else
    return { "SET @floatVar = 3.14;", "SELECT @floatVar AS floatVar;" }
  end
end

function soutd_mapping()
  local engine = get_engine()
  if engine == "sqlite" then
    return { "PRAGMA doubleVar = 3.14159265359;", "SELECT doubleVar;" }
  elseif engine == "sql_server" then
    return { "DECLARE @doubleVar FLOAT = 3.14159265359;", "SELECT @doubleVar AS doubleVar;" }
  elseif engine == "oracle" then
    return {
      "DECLARE doubleVar NUMBER := 3.14159265359;",
      "BEGIN DBMS_OUTPUT.PUT_LINE(doubleVar); END;"
    }
  else
    return { "SET @doubleVar = 3.14159265359;", "SELECT @doubleVar AS doubleVar;" }
  end
end

function insert_dynamic_sql(mapping_func)
  local statements = mapping_func()
  if not statements or type(statements) ~= "table" or #statements == 0 then
    print("No SQL statements generated or invalid output.")
    return
  end

  -- Insert statements into buffer
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, statements)
  -- Place blank line and move cursor to it
  vim.api.nvim_buf_set_lines(0, row + #statements, row + #statements, false, { "" })
  vim.api.nvim_win_set_cursor(0, { row + #statements + 1, 0 })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sql",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_keymap(bufnr, "i", "sout<Tab>", "<cmd>lua insert_dynamic_sql(sout_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "soutf<Tab>", "<cmd>lua insert_dynamic_sql(soutf_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "soutd<Tab>", "<cmd>lua insert_dynamic_sql(soutd_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "souti<Tab>", "<cmd>lua insert_dynamic_sql(souti_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "souts<Tab>", "<cmd>lua insert_dynamic_sql(souts_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "soutb<Tab>", "<cmd>lua insert_dynamic_sql(soutb_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "func<Tab>", "<cmd>lua insert_dynamic_sql(func_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "proc<Tab>", "<cmd>lua insert_dynamic_sql(proc_mapping)<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "i", "view<Tab>", "<cmd>lua insert_dynamic_sql(view_mapping)<CR>", { noremap = true, silent = true })
  end,
})

local function read_sqls_connections()
  local uv = vim.loop
  local is_windows = vim.fn.has("win32") == 1
  local home = uv.os_homedir() or vim.env.HOME or ""
  local cfg_path = is_windows
      and "C:/local/sqls_config.txt"
      or (home .. "/Documents/local/sqls_config.txt")

  local fd = io.open(cfg_path, "r")
  if not fd then return {} end

  local connections = {}
  for line in fd:lines() do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= "" and not trimmed:match("^#") then
      local driver, dsn = trimmed:match("^(%w+)%s*:%s*(.+)$")
      if driver and dsn then
        table.insert(connections, {
          driver = driver:lower(),
          dataSourceName = dsn,
        })
      end
    end
  end
  fd:close()
  return connections
end

function switch_sqls_connection()
  local use_debug_print = myconfig.should_debug_print()
  if myconfig.should_use_custom_lsp_for_sql() then
    -- TODO: call sql mini switch connection with index based on read connection strings...
    if use_debug_print then
      print("[sqls] Skipping connection switch - UseCustomLspForSql is enabled")
    end
    return
  end

  local engine, env = extract_engine_env_from_buffer()
  if not engine or not env then
    --vim.notify("[sqls] No --engine or --env found in buffer", vim.log.levels.WARN)
    return
  end

  if use_debug_print then
    print("engine: " .. engine)
    print("env: " .. env)
  end

  local connections = read_sqls_connections()
  if #connections == 0 then
    --vim.notify("[sqls] No connections loaded from sqls config file", vim.log.levels.ERROR)
    return
  end

  engine = engine:lower()
  env = env:lower()

  if engine == "sql_server" then
    engine = engine:gsub("sql_server", "mssql")
    env = env:gsub("1bo", "onebackoffice")
  end

  local matched_index = nil
  for i, conn in ipairs(connections) do
    if conn.driver:lower():find(engine, 1, true)
        and conn.dataSourceName:lower():find(env, 1, true) then
      matched_index = i
      break
    end
  end

  if not matched_index then
    vim.notify(string.format("[sqls] No connection matches engine='%s', env='%s'", engine, env), vim.log.levels.WARN)
    return
  end

  vim.cmd("SqlsSwitchConnection " .. matched_index)
  vim.notify(string.format("[sqls] Switched to index %d: %s", matched_index, connections[matched_index].dataSourceName))
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sql",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_keymap(bufnr, "i", "switch<Tab>", "<cmd>lua switch_sqls_connection()<CR>", { noremap = true, silent = true })
  end,
})
-- Run automagically at BufEnter
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.sql",
  callback = function()
    -- Delay slightly to ensure LSP is attached and buffer is ready
    vim.defer_fn(function()
      switch_sqls_connection()
    end, 100)
  end,
})

-- Custom sql lsp functions and commands
local function sqlmini_switch(idx)
  local client = vim.lsp.get_clients({ name = "sqlmini" })[1]
  if not client then
    vim.notify("SqlMiniLsp not attached", vim.log.levels.WARN)
    return
  end

  client.request('workspace/executeCommand', {
    command = 'sqlmini.switch',
    arguments = { { index = tonumber(idx) } }, -- 1=mssql, 2=mysql, 3=sqlite
  }, function(err, _)
      if err then
        vim.notify("sqlmini.switch failed: " .. (err.message or tostring(err)), vim.log.levels.ERROR)
      else
        vim.notify("SqlMiniLsp: switched to preset " .. idx, vim.log.levels.INFO)
      end
    end)
end

vim.api.nvim_create_user_command('SqlMiniSwitch', function(opts)
  sqlmini_switch(opts.args)
end, { nargs = 1, complete = function()
    return { "1", "2", "3" }
  end })

local function sqlmini_dump()
  local client = vim.lsp.get_clients({ name = "sqlmini" })[1]
  if not client then
    vim.notify("SqlMiniLsp not attached", vim.log.levels.WARN)
    return
  end

  client.request('workspace/executeCommand', {
    command = 'sqlmini.dump',
    arguments = {},  -- none needed
  }, function(err, result)
      if err then
        vim.notify("sqlmini.dump failed: " .. (err.message or tostring(err)), vim.log.levels.ERROR)
        return
      end
      if type(result) ~= "string" or result == "" then
        vim.notify("sqlmini.dump: empty result", vim.log.levels.WARN)
        return
      end

      -- open a scratch markdown buffer
      vim.cmd("belowright new")
      local buf = vim.api.nvim_get_current_buf()
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.bo[buf].filetype = "markdown"
      vim.api.nvim_buf_set_name(buf, "SqlMiniSchema.md")

      local lines = {}
      for s in result:gmatch("([^\r\n]*)\r?\n?") do
        table.insert(lines, s)
      end
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
    end)
end

vim.api.nvim_create_user_command("SqlMiniDump", sqlmini_dump, { nargs = 0 })

