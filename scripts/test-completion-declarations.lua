-- Run from the config directory: nvim --headless -u NONE -i NONE -n '+luafile scripts/test-completion-declarations.lua'
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. '.cpp')
vim.bo.filetype = 'cpp'
local completion = require('config.completion')
local function later(fn)
    vim.defer_fn(function()
        local ok, err = pcall(fn)
        if not ok then print(err); vim.cmd('cquit 1') end
    end, 350)
end
local items = {
    { label='mainValue', kind=6 },
    { label='make', kind=3, insertTextFormat=2, insertText='make(${1:arg})' },
    { label='main', kind=15, insertTextFormat=2, insertText='int main() {\n$0\n}' },
    { label='macro', kind=14, insertTextFormat=2, insertText='if (${1:test}) $0' },
    { label='mainBlock', kind=3, insertTextFormat=2, insertText='int main() {\n$0\n}' },
}
assert(#completion.filter_result(vim.deepcopy(items)) == 2)
assert(#completion.filter_result({items=vim.deepcopy(items), isIncomplete=true}).items == 2)
local keyword = completion.filter_result({itemDefaults={insertTextFormat=2}, items={{label='for',kind=14,insertText='for ($1) $0'}}}).items[1]
assert(keyword.insertText == 'for' and keyword.insertTextFormat == 1)
assert(#completion.filter_result({itemDefaults={insertTextFormat=2}, items={{label='return',kind=14}}}).items == 1)
vim.api.nvim_create_autocmd('LspAttach', {callback=function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    completion.attach(client, ev.buf)
    if client.name == 'prefixed-snippets' then return end
    local cases = {
        { 'int ma', false },
        { 'class Ma', false },
        { 'int f(int ma', false },
        { 'int value = ma', true },
        { 'object.ma', true },
        { 'ma', true },
        { 'snipma', true },
    }
    local function run(index)
        local case = cases[index]
        if not case then
            print('PASS: declaration menus suppressed; types, expressions, members, and snip templates preserved')
            vim.cmd('qa!')
            return
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { '' })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        vim.api.nvim_input('i' .. case[1])
        later(function()
            assert((vim.fn.pumvisible() == 1) == case[2],
                case[1] .. ': ' .. vim.inspect(vim.fn.complete_info().items))
            vim.api.nvim_input('<C-e><Esc>')
            later(function() run(index + 1) end)
        end)
    end
    later(function() run(1) end)
end})
vim.lsp.start({name='test',cmd=function()
    local closing=false
    return {
        request=function(method, params, callback)
            local result
            if method=='initialize' then result={capabilities={completionProvider={resolveProvider=true}}}
            elseif method=='textDocument/completion' then result=vim.deepcopy(items)
            elseif method=='completionItem/resolve' then result=params end
            vim.schedule(function() callback(nil,result) end)
            return true,1
        end,
        notify=function() return true end,
        is_closing=function() return closing end,
        terminate=function() closing=true end,
    }
end})
vim.defer_fn(function() print('TIMEOUT'); vim.cmd('cquit 1') end,12000)
