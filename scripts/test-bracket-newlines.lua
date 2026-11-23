-- Run from the config directory with installed plugins:
-- nvim --headless -u NONE -i NONE -n '+luafile scripts/test-bracket-newlines.lua'
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/nvim-autopairs')
require('nvim-autopairs').setup({})
vim.bo.autoindent=true
vim.bo.smartindent=true
vim.bo.expandtab=true
vim.bo.shiftwidth=4
local later=function(fn) vim.defer_fn(function() local ok,err=pcall(fn); if not ok then print(err); vim.cmd('cquit 1') end end,150) end
vim.api.nvim_create_autocmd('LspAttach',{callback=function(ev)
    require('config.completion').attach(vim.lsp.get_client_by_id(ev.data.client_id),ev.buf)
    local cases = {
        { key = '{', lines = { '{', '    ', '}' }, cursor = { 2, 4 } },
        { key = '(', lines = { '(', '', ')' }, cursor = { 2, 0 } },
        { key = '{', menu = true, lines = { '{', '    ', '}' }, cursor = { 2, 4 } },
    }
    local function run(index)
        local case = cases[index]
        if not case then
            print('PASS: braces, parentheses, cursor placement, and newline with unselected completion menu')
            vim.cmd('qa!')
            return
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { '' })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        vim.api.nvim_input('i' .. case.key)
        later(function()
            if case.menu then vim.fn.complete(2, { 'example' }) end
            vim.api.nvim_input('<CR>')
            later(function()
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                assert(vim.deep_equal(lines, case.lines), vim.inspect(lines))
                assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), case.cursor),
                    vim.inspect(vim.api.nvim_win_get_cursor(0)))
                vim.api.nvim_input('<Esc>')
                later(function() run(index + 1) end)
            end)
        end)
    end
    run(1)
end})
vim.lsp.start({name='test',cmd=function()
    local closing=false
    return {request=function(method,params,cb)
        vim.schedule(function() cb(nil,method=='initialize' and {capabilities={completionProvider={}}} or {}) end)
        return true,1
    end,notify=function() return true end,is_closing=function() return closing end,terminate=function() closing=true end}
end})
vim.defer_fn(function() vim.cmd('cquit 1') end,4000)
