-- Automatic command to adjust format options
vim.cmd [[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
]]

-- vim.api.nvim_command('autocmd BufEnter *.tex :set wrap linebreak nolist spell')

-- Automatically load the session when entering vim
-- vim.api.nvim_create_autocmd("VimEnter", {
--   pattern = "*",
--   command = "source ~/.vim/sessions/s.vim"
-- })

-- Helper function to create key mappings for given filetypes
local function create_mappings(ft, mappings)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      for lhs, rhs in pairs(mappings) do
        vim.api.nvim_buf_set_keymap(bufnr, 'i', lhs, rhs, { noremap = true, silent = true })
      end
    end
  })
end

-- Text
create_mappings("vtxt,vimwiki,wiki,text,md,markdown", {
  ["line<Tab>"] = '----------------------------------------------------------------------------------<Enter>',
  ["oline<Tab>"] = '******************************************<Enter>',
  ["date<Tab>"] = '<-- <C-R>=strftime("%Y-%m-%d %a")<CR><Esc>A -->'
})

-- HTML
create_mappings("html", {
  ["<i<Tab>"] = '<em></em> <Space><++><Esc>/<<Enter>GNi',
  ["<b<Tab>"] = '<b></b><Space><++><Esc>/<<Enter>GNi',
  ["<h1<Tab>"] = '<h1></h1><Space><++><Esc>/<<Enter>GNi',
  ["<h2<Tab>"] = '<h2></h2><Space><++><Esc>/<<Enter>GNi',
  ["<im<Tab>"] = '<img></img><Space><++><Esc>/<<Enter>GNi'
})

-- C
create_mappings("c", {
  ["sout<Tab>"] = 'printf("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'printf("x: %d\\n", x);<Esc>Fxciw',
  ["souts<Tab>"] = 'printf("x: %s\\n", x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'printf("x: %s\\n", x ? "true" : "false");<Esc>Fxciw',
  ["soutf<Tab>"] = 'printf("x: %.2f\\n", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'printf("x: %.6f\\n", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'printf("x: %c\\n", x);<Esc>Fxciw',
  ["soutp<Tab>"] = 'printf("x: %p\\n", (void*)&x);<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (int i = 0; i < length; i++) {<Enter>printf("El: %d\\n", arr[i]);<Enter>}<Esc>?arr<Enter>ciw'
})

-- C++
create_mappings("cpp,c++", {
  ["sout<Tab>"] = 'std::cout << ""; std::endl;<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw',
  ["souts<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw',
  ["soutb<Tab>"] = 'std::cout << "x: " << (x ? "true" : "false") << std::endl;<Esc>Fxciw',
  ["soutf<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(2) << x << std::endl;<Esc>Fxciw',
  ["soutd<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(6) << x << std::endl;<Esc>Fxciw',
  ["soutc<Tab>"] = 'std::cout << "x: " << static_cast<char>(x) << std::endl;<Esc>Fxciw',
  ["soutp<Tab>"] = 'std::cout << "x: " << &x << std::endl;<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (auto& el : arr) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- C#
create_mappings("cs", {
  ["sout<Tab>"] = 'Console.WriteLine("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["souts<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["soutb<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["soutf<Tab>"] = 'Console.WriteLine($"x: {x:F2}");<Esc>Fxciw',
  ["soutd<Tab>"] = 'Console.WriteLine($"x: {x:F6}");<Esc>Fxciw',
  ["soutc<Tab>"] = 'Console.WriteLine($"x: {(char)x}");<Esc>Fxciw',
  ["soutp<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw', -- Pointer value
  ["fore<Tab>"] = 'foreach (var x in obj)<Enter>{<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw'
})

-- Go
create_mappings("go", {
  ["sout<Tab>"] = 'fmt.Println("");<Esc>2F"li',
  ["souti<Tab>"] = 'fmt.Printf("x: %d\\n", x)<Esc>Fxciw',
  ["souts<Tab>"] = 'fmt.Printf("x: %s\\n", x)<Esc>Fxciw',
  ["soutb<Tab>"] = 'fmt.Printf("x: %t\\n", x)<Esc>Fxciw',
  ["soutf<Tab>"] = 'fmt.Printf("x: %.2f\\n", x)<Esc>Fxciw',
  ["soutd<Tab>"] = 'fmt.Printf("x: %.6f\\n", x)<Esc>Fxciw',
  ["soutc<Tab>"] = 'fmt.Printf("x: %c\\n", x)<Esc>Fxciw',
  ["soutp<Tab>"] = 'fmt.Printf("x: %p\\n", &x)<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for i := 0; i < val; i++ {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for idx, el := range arr {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Java
create_mappings("java", {
  ["sout<Tab>"] = 'System.out.println("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw',
  ["souts<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'System.out.println("x: " + (x ? "true" : "false"));<Esc>Fxciw',
  ["soutf<Tab>"] = 'System.out.printf("x: %.2f%n", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'System.out.printf("x: %.6f%n", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'System.out.println("x: " + (char)x);<Esc>Fxciw',
  ["soutp<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw', -- Pointer value
  ["fore<Tab>"] = 'for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["psvm<Tab>"] = 'public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o'
})

-- Js/Ts
create_mappings("js,ts,javascript,typescript", {
  ["sout<Tab>"] = 'console.log("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw',
  ["souts<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw',
  ["soutb<Tab>"] = 'console.log(`x: ${x}` ? "true" : "false");<Esc>Fxciw',
  ["soutf<Tab>"] = 'console.log(`x: ${x.toFixed(2)}`);<Esc>Fxciw',
  ["soutd<Tab>"] = 'console.log(`x: ${x.toFixed(6)}`);<Esc>Fxciw',
  ["soutc<Tab>"] = 'console.log(`x: ${String.fromCharCode(x)}`);<Esc>Fxciw',
  ["soutp<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for (let i = 0; i < val; i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'arr.forEach(el => {<Enter><Enter>});<Esc>?arr<Enter>ciw'
})

-- Lua
create_mappings("lua", {
  ["sout<Tab>"] = 'print("")<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'print("x: " .. x)<Esc>Fxciw',
  ["souts<Tab>"] = 'print("x: " .. x)<Esc>Fxciw',
  ["soutb<Tab>"] = 'print("x: " .. (x and "true" or "false"))<Esc>Fxciw',
  ["soutf<Tab>"] = 'print(string.format("x: %.2f", x))<Esc>Fxciw',
  ["soutd<Tab>"] = 'print(string.format("x: %.6f", x))<Esc>Fxciw',
  ["soutc<Tab>"] = 'print("x: " .. string.char(x))<Esc>Fxciw',
  ["soutp<Tab>"] = 'print("x: " .. tostring(x))<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for i = 1, val, 1 do<Enter><Enter>end<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for i, el in ipairs(arr) do<Enter><Enter>end<Esc>?arr<Enter>ciw'
})

-- Php
create_mappings("php", {
  ["sout<Tab>"] = 'echo "";<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw',
  ["souts<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw',
  ["soutb<Tab>"] = 'echo "x: " . ($x ? "true" : "false") . "\\n";<Esc>Fxciw',
  ["soutf<Tab>"] = 'echo "x: " . number_format($x, 2) . "\\n";<Esc>Fxciw',
  ["soutd<Tab>"] = 'echo "x: " . number_format($x, 6) . "\\n";<Esc>Fxciw',
  ["soutc<Tab>"] = 'echo "x: " . chr($x) . "\\n";<Esc>Fxciw',
  ["soutp<Tab>"] = 'echo "x: " . $x . "\\n";<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for ($i = 0; $i < $val; $i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'foreach ($arr as $el) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Python
create_mappings("py,python", {
  ["sout<Tab>"] = 'print("")<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw',
  ["souts<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw',
  ["soutb<Tab>"] = 'print(f"x: {"true" if x else "false"}")<Esc>Fxciw',
  ["soutf<Tab>"] = 'print(f"x: {x:.2f}")<Esc>Fxciw',
  ["soutd<Tab>"] = 'print(f"x: {x:.6f}")<Esc>Fxciw',
  ["soutc<Tab>"] = 'print(f"x: {chr(x)}")<Esc>Fxciw',
  ["soutp<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for i in range():<Esc>hi',
  ["fore<Tab>"] = 'for i in :<Esc>i'
})

-- Rust
create_mappings("rs,rust", {
  ["sout<Tab>"] = 'println!("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw',
  ["souts<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'println!("x: {}", if x { "true" } else { "false" });<Esc>Fxciw',
  ["soutf<Tab>"] = 'println!("x: {:.2}", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'println!("x: {:.6}", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'println!("x: {}", x as char);<Esc>Fxciw',
  ["soutp<Tab>"] = 'println!("x: {:?}", &x);<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for i in 0..val {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for el in arr.iter() {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Bash
create_mappings("sh,bash", {
  ["sout<Tab>"] = 'echo "";<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'echo "x: $x";<Esc>0f$ciw',
  ["souts<Tab>"] = 'echo "x: $x";<Esc>0f$ciw',
  ["soutb<Tab>"] = 'if [ "$x" = "true" ]; then echo "x: true"; else echo "x: false"; fi;<Esc>0f$ciw',
  ["soutf<Tab>"] = 'printf "x: %.2f\\n" "$x";<Esc>0f$ciw',
  ["for<Tab>"] = 'for i in {1..10}; do<Enter>echo "Element: $i"<Enter>done<Esc>kA<Enter>',
  ["fore<Tab>"] = 'for item in "${array[@]}"; do<Enter>echo "Item: $item"<Enter>done<Esc>kA<Enter>'
})

-- PowerShell
create_mappings("ps1,powershell", {
  ["sout<Tab>"] = 'Write-Output ""<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'Write-Output "x: $x"<Esc>0f$ciw',
  ["souts<Tab>"] = 'Write-Output "x: $x"<Esc>0f$ciw',
  ["soutb<Tab>"] = 'Write-Output ("x: " + ($x -eq $true ? "true" : "false"))<Esc>0f$ciw',
  ["soutf<Tab>"] = 'Write-Output ("x: " + "{0:N2}" -f $x)<Esc>0f$ciw',
  ["for<Tab>"] = 'for ($i = 0; $i -lt 10; $i++) {<Enter>Write-Output "Element: $i"<Enter>}<Esc>kA<Enter>',
  ["fore<Tab>"] = 'foreach ($item in $array) {<Enter>Write-Output "Item: $item"<Enter>}<Esc>kA<Enter>'
})

local function run_pdflatex()
  local file = vim.fn.expand('%:p')
  vim.fn.jobstart({'pdflatex', file})
end

-- Autocommand to run pdflatex on write for .tex files
if vim.fn.executable('pdflatex') == 1 then
  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.tex',
    callback = run_pdflatex,
  })
end

vim.api.nvim_create_autocmd("BufRead", {
  -- pattern = "*",
  pattern = {"*.txt", "*.sql"},
  callback = function()
    vim.cmd('edit ++ff=dos %')
  end
})

local function update_wildignore(filetype)
  local wildignore = vim.opt.wildignore:get()

  if filetype == "rust" then
    if not vim.tbl_contains(wildignore, "*/target/*") then
      table.insert(wildignore, "*/target/*")
    end
  elseif filetype == "cs" then
    if not vim.tbl_contains(wildignore, "*/bin/*") then
      table.insert(wildignore, "*/bin/*")
    end
    if not vim.tbl_contains(wildignore, "*/obj/*") then
      table.insert(wildignore, "*/obj/*")
    end
  elseif filetype == "cpp" or filetype == "c" then
    if not vim.tbl_contains(wildignore, "*/build/*") then
      table.insert(wildignore, "*/build/*")
    end
  end

  vim.opt.wildignore = wildignore
end

-- use leader-, on line below
-- :lua print(vim.inspect(vim.opt.wildignore:get()))
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = { "*.rs", "*.cs", "*.cpp", "*.c" },
  callback = function()
    local filetype = vim.bo.filetype
    update_wildignore(filetype)
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Autocommands for SQL files

-- Read Program.cs and appsettings file and extract engine and env values
local function read_envs_from_appsettings()
  local code_root_dir = os.getenv("code_root_dir")
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
  local suffixes = { "_local", "_dev", "_test", "_uat", "_stage", "_prod" }

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
  local code_root_dir = os.getenv("code_root_dir")
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
-- No initial new line
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

  -- Insert lines into buffer without an extra newline at the start
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
  local code_root_dir = os.getenv("code_root_dir")
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
    for table_name in line:lower():gmatch("from%s+([%w_%.]+)") do
      tables[table_name] = true
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
  local matches = find_matching_databases(tables, db_data)
  -- print_results(matches, engine_env_map)

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
  local suffixes = { "_local", "_dev", "_test", "_uat", "_stage", "_prod" }

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

  -- Extract engine and env from the buffer
  local engine, env = extract_engine_env_from_buffer()
  if not engine or not env then
    print("Engine or environment not found in the current buffer.")
    return
  end

  -- Find file corresponding to env
  local db_name = find_file_for_env(env, db_data, engine_env_map)
  -- print("db_name: " .. db_name)

  if not db_name then
    print("No matching database file found for the environment:", env)
    return
  end

  local file_path = db_path .. "/" .. db_name .. ".txt"
  -- print("file_path: " .. file_path)

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

-- 2 spaces for tabs in Lua files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.bo.shiftwidth = 2  -- Number of spaces to use for each step of (auto)indent
    vim.bo.tabstop = 2     -- Number of spaces that a <Tab> counts for
    vim.bo.softtabstop = 2 -- Number of spaces that a <Tab> inserts
    vim.bo.expandtab = true -- Use spaces instead of tabs
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

