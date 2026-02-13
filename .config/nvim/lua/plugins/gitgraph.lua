require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "ornfelt/gitgraph.nvim",
  dependencies = {
    "sindrets/diffview.nvim",
  },
  config = function()
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
  end,
  lazy = true,
}
