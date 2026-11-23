local M = {}

-- Explicit templates: the snip prefix is part of every completion label.
local braces = {
    snipif = "if (${1:condition}) {\n\t$0\n}",
    snipfor = "for (int ${1:i} = 0; $1 < ${2:count}; ++$1) {\n\t$0\n}",
}
local templates = {
    c = vim.tbl_extend("force", braces, { snipmain = "int main(void) {\n\t$0\n\treturn 0;\n}" }),
    cpp = vim.tbl_extend("force", braces, { snipmain = "int main() {\n\t$0\n\treturn 0;\n}" }),
    cs = vim.tbl_extend("force", braces, { snipmain = "static void Main(string[] args) {\n\t$0\n}" }),
    java = vim.tbl_extend("force", braces, { snipmain = "public static void main(String[] args) {\n\t$0\n}" }),
    python = {
        snipmain = 'if __name__ == "__main__":\n\t$0',
        snipif = "if ${1:condition}:\n\t$0",
        snipfor = "for ${1:item} in ${2:items}:\n\t$0",
        snipfn = "def ${1:name}(${2:args}):\n\t$0",
    },
    lua = {
        snipif = "if ${1:condition} then\n\t$0\nend",
        snipfor = "for ${1:i} = 1, ${2:count} do\n\t$0\nend",
        snipfn = "local function ${1:name}(${2:args})\n\t$0\nend",
    },
    javascript = {
        snipif = braces.snipif,
        snipfor = "for (const ${1:item} of ${2:items}) {\n\t$0\n}",
        snipfn = "function ${1:name}(${2:args}) {\n\t$0\n}",
    },
}
templates.typescript = templates.javascript
templates.javascriptreact = templates.javascript
templates.typescriptreact = templates.javascript

function M.items(params)
    local current = vim.api.nvim_get_current_buf()
    local bufnr = vim.uri_from_bufnr(current) == params.textDocument.uri and current
        or vim.uri_to_bufnr(params.textDocument.uri)
    local line = vim.api.nvim_buf_get_lines(bufnr, params.position.line, params.position.line + 1, false)[1] or ""
    local byte = vim.str_byteindex(line, "utf-16", params.position.character, false)
    local prefix = line:sub(1, byte):match("[%w_]+$") or ""
    local items = {}
    if not vim.startswith(prefix, "snip") then return items end
    for label, body in pairs(templates[vim.bo[bufnr].filetype] or {}) do
        if vim.startswith(label, prefix) then
            items[#items + 1] = {
                label = label, filterText = label, insertText = body,
                kind = vim.lsp.protocol.CompletionItemKind.Snippet,
                insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
                documentation = { kind = "markdown", value = "```" .. vim.bo[bufnr].filetype .. "\n" .. body .. "\n```" },
            }
        end
    end
    table.sort(items, function(a, b) return a.label < b.label end)
    return items
end

function M.attach(bufnr)
    if not templates[vim.bo[bufnr].filetype] then return end
    -- A local completion-only source lets native completion own expansion,
    -- placeholder navigation, cancellation, and buffer lifecycle.
    vim.lsp.start({
        name = "prefixed-snippets",
        cmd = function(dispatchers)
            local closing, request_id = false, 0
            local function close()
                if closing then return end
                closing = true
                dispatchers.on_exit(0, 0)
            end
            return {
                request = function(method, params, callback)
                    request_id = request_id + 1
                    local id, result = request_id, nil
                    if method == "initialize" then
                        result = { capabilities = { completionProvider = {}, positionEncoding = "utf-16" } }
                    elseif method == "textDocument/completion" then
                        result = { isIncomplete = true, items = M.items(params) }
                    end
                    vim.schedule(function() callback(nil, result, id) end)
                    return true, id
                end,
                notify = function(method)
                    if method == "exit" then close() end
                    return true
                end,
                is_closing = function() return closing end,
                terminate = close,
            }
        end,
    }, { bufnr = bufnr })
end

return M
