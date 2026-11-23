local M = {}

-- Some servers (notably clangd) provide control-flow keywords only as
-- snippets. Keep the word, without opting the user into a code template.
local keyword_templates = {}
for word in ("if else elif elseif for foreach while do switch case default try catch finally "
    .. "return break continue throw yield with match using lock class struct enum interface "
    .. "def function repeat until"):gmatch("%S+") do
    keyword_templates[word] = true
end

local function plain_keyword(item)
    local word = vim.trim(item.filterText or item.label or "")
    if not keyword_templates[word] then return nil end
    local plain = vim.deepcopy(item)
    plain.label, plain.filterText, plain.insertText = word, word, word
    plain.kind = vim.lsp.protocol.CompletionItemKind.Keyword
    plain.insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText
    plain.textEditText = word
    if plain.textEdit then plain.textEdit.newText = word end
    plain.labelDetails, plain.detail = nil, nil
    plain.command, plain.additionalTextEdits = nil, nil
    plain.documentation = "Keyword: " .. word .. ". Use snip for code templates."
    plain._plain_keyword = true
    return plain
end

local function is_template(item, defaults)
    if item.kind == vim.lsp.protocol.CompletionItemKind.Snippet then return true end
    local format = item.insertTextFormat or (defaults or {}).insertTextFormat
    if format ~= vim.lsp.protocol.InsertTextFormat.Snippet then return false end
    local text = (item.textEdit or {}).newText or item.textEditText or item.insertText or ""
    -- Keep callable signatures/generic type placeholders, but hide code blocks
    -- and keyword templates even when the server doesn't label them Snippet.
    return (item.kind == vim.lsp.protocol.CompletionItemKind.Keyword and text:find("$", 1, true) ~= nil)
        or text:find("\n", 1, true) ~= nil
end

function M.filter_result(result)
    if type(result) ~= "table" then return result end
    local filtered = {}
    for _, item in ipairs(result.items or result) do
        if is_template(item, result.itemDefaults) then
            local keyword = plain_keyword(item)
            if keyword then filtered[#filtered + 1] = keyword end
        else
            filtered[#filtered + 1] = item
        end
    end
    if result.items then
        result.items = filtered
        return result
    end
    return filtered
end

function M.attach(client, bufnr)
    if not client or not client:supports_method("textDocument/completion") then return end

    if not client._filtered_completion then
        client._filtered_completion = true
        local request = client.request
        client.request = function(self, method, params, handler, buffer)
            if method == "textDocument/completion" and handler then
                local original = handler
                handler = function(err, result, context, config)
                    if require("config.completion_context").is_declaration(context and context.bufnr or buffer) then
                        result = { isIncomplete = true, items = {} }
                    elseif self.name ~= "prefixed-snippets" then
                        result = M.filter_result(result)
                    end
                    return original(err, result, context, config)
                end
            elseif method == "completionItem/resolve" and params._plain_keyword and handler then
                local original = handler
                handler = function(err, result, context, config)
                    -- Preserve the plain insertion if resolving returns the
                    -- original snippet or its extra edits again.
                    return original(err, params, context, config)
                end
            end
            return request(self, method, params, handler, buffer)
        end
    end

    -- Keep server punctuation triggers (such as '.') and also suggest names
    -- while typing identifiers. Neovim handles request timing and cancellation.
    local provider = client.server_capabilities.completionProvider
    local triggers = provider.triggerCharacters or {}
    for character in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$"):gmatch(".") do
        if not vim.tbl_contains(triggers, character) then
            triggers[#triggers + 1] = character
        end
    end
    provider.triggerCharacters = triggers
    -- Re-rank the menu as the identifier grows; server sortText breaks ties.
    vim.bo[bufnr].completeopt = "menu,menuone,noselect,popup,fuzzy"
    vim.opt.pumheight = 10
    vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true,
        commit_characters = false,
    })

    local group = vim.api.nvim_create_augroup("CompletionContext" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
        group = group, buffer = bufnr,
        callback = function()
            -- Also dismiss cached candidates when typing changes the context.
            vim.schedule(function()
                if vim.api.nvim_get_current_buf() == bufnr and vim.fn.pumvisible() == 1
                    and require("config.completion_context").is_declaration(bufnr) then
                    vim.api.nvim_feedkeys(vim.keycode("<C-e>"), "n", false)
                end
            end)
        end,
    })

    local function map(key, action, description, options)
        vim.keymap.set("i", key, action, vim.tbl_extend("force",
            { buffer = bufnr, expr = true, desc = description }, options or {}))
    end
    map("<Tab>", function()
        return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
    end, "Next suggestion")
    map("<S-Tab>", function()
        return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
    end, "Previous suggestion")
    -- autopairs already returns encoded keys; translating them again corrupts
    -- its cursor-motion and indentation commands into literal buffer text.
    map("<CR>", function()
        if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected >= 0 then
            return vim.keycode("<C-y>")
        end
        -- Preserve bracket-aware newlines when no suggestion is selected.
        local ok, autopairs = pcall(require, "nvim-autopairs")
        local newline = ok and autopairs.autopairs_cr() or vim.keycode("<CR>")
        return (vim.fn.pumvisible() == 1 and vim.keycode("<C-e>") or "") .. newline
    end, "Accept selected suggestion or insert newline", { replace_keycodes = false })
    vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, {
        buffer = bufnr, desc = "Show suggestions",
    })
    for key, direction in pairs({ ["<C-j>"] = 1, ["<C-k>"] = -1 }) do
        vim.keymap.set({ "i", "s" }, key, function()
            if vim.snippet.active({ direction = direction }) then vim.snippet.jump(direction) end
        end, { buffer = bufnr, desc = direction == 1 and "Next snippet field" or "Previous snippet field" })
    end
    if client.name ~= "prefixed-snippets" then
        require("config.snippets").attach(bufnr)
    end
end

return M
