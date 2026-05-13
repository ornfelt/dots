require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/ornfelt/gitgraph.nvim",
  dependencies = {
    "https://github.com/dlyongemallo/diffview.nvim",
  },
  config = function()
    local function do_setup()
      require("gitgraph").setup({
        symbols = {
          merge_commit = "M",
          commit = "*",
        },
        format = {
          timestamp = "%H:%M:%S %d-%m-%Y",
          fields = { "hash", "timestamp", "author", "branch_name", "tag" },
        },
        hooks = {
          on_select_commit = function(commit)
            vim.notify("DiffviewOpen " .. commit.hash .. "^!")
            vim.cmd(":DiffviewOpen " .. commit.hash .. "^!")
          end,
          on_select_range_commit = function(from, to)
            vim.notify("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
            vim.cmd(":DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
          end,
        },
      })
    end

    -- Run after init.lua finishes (so :colorscheme has already been applied),
    -- mirroring lazy.nvim's deferred load.
    if vim.v.vim_did_enter == 1 then
      do_setup()
    else
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = do_setup,
      })
    end
  end,
}
