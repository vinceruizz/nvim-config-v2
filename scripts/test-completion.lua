-- Run from the config directory: nvim --headless -u NONE -i NONE -n '+luafile scripts/test-completion.lua'
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
    later(function()
        vim.api.nvim_input('ima')
        later(function()
            local choices = vim.fn.complete_info().items
            assert(#choices == 2, 'Expected symbol and callable only: ' .. vim.inspect(choices))
            vim.api.nvim_input('<C-e><Esc>')
            later(function()
                vim.api.nvim_buf_set_lines(0,0,-1,false,{''})
                vim.api.nvim_input('isnipma')
                later(function()
                    local snippets = vim.fn.complete_info().items
                    assert(#snippets == 1 and snippets[1].abbr == 'snipmain', vim.inspect(snippets))
                    vim.api.nvim_input('<Tab><CR>')
                    later(function()
                        local text = table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\n')
                        assert(text:find('int main()', 1, true), text)
                        assert(not text:find('snip', 1, true), text)
                        print('PASS: snippet filtering, preserved function placeholders, snip prefix, C++ template expansion')
                        vim.cmd('qa!')
                    end)
                end)
            end)
        end)
    end)
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
vim.defer_fn(function() print('TIMEOUT'); vim.cmd('cquit 1') end,8000)
