-- Requires clangd. Run from the config directory:
-- nvim --headless -u NONE -i NONE -n '+luafile scripts/test-keyword-completion.lua'
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. '.cpp')
vim.bo.filetype = 'cpp'
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'int main() { ' })
local function later(fn)
    vim.defer_fn(function()
        local ok, err = pcall(fn)
        if not ok then print(err); vim.cmd('cquit 1') end
    end, 500)
end
local cases = { { 'i', 'if' }, { 'wh', 'while' } }
local function run(index)
    local case = cases[index]
    if not case then
        print('PASS: real clangd if/while appear and accept as plain keywords, without template expansion')
        vim.cmd('qa!')
        return
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'int main() { ' })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.api.nvim_input('A' .. case[1])
    later(function()
        local items = vim.fn.complete_info().items
        local selected
        for i, item in ipairs(items) do
            if item.abbr == case[2] then
                assert(item.kind == 'Keyword', vim.inspect(item))
                selected = i
            end
        end
        assert(selected, 'Missing ' .. case[2] .. ': ' .. vim.inspect(items))
        vim.api.nvim_input(string.rep('<C-n>', selected) .. '<CR>')
        later(function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            assert(vim.deep_equal(lines, { 'int main() { ' .. case[2] }), vim.inspect(lines))
            vim.api.nvim_input('<Esc>')
            later(function() run(index + 1) end)
        end)
    end)
end
vim.api.nvim_create_autocmd('LspAttach', { callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    require('config.completion').attach(client, ev.buf)
    if client.name == 'keyword-test' then later(function() run(1) end) end
end })
assert(vim.lsp.start({ name = 'keyword-test', cmd = { 'clangd', '--all-scopes-completion=false' }, root_dir = vim.fn.getcwd() }))
vim.defer_fn(function() print('TIMEOUT'); vim.cmd('cquit 1') end, 10000)
