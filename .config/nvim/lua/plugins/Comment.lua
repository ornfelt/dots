return {
  "numToStr/Comment.nvim",
  lazy = false,
  opts = {
    ---Add a space b/w comment and the line
    padding = false,
    ---Whether the cursor should stay at its position
    sticky = true,
    ---Lines to be ignored while (un)comment
    ignore = nil,
    ---LHS of toggle mappings in NORMAL mode
    toggler = {
      --line = 'gc',
      -- map: <C-k> -> toggle comment
      line = '<C-k>',
      block = 'gb',
    },
    ---LHS of operator-pending mappings in NORMAL and VISUAL mode
    opleader = {
      --line = 'gc',
      line = '<C-k>',
      block = 'gb',
    },
    ---LHS of extra mappings
    extra = {
      ---Add comment on the line above
      above = 'gcO',
      ---Add comment on the line below
      below = 'gco',
      ---Add comment at the end of line
      eol = 'gcA',
    },
    ---Enable keybindings
    ---NOTE: If given `false` then the plugin won't create any mappings
    mappings = {
      ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
      basic = true,
      ---Extra mapping; `gco`, `gcO`, `gcA`
      extra = true,
    },
    ---Function to call before (un)comment
    pre_hook = nil,
    ---Function to call after (un)comment
    post_hook = nil,
  },
}
