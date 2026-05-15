require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")

-- GPT binds
--if myconfig.is_plugin_installed('chatgpt') then
--  local chatgpt_config = {
--    openai_api_key = os.getenv("OPENAI_API_KEY"),
--  }
--
--  -- Model can be changed in actions for this plugin
--  require("chatgpt").setup(chatgpt_config)
--
--  -- bind leader-e: ChatGPTEditWithInstructions (n, v)
--  myconfig.map('n', '<leader>e', ':ChatGPTEditWithInstructions<CR>')
--  myconfig.map('v', '<leader>e', ':ChatGPTEditWithInstructions<CR>')
--  -- bind leader-x: ChatGPTRun explain_code (n, v)
--  myconfig.map('n', '<leader>x', ':ChatGPTRun explain_code<CR>')
--  myconfig.map('v', '<leader>x', ':ChatGPTRun explain_code<CR>')
--  -- bind leader-cc: ChatGPTRun complete_code (n, v)
--  myconfig.map('n', '<leader>cc', ':ChatGPTRun complete_code<CR>')
--  myconfig.map('v', '<leader>cc', ':ChatGPTRun complete_code<CR>')
--  -- bind leader-v: ChatGPTRun summarize (n, v)
--  myconfig.map('n', '<leader>v', ':ChatGPTRun summarize<CR>')
--  myconfig.map('v', '<leader>v', ':ChatGPTRun summarize<CR>')
--  -- bind leader-g: ChatGPTRun grammar_correction (n, v)
--  myconfig.map('n', '<leader>g', ':ChatGPTRun grammar_correction<CR>')
--  myconfig.map('v', '<leader>g', ':ChatGPTRun grammar_correction<CR>')
--  -- bind leader-6: ChatGPTRun docstring (n, v)
--  myconfig.map('n', '<leader>6', ':ChatGPTRun docstring<CR>')
--  myconfig.map('v', '<leader>6', ':ChatGPTRun docstring<CR>')
--  -- bind leader-7: ChatGPTRun add_tests (n, v)
--  myconfig.map('n', '<leader>7', ':ChatGPTRun add_tests<CR>')
--  myconfig.map('v', '<leader>7', ':ChatGPTRun add_tests<CR>')
--  -- bind leader-8: ChatGPTRun optimize_code (n, v)
--  myconfig.map('n', '<leader>8', ':ChatGPTRun optimize_code<CR>')
--  myconfig.map('v', '<leader>8', ':ChatGPTRun optimize_code<CR>')
--  -- bind leader-9: ChatGPTRun code_readability_analysis (n, v)
--  myconfig.map('n', '<leader>9', ':ChatGPTRun code_readability_analysis<CR>')
--  myconfig.map('v', '<leader>9', ':ChatGPTRun code_readability_analysis<CR>')
--  -- bind leader-0: ChatGPT (n, v)
--  myconfig.map('n', '<leader>0', ':ChatGPT<CR>')
--  myconfig.map('v', '<leader>0', ':ChatGPT<CR>')
--  -- bind leader-c: ChatGPTRun send_request (n, v, i)
--  myconfig.map('n', '<leader>c', ':ChatGPTRun send_request<CR>')
--  myconfig.map('v', '<leader>c', ':ChatGPTRun send_request<CR>')
--  myconfig.map('i', '<leader>c', ':ChatGPTRun send_request<CR>')
--end
--
--if myconfig.is_plugin_installed('gp') then
--  local gp_config = {
--    openai_api_key = os.getenv("OPENAI_API_KEY"),
--    providers = {
--      ollama = {
--        disable = false,
--        endpoint = "http://localhost:11434/v1/chat/completions",
--        -- secret = "dummy_secret",
--      },
--    }
--  }
--
--  --require("gp").setup({openai_api_key: os.getenv("OPENAI_API_KEY")})
--  require("gp").setup(gp_config)
--
--  -- bind leader-e: GpAppend (n, v)
--  myconfig.map('n', '<leader>e', ':GpAppend<CR>')
--  myconfig.map('v', '<leader>e', ':GpAppend<CR>')
--  -- bind leader-x: GpTabnew (n, v)
--  myconfig.map('n', '<leader>x', ':GpTabnew<CR>')
--  myconfig.map('v', '<leader>x', ':GpTabnew<CR>')
--  -- bind leader-c: GpNew (n, v)
--  myconfig.map('n', '<leader>c', ':GpNew<CR>')
--  myconfig.map('v', '<leader>c', ':GpNew<CR>')
--  -- bind leader-v: GpVnew (n, v)
--  myconfig.map('n', '<leader>v', ':GpVnew<CR>')
--  myconfig.map('v', '<leader>v', ':GpVnew<CR>')
--  -- bind leader-g: GpRewrite (n, v)
--  myconfig.map('n', '<leader>g', ':GpRewrite<CR>')
--  myconfig.map('v', '<leader>g', ':GpRewrite<CR>')
--  -- bind leader-6: GpImplement (n, v)
--  myconfig.map('n', '<leader>6', ':GpImplement<CR>')
--  myconfig.map('v', '<leader>6', ':GpImplement<CR>')
--  -- bind leader-7: GpChatRespond (n, v)
--  myconfig.map('n', '<leader>7', ':GpChatRespond<CR>')
--  myconfig.map('v', '<leader>7', ':GpChatRespond<CR>')
--  -- bind leader-8: GpNextAgent (n, v)
--  -- myconfig.map('n', '<leader>8', ':GpChatFinder<CR>')
--  -- myconfig.map('v', '<leader>8', ':GpChatFinder<CR>')
--  -- myconfig.map('n', '<leader>8', ':GpContext<CR>')
--  -- myconfig.map('v', '<leader>8', ':GpContext<CR>')
--  myconfig.map('n', '<leader>8', ':GpNextAgent<CR>')
--  myconfig.map('v', '<leader>8', ':GpNextAgent<CR>')
--  -- bind leader-9: GpChatNew (n, v)
--  myconfig.map('n', '<leader>9', ':GpChatNew<CR>')
--  myconfig.map('v', '<leader>9', ':GpChatNew<CR>')
--  -- bind leader-0: GpChatToggle (n, v)
--  myconfig.map('n', '<leader>0', ':GpChatToggle<CR>')
--  myconfig.map('v', '<leader>0', ':GpChatToggle<CR>')
--  -- There's also:
--  -- :GpAgent (for info)
--  -- :GpWhisper
--  -- :GpImage
--  -- :GpStop
--  -- etc.
--end

if myconfig.is_plugin_installed('chatgpt') then
  require("chatgpt").setup({
    openai_api_key = os.getenv("OPENAI_API_KEY"),
  })

  -- Monkey patch fix: Guard vim.fn.bufwinid against nil.
  -- The error originates deep in nui's _open_window where it calls
  -- vim.fn.bufwinid(component.bufnr) with a nil bufnr. Since vim.fn is a Lua table,
  -- we can shadow bufwinid with this guarded version:
  local _orig_bufwinid = vim.fn.bufwinid
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.bufwinid = function(bufnr)
    if type(bufnr) ~= "number" and type(bufnr) ~= "string" then
      vim.notify("[nui] bufwinid got nil bufnr, returning -1", vim.log.levels.DEBUG)
      return -1
    end
    return _orig_bufwinid(bufnr)
  end
end

if myconfig.is_plugin_installed('gp') then
  require("gp").setup({
    openai_api_key = os.getenv("OPENAI_API_KEY"),
    providers = {
      ollama = {
        disable = false,
        endpoint = "http://localhost:11434/v1/chat/completions",
      },
    },
  })
end

-- ai dispatcher: Checks mode at call time
local function ai(chatgpt_cmd, gp_cmd)
  return function()
    local mode = myconfig.get_ai_mode()
    if mode == "chatgpt" and myconfig.is_plugin_installed('chatgpt') then
      vim.cmd(chatgpt_cmd)
    elseif myconfig.is_plugin_installed('gp') then
      vim.cmd(gp_cmd)
    else
      vim.notify("No AI plugin available for mode: " .. mode, vim.log.levels.WARN)
    end
  end
end

-- Unified ai binds
local binds = {
  -- { lhs,          chatgpt_cmd,                           gp_cmd,          modes }
  -- bind leader-e: ChatGPTEditWithInstructions / GpAppend (n, v)
  { '<leader>e',  'ChatGPTEditWithInstructions',          'GpAppend',        {'n','v'} },
  -- bind leader-x: ChatGPTRun explain_code / GpTabnew (n, v)
  { '<leader>x',  'ChatGPTRun explain_code',              'GpTabnew',        {'n','v'} },
  -- bind leader-cc: ChatGPTRun complete_code / GpChatNew (n, v)
  { '<leader>cc', 'ChatGPTRun complete_code',             'GpChatNew',       {'n','v'} },
  -- bind leader-v: ChatGPTRun summarize / GpVnew (n, v)
  { '<leader>v',  'ChatGPTRun summarize',                 'GpVnew',          {'n','v'} },
  -- bind leader-g: ChatGPTRun grammar_correction / GpRewrite (n, v)
  { '<leader>g',  'ChatGPTRun grammar_correction',        'GpRewrite',       {'n','v'} },
  -- bind leader-6: ChatGPTRun docstring / GpImplement (n, v)
  { '<leader>6',  'ChatGPTRun docstring',                 'GpImplement',     {'n','v'} },
  -- bind leader-7: ChatGPTRun add_tests / GpChatRespond (n, v)
  { '<leader>7',  'ChatGPTRun add_tests',                 'GpChatRespond',   {'n','v'} },
  -- bind leader-8: ChatGPTRun optimize_code / GpNextAgent (n, v)
  { '<leader>8',  'ChatGPTRun optimize_code',             'GpNextAgent',     {'n','v'} },
  -- bind leader-9: ChatGPTRun code_readability_analysis / GpChatNew (n, v)
  { '<leader>9',  'ChatGPTRun code_readability_analysis', 'GpChatNew',       {'n','v'} },
  -- bind leader-0: ChatGPT / GpChatToggle (n, v)
  { '<leader>0',  'ChatGPT',                              'GpChatToggle',    {'n','v'} },
  -- bind leader-c: ChatGPTRun send_request / GpNew (n, v, i)
  { '<leader>c',  'ChatGPTRun send_request',              'GpNew',           {'n','v'} },
}

for _, b in ipairs(binds) do
  local lhs, cgpt, gp_cmd, modes = b[1], b[2], b[3], b[4]
  local fn = ai(cgpt, gp_cmd)
  for _, mode in ipairs(modes) do
    vim.keymap.set(mode, lhs, fn, { silent = true })
  end
end

-- ip helpers (used for local ai)
local function is_ipv4(s)
  return s and s:match("^%d+%.%d+%.%d+%.%d+$") ~= nil
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function get_ipv4_ps()
  local script = [[
$hostEntry = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName());
foreach ($addr in $hostEntry.AddressList) {
  if ($addr.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
    $ipStr = $addr.IPAddressToString
    if ($ipStr -ne '127.0.0.1' -and $ipStr -notlike '169.254.*') {
      Write-Output $ipStr
      break
    }
  }
}
]]

  local out = vim.fn.system({ "powershell", "-NoProfile", "-NonInteractive", "-Command", script })
  out = trim(out or "")
  return out
end

local function get_local_ipv4(debug)
  local function dbg_log(msg)
    if debug then
      print(msg)
      -- alternative:
      --vim.notify(msg, vim.log.levels.INFO)
    end
  end

  -- Windows: .NET DNS HostEntry approach
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    local out = get_ipv4_ps()
      -- debug
    --print("out (ps): " .. out)
    --print("shell_error (ps): " .. tostring(vim.v.shell_error))
    if is_ipv4(out) then
      dbg_log(("get_local_ipv4: %s (branch: windows/.NET DNS HostEntry)"):format(out))
      return out
    end
  end

  -- Linux
  if vim.fn.has("linux") == 1 then
    do
      local out = vim.fn.system([[sh -lc "ip addr show | grep -v 'inet6' | grep -v 'inet 127' | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d/ -f1"]]) or ""
      out = out:gsub("inet", "")
      out = trim(out)
      -- debug
      --print("out (ip addr): " .. out)
      if is_ipv4(out) then
        dbg_log(("get_local_ipv4: %s (branch: linux/ip addr)"):format(out))
        return out
      end
    end

    do
      local out = trim(vim.fn.system([[sh -lc "ip route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \\([0-9.]\\+\\).*/\\1/p' | head -n1"]]) or "")
      if is_ipv4(out) then
        dbg_log(("get_local_ipv4: %s (branch: linux/ip route get src)"):format(out))
        return out
      end
    end
  end

  -- Universal fallback: UDP route trick via python
  do
    local cmd = [[python -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('8.8.8.8',80)); print(s.getsockname()[0]); s.close()"]]
    local out = trim(vim.fn.system(cmd) or "")
    if is_ipv4(out) then
      dbg_log(("get_local_ipv4: %s (branch: python/udp route trick)"):format(out))
      return out
    end
  end

  dbg_log("get_local_ipv4: 127.0.0.1 (branch: default)")
  return "127.0.0.1"
end

-- Basic llama.cpp example request (no streaming)
local function llm()
  local should_debug_print = myconfig.should_debug_print()

  --local url = "http://127.0.0.1:8080/completion"
  --local url = "http://localhost:8080/completion"
  local ip = get_local_ipv4()
  if should_debug_print then
    print("local ip: " .. ip)
  end
  local url = ("http://%s:8080/completion"):format(ip)

  local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

  local json_payload = {
    temp = 0.72,
    top_k = 100,
    top_p = 0.73,
    repeat_penalty = 1.100000023841858,
    n_predict = 256,
    stop = {"\n\n\n"},
    stream = false,
    prompt = buffer_content
  }

  local curl_command = 'curl -k -s -X POST -H "Content-Type: application/json" -d @- ' .. url
  local response = vim.fn.system(curl_command, vim.fn.json_encode(json_payload))
  --local content = vim.fn.json_decode(response).content
  --local decoded_response = vim.fn.json_decode(response)
  local success, decoded_response = pcall(vim.fn.json_decode, response)
  if not success then
    decoded_response = nil
  end

  local default_msg = "llama is sleeping"
  local content = (decoded_response and decoded_response.content) or default_msg

  local split_newlines = vim.split(content, '\n', true)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)
  lines[1] = lines[1] .. split_newlines[1]
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, lines)
  vim.api.nvim_buf_set_lines(0, line_num, line_num, false, vim.list_slice(split_newlines, 2))
end

-- Default Ollama model (can be overridden by passing an argument to :Ollama / :OllamaStream)
local ollama_model = "llama3.2"

-- Basic Ollama request (no streaming). Mirrors llm() but talks to /api/generate.
local function ollama(model_override)
  local should_debug_print = myconfig.should_debug_print()

  --local url = "http://127.0.0.1:11434/api/generate"
  local url = "http://localhost:11434/api/generate"
  --local ip = get_local_ipv4()
  --if should_debug_print then
  --  print("local ip: " .. ip)
  --end
  --local url = ("http://%s:11434/api/generate"):format(ip)

  local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

  local json_payload = {
    model = (model_override and model_override ~= "") and model_override or ollama_model,
    prompt = buffer_content,
    stream = false,
  }

  local curl_command = 'curl -k -s -X POST -H "Content-Type: application/json" -d @- ' .. url
  local response = vim.fn.system(curl_command, vim.fn.json_encode(json_payload))
  local success, decoded_response = pcall(vim.fn.json_decode, response)
  if not success then
    decoded_response = nil
  end

  local default_msg = "ollama is sleeping"
  -- Ollama puts generated text in `.response` (unlike llama.cpp's `.content`)
  local content = (decoded_response and decoded_response.response) or default_msg

  local split_newlines = vim.split(content, '\n', true)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)
  lines[1] = lines[1] .. split_newlines[1]
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, lines)
  vim.api.nvim_buf_set_lines(0, line_num, line_num, false, vim.list_slice(split_newlines, 2))
end

-- Streaming helpers --------------------------------------------------------

-- Create a streaming inserter that appends chunks to the buffer at the
-- cursor line. Each call appends `text` (which may contain newlines) right
-- after whatever has been inserted so far. Mirrors the insertion behaviour
-- of the non-streaming llm() function.
local function make_stream_inserter()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  return function(text)
    if not text or text == "" then return end
    local parts = vim.split(text, '\n', true)
    local existing = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)
    if #existing == 0 then existing = {""} end
    existing[1] = existing[1] .. parts[1]
    vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, existing)
    if #parts > 1 then
      local new_lines = vim.list_slice(parts, 2)
      vim.api.nvim_buf_set_lines(0, current_line, current_line, false, new_lines)
      current_line = current_line + #new_lines
    end
  end
end

-- jobstart's on_stdout splits bytes by \n but a single logical line can be
-- split across multiple callbacks. Per :h channel-lines, the first chunk
-- continues whatever was pending and the last chunk is the new pending.
-- Returns (on_stdout_handler, flush_pending) where flush_pending should be
-- called from on_exit to emit any unterminated trailing line.
local function make_line_handler(process_line)
  local pending = ""
  local function on_stdout(_, data, _)
    if not data or #data == 0 then return end
    pending = pending .. data[1]
    for i = 2, #data do
      if pending ~= "" then
        process_line(pending)
      end
      pending = data[i]
    end
  end
  local function flush()
    if pending ~= "" then
      process_line(pending)
      pending = ""
    end
  end
  return on_stdout, flush
end

-- Streaming llama.cpp request. llama.cpp uses Server-Sent Events: each event
-- arrives as a line "data: {json}" with `content` carrying the next token.
local function llm_stream()
  local should_debug_print = myconfig.should_debug_print()
  local ip = get_local_ipv4()
  if should_debug_print then
    print("local ip: " .. ip)
  end
  local url = ("http://%s:8080/completion"):format(ip)

  local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

  local json_payload = vim.fn.json_encode({
    temp = 0.72,
    top_k = 100,
    top_p = 0.73,
    repeat_penalty = 1.100000023841858,
    n_predict = 256,
    stop = {"\n\n\n"},
    stream = true,
    prompt = buffer_content,
  })

  local insert_chunk = make_stream_inserter()

  local process_line = function(line)
    local json_str = line:match("^data:%s*(.+)$")
    if not json_str then return end
    local ok, parsed = pcall(vim.fn.json_decode, json_str)
    if ok and parsed and parsed.content then
      insert_chunk(parsed.content)
    end
  end

  local on_stdout, flush = make_line_handler(process_line)

  -- -N disables curl's output buffering so we get tokens as they arrive
  local cmd = { "curl", "-k", "-s", "-N", "-X", "POST",
                "-H", "Content-Type: application/json",
                "-d", "@-", url }

  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = on_stdout,
    on_stderr = function(_, data, _)
      if not data then return end
      for _, line in ipairs(data) do
        if line and line ~= "" and should_debug_print then
          print("llm_stream stderr: " .. line)
        end
      end
    end,
    on_exit = function(_, code, _)
      flush()
      if code ~= 0 and should_debug_print then
        print("llm_stream: curl exited with code " .. code)
      end
    end,
  })

  if job_id <= 0 then
    print("llm_stream: failed to start curl job")
    return
  end

  vim.fn.chansend(job_id, json_payload)
  vim.fn.chanclose(job_id, "stdin")
end

-- Streaming Ollama request. Ollama uses JSONL: one JSON object per line,
-- with the generated text in `.response` and a final object having
-- `done = true`.
local function ollama_stream(model_override)
  local should_debug_print = myconfig.should_debug_print()

  --local url = "http://127.0.0.1:11434/api/generate"
  local url = "http://localhost:11434/api/generate"
  --local ip = get_local_ipv4()
  --if should_debug_print then
  --  print("local ip: " .. ip)
  --end
  --local url = ("http://%s:11434/api/generate"):format(ip)

  local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

  local json_payload = vim.fn.json_encode({
    model = (model_override and model_override ~= "") and model_override or ollama_model,
    prompt = buffer_content,
    stream = true,
  })

  local insert_chunk = make_stream_inserter()

  local process_line = function(line)
    if not line or line == "" then return end
    local ok, parsed = pcall(vim.fn.json_decode, line)
    if ok and parsed and parsed.response then
      insert_chunk(parsed.response)
    end
  end

  local on_stdout, flush = make_line_handler(process_line)

  local cmd = { "curl", "-k", "-s", "-N", "-X", "POST",
                "-H", "Content-Type: application/json",
                "-d", "@-", url }

  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = on_stdout,
    on_stderr = function(_, data, _)
      if not data then return end
      for _, line in ipairs(data) do
        if line and line ~= "" and should_debug_print then
          print("ollama_stream stderr: " .. line)
        end
      end
    end,
    on_exit = function(_, code, _)
      flush()
      if code ~= 0 and should_debug_print then
        print("ollama_stream: curl exited with code " .. code)
      end
    end,
  })

  if job_id <= 0 then
    print("ollama_stream: failed to start curl job")
    return
  end

  vim.fn.chansend(job_id, json_payload)
  vim.fn.chanclose(job_id, "stdin")
end

-- cmd Llm: send basic llama.cpp request
vim.api.nvim_create_user_command('Llm', llm, {})
-- cmd LlmStream: send basic llama.cpp request using streaming
vim.api.nvim_create_user_command('LlmStream', llm_stream, {})
-- cmd Ollama: send basic ollama request
vim.api.nvim_create_user_command('Ollama', function(opts)
  ollama(opts.args)
end, { nargs = '?' })
-- cmd OllamaStream: send basic ollama request using streaming
vim.api.nvim_create_user_command('OllamaStream', function(opts)
  ollama_stream(opts.args)
end, { nargs = '?' })

-- cmd LocalIP: debug commad for trying to get local ip
vim.api.nvim_create_user_command("LocalIP", function()
  local ip = get_local_ipv4(true)
  --vim.notify("Local IPv4: " .. ip, vim.log.levels.INFO)
  -- alternative:
  print("Local IPv4: " .. ip)
end, {})

if myconfig.is_plugin_installed('model') then
  local llamacpp = require('model.providers.llamacpp')
  --local url = "http://localhost:8080"
  local ip = get_local_ipv4()
  local url = ("http://%s:8080"):format(ip)

  require('model').setup({
    prompts = {
      zephyr = {
        provider = llamacpp,
        options = {
          url = url,
        },
        builder = function(input, context)
          return {
            prompt =
              '<|system|>'
              .. (context.args or 'You are a helpful assistant')
              .. '\n</s>\n<|user|>\n'
              .. input
              .. '</s>\n<|assistant|>',
            stop = { '</s>' }
          }
        end
      }
    }
  })

  -- bind m--: Model zephyr (n, i, v)
  vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
else
  -- bind m--: Llm (n, i, v)
  vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
end

local my_notes_path = myconfig.my_notes_path

-- cmd PrintAiModels: print all AI models via python script
vim.api.nvim_create_user_command('PrintAiModels', function()
  local script_path = my_notes_path .. "/scripts/gpt/gpt/print_all_models.py"

  local file_exists = vim.fn.filereadable(script_path) == 1
  if not file_exists then
    print("Error: The script file '" .. script_path .. "' does not exist.")
    return
  end

  local output = vim.fn.systemlist("python " .. script_path)
  for i, line in ipairs(output) do
    output[i] = line:gsub('\r', '')
  end
  vim.api.nvim_put(output, 'l', true, true)
end, {})

local function normalize_provider(provider)
  local cleaned_provider = provider:lower():gsub("[-_]", "")
  -- Map some values
  if cleaned_provider:find("gpt") then
    return "openai"
  elseif cleaned_provider == "claude" then
    return "anthropic"
  elseif cleaned_provider:find("google") or cleaned_provider == "gemini" then
    return "googleai"
  else
    return cleaned_provider
  end
end

-- cmd PrintAiModelsByRequest: fetch and print AI models by API request
vim.api.nvim_create_user_command('PrintAiModelsByRequest', function(opts)
  local should_debug_print = myconfig.should_debug_print()
  local api_key, url, curl_cmd

  local provider = opts.args:lower() == "" and "openai" or opts.args:lower()
  provider = normalize_provider(provider)

  if should_debug_print then
    print("provider arg: " .. provider)
  end

  if provider == "openai" then
    api_key = os.getenv("OPENAI_API_KEY")

    if not api_key then
      print("Error: OPENAI_API_KEY is not set.")
      return
    end

    url = "https://api.openai.com/v1/models"
    curl_cmd = 'curl -s -H "Authorization: Bearer ' .. api_key .. '" ' .. url
  elseif provider == "anthropic" then
    api_key = os.getenv("ANTHROPIC_API_KEY")

    if not api_key then
      print("Error: ANTHROPIC_API_KEY is not set.")
      return
    end

    url = "https://api.anthropic.com/v1/models"
    curl_cmd = 'curl -s -H "x-api-key: ' .. api_key .. '" -H "anthropic-version: 2023-06-01" ' .. url
  elseif provider == "googleai" then
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")

    if not api_key then
      print("Error: GEMINI_API_KEY or GOOGLE_API_KEY is not set.")
      return
    end

    url = "https://generativelanguage.googleapis.com/v1beta/models"
    curl_cmd = 'curl -s -H "x-goog-api-key: ' .. api_key .. '" ' .. url
  else
    print("Error: Unknown provider. Use 'openai', 'anthropic', or 'googleai'.")
    return
  end

  if should_debug_print then
    print("curl command: " .. curl_cmd)
  end

  local result = vim.fn.systemlist(curl_cmd)

  if vim.v.shell_error ~= 0 then
    print("Error fetching models: " .. table.concat(result, "\n"))
    return
  end

  if should_debug_print then
    print("Raw response:\n" .. table.concat(result, "\n"))
  end

  local models = {}
  local success, data = pcall(vim.fn.json_decode, table.concat(result, "\n"))

  if success then
    if provider == "openai" then
      for _, model in ipairs(data.data) do
        table.insert(models, model.id)
      end
    elseif provider == "anthropic" then
      for _, model in ipairs(data.data) do
        table.insert(models, model.id)
      end
    elseif provider == "googleai" then
      for _, model in ipairs(data.models) do
        table.insert(models, model.name)
      end
    end

    vim.api.nvim_put({table.concat(models, ", ")}, 'l', true, true)
  else
    print("Error parsing JSON response.")
  end
end, {
  nargs = "?",
  complete = function(ArgLead, CmdLine, CursorPos)
    return { 'openai', 'anthropic', 'googleai' }
  end
})
