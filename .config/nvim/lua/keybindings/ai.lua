local myconfig = require("myconfig")

-- GPT binds
if myconfig.is_plugin_installed('chatgpt') then
  local chatgpt_config = {
    openai_api_key = os.getenv("OPENAI_API_KEY"),
  }

  -- Model can be changed in actions for this plugin
  require("chatgpt").setup(chatgpt_config)

  myconfig.map('n', '<leader>e', ':ChatGPTEditWithInstructions<CR>')
  myconfig.map('v', '<leader>e', ':ChatGPTEditWithInstructions<CR>')
  myconfig.map('n', '<leader>x', ':ChatGPTRun explain_code<CR>')
  myconfig.map('v', '<leader>x', ':ChatGPTRun explain_code<CR>')
  myconfig.map('n', '<leader>c', ':ChatGPTRun complete_code<CR>')
  myconfig.map('v', '<leader>c', ':ChatGPTRun complete_code<CR>')
  myconfig.map('n', '<leader>v', ':ChatGPTRun summarize<CR>')
  myconfig.map('v', '<leader>v', ':ChatGPTRun summarize<CR>')
  myconfig.map('n', '<leader>g', ':ChatGPTRun grammar_correction<CR>')
  myconfig.map('v', '<leader>g', ':ChatGPTRun grammar_correction<CR>')
  myconfig.map('n', '<leader>6', ':ChatGPTRun docstring<CR>')
  myconfig.map('v', '<leader>6', ':ChatGPTRun docstring<CR>')
  myconfig.map('n', '<leader>7', ':ChatGPTRun add_tests<CR>')
  myconfig.map('v', '<leader>7', ':ChatGPTRun add_tests<CR>')
  myconfig.map('n', '<leader>8', ':ChatGPTRun optimize_code<CR>')
  myconfig.map('v', '<leader>8', ':ChatGPTRun optimize_code<CR>')
  myconfig.map('n', '<leader>9', ':ChatGPTRun code_readability_analysis<CR>')
  myconfig.map('v', '<leader>9', ':ChatGPTRun code_readability_analysis<CR>')
  myconfig.map('n', '<leader>0', ':ChatGPT<CR>')
  myconfig.map('v', '<leader>0', ':ChatGPT<CR>')
  myconfig.map('n', '<M-c>', ':ChatGPTRun send_request<CR>')
  myconfig.map('v', '<M-c>', ':ChatGPTRun send_request<CR>')
  myconfig.map('i', '<M-c>', ':ChatGPTRun send_request<CR>')
end

if myconfig.is_plugin_installed('gp') then
  local gp_config = {
    openai_api_key = os.getenv("OPENAI_API_KEY"),
    providers = {
      ollama = {
        disable = false,
        endpoint = "http://localhost:11434/v1/chat/completions",
        -- secret = "dummy_secret",
      },
    }
  }

  --require("gp").setup({openai_api_key: os.getenv("OPENAI_API_KEY")})
  require("gp").setup(gp_config)

  myconfig.map('n', '<leader>e', ':GpAppend<CR>')
  myconfig.map('v', '<leader>e', ':GpAppend<CR>')
  myconfig.map('n', '<leader>x', ':GpTabnew<CR>')
  myconfig.map('v', '<leader>x', ':GpTabnew<CR>')
  myconfig.map('n', '<leader>c', ':GpNew<CR>')
  myconfig.map('v', '<leader>c', ':GpNew<CR>')
  myconfig.map('n', '<leader>v', ':GpVnew<CR>')
  myconfig.map('v', '<leader>v', ':GpVnew<CR>')
  myconfig.map('n', '<leader>g', ':GpRewrite<CR>')
  myconfig.map('v', '<leader>g', ':GpRewrite<CR>')
  myconfig.map('n', '<leader>6', ':GpImplement<CR>')
  myconfig.map('v', '<leader>6', ':GpImplement<CR>')
  myconfig.map('n', '<leader>7', ':GpChatRespond<CR>')
  myconfig.map('v', '<leader>7', ':GpChatRespond<CR>')
  -- myconfig.map('n', '<leader>8', ':GpChatFinder<CR>')
  -- myconfig.map('v', '<leader>8', ':GpChatFinder<CR>')
  -- myconfig.map('n', '<leader>8', ':GpContext<CR>')
  -- myconfig.map('v', '<leader>8', ':GpContext<CR>')
  myconfig.map('n', '<leader>8', ':GpNextAgent<CR>')
  myconfig.map('v', '<leader>8', ':GpNextAgent<CR>')
  myconfig.map('n', '<leader>9', ':GpChatNew<CR>')
  myconfig.map('v', '<leader>9', ':GpChatNew<CR>')
  myconfig.map('n', '<leader>0', ':GpChatToggle<CR>')
  myconfig.map('v', '<leader>0', ':GpChatToggle<CR>')
  -- There's also:
  -- :GpAgent (for info)
  -- :GpWhisper
  -- :GpImage
  -- :GpStop
  -- etc.
end

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
  --local url = "http://127.0.0.1:8080/completion"
  local should_debug_print = myconfig.should_debug_print()
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

vim.api.nvim_create_user_command('Llm', llm, {})

-- Debug commad for trying to get local ip
vim.api.nvim_create_user_command("LocalIP", function()
  local ip = get_local_ipv4(true)
  --vim.notify("Local IPv4: " .. ip, vim.log.levels.INFO)
  -- alternative:
  print("Local IPv4: " .. ip)
end, {})

if myconfig.is_plugin_installed('model') then
  local llamacpp = require('model.providers.llamacpp')

  require('model').setup({
    prompts = {
      zephyr = {
        provider = llamacpp,
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

  vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
else
  vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
end

local my_notes_path = myconfig.my_notes_path

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

-- Fetch models via request
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

