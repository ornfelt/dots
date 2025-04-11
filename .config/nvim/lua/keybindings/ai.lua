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

-- Basic llama.cpp example request (no streaming)
local function llm()
  local url = "http://127.0.0.1:8080/completion"
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

