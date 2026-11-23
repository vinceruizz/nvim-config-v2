-- Run from the config directory with the installed Treesitter parsers:
-- nvim --headless -u NONE -i NONE -n -l scripts/test-completion-context.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.o.virtualedit = 'onemore'
local context = require('config.completion_context')
local cases = {
    -- The | marker is the insertion point. True means hide suggestions.
    { 'c', 'int mai|', true },
    { 'c', 'int *ptr|;', true },
    { 'c', 'int a, oth|;', true },
    { 'cpp', 'Widget val|;', true },
    { 'cpp', 'auto val| = obj;', true },
    { 'cpp', 'auto [first, sec|] = pair;', true },
    { 'cpp', 'class Wid|', true },
    { 'cpp', 'int fun(int par|) {}', true },
    { 'cpp', 'int fun(int par|', true },
    { 'cpp', 'int fun() {\n    Widget val|;\n}', true },
    { 'cpp', 'std::vector<int> val|;', true },
    { 'cpp', 'int f() { int val| }', true },
    { 'cpp', 'int x = oth|;', false },
    { 'cpp', 'void f() { return oth|; }', false },
    { 'cpp', 'obj.met|', false },
    { 'cpp', 'std::vec|', false },
    { 'cpp', 'Wid| value;', false },
    { 'cpp', 'int values[siz|];', false },
    { 'cpp', 'int f(int p = oth|) {}', false },
    { 'cpp', 'int snip|', false },
    { 'python', 'def nam|', true },
    { 'python', 'async def nam|', true },
    { 'python', 'class Nam|', true },
    { 'python', 'def f(par|): pass', true },
    { 'python', 'def f(par|', true },
    { 'python', 'def f(\n    par|', true },
    { 'python', 'var| = 1', true },
    { 'python', 'for val| in xs: pass', true },
    { 'python', 'def f(arg: Typ|): pass', false },
    { 'python', 'def f(arg=oth|): pass', false },
    { 'python', 'def f(arg=oth|', false },
    { 'python', 'val = oth|', false },
    { 'python', 'obj.att|', false },
    { 'python', 'var|', false }, -- Ambiguous until an assignment is written.
    { 'lua', 'local nam|', true },
    { 'lua', 'local function nam|', true },
    { 'lua', 'function nam|', true },
    { 'lua', 'local a, nam|', true },
    { 'lua', 'function f(par|) end', true },
    { 'lua', 'function f(par|', true },
    { 'lua', 'function f(\n    par|', true },
    { 'lua', 'local a = oth|', false },
    { 'lua', 'return oth|', false },
    { 'javascript', 'const nam|', true },
    { 'javascript', 'let nam| = 1;', true },
    { 'javascript', 'function nam|', true },
    { 'javascript', 'class Nam|', true },
    { 'javascript', 'class X { nam| }', true },
    { 'javascript', 'const f = nam| => 1;', true },
    { 'javascript', 'function f(par|) {}', true },
    { 'javascript', 'function f(par|', true },
    { 'javascript', 'function f(\n    par|', true },
    { 'javascript', 'function f(p = oth|', false },
    { 'javascript', 'const {foo: nam|} = obj;', true },
    { 'javascript', 'const {foo = oth|} = obj;', false },
    { 'javascript', 'const {foo| = other} = obj;', true },
    { 'javascript', 'function f(p = oth|) {}', false },
    { 'javascript', 'const obj = {key: val|};', false },
    { 'javascript', 'const a = oth|;', false },
    { 'javascript', 'obj.met|', false },
    { 'typescript', 'interface Nam|', true },
    { 'typescript', 'class X { nam|: string; }', true },
    { 'typescript', 'type Nam| = string', true },
    { 'typescript', 'const nam|: number = 1;', true },
    { 'typescript', 'function f(par|: string) {}', true },
    { 'typescript', 'function f(p: Typ|) {}', false },
    { 'typescript', 'type X = Typ|', false },
    { 'typescriptreact', 'const nam| = 1;', true },
    { 'javascriptreact', 'const a = obj.met|;', false },
    { 'java', 'class Nam|', true },
    { 'java', 'class X { int nam|; }', true },
    { 'java', 'class X { void nam| }', true },
    { 'java', 'class X { void f(int par|) {} }', true },
    { 'java', 'class X { void f(Typ| p) {} }', false },
    { 'java', 'class X { int p = oth|; }', false },
    { 'cs', 'class Nam|', true },
    { 'cs', 'class X { int nam|; }', true },
    { 'cs', 'class X { void nam| }', true },
    { 'cs', 'class X { void f(int par|) {} }', true },
    { 'cs', 'class X { void f(Typ| p) {} }', false },
    { 'cs', 'class X { int p = oth|; }', false },
    { 'python', '# class Nam|', false },
    { 'javascript', 'const s = "class Nam|";', false },
}
local failures = {}
for _, case in ipairs(cases) do
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = case[1]
    local position = assert(case[2]:find('|', 1, true))
    local before = case[2]:sub(1, position - 1)
    local prefix_lines = vim.split(before, '\n', { plain = true })
    local lines = vim.split(case[2]:sub(1, position - 1) .. case[2]:sub(position + 1), '\n', { plain = true })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { #prefix_lines, #prefix_lines[#prefix_lines] })
    local actual = context.is_declaration(buf)
    if actual ~= case[3] then failures[#failures + 1] = vim.inspect(case) .. ': got ' .. tostring(actual) end
    vim.api.nvim_buf_delete(buf, { force = true })
end
assert(#failures == 0, table.concat(failures, '\n'))
print('PASS: ' .. #cases .. ' declaration and reference contexts across all configured languages')
