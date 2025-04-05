vim.o.completeopt = 'menu,menuone,noinsert,popup,fuzzy'

-- Keymaps (TODO: update)
local pumMaps = {
  ['<Down>'] = '<C-n>',
  ['<Up>'] = '<C-p>',
  ['<CR>'] = '<C-y>',
}
for insertKmap, pumKmap in pairs(pumMaps) do
  vim.keymap.set('i', insertKmap, function()
    return vim.fn.pumvisible() == 1 and pumKmap or insertKmap
  end, { expr = true })
end

vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, { noremap = true, silent = true })

local setup = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if not client.server_capabilities.completionProvider then
        return
    end

    -- TODO: backspace?
    client.server_capabilities.completionProvider.triggerCharacters = vim.split("qwertyuiopasdfghjklzxcvbnm. ", "")
    vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })

    -- This shows docs alongside the current completion item
    local _, cancel_prev = nil, function() end
    vim.api.nvim_create_autocmd('CompleteChanged', {
        buffer = args.buf,
        callback = function()
            cancel_prev()
            local info = vim.fn.complete_info({ 'selected' })
            local completionItem = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
            if nil == completionItem then
                return
            end
            _, cancel_prev = vim.lsp.buf_request(args.buf,
            vim.lsp.protocol.Methods.completionItem_resolve,
            completionItem,
            function(err, item, ctx)
                if not item then
                    return
                end
                local docs = (item.documentation or {}).value
                local win = vim.api.nvim__complete_set(info['selected'], { info = docs })
                if win.winid and vim.api.nvim_win_is_valid(win.winid) then
                    vim.treesitter.start(win.bufnr, 'markdown')
                    vim.wo[win.winid].conceallevel = 3
                end
            end)
        end
    })
end

local M = {
    setup = setup,
}

return M
