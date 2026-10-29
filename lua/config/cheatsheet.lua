local M = {}
local state = { query = "" }
local ns = vim.api.nvim_create_namespace("neovim_cheatsheet")
local render

local function valid()
    return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function highlights()
    for name, spec in pairs({
        Normal = { fg = "#e0d9c7", bg = "#101e2d" },
        Border = { fg = "#46657e", bg = "#101e2d" },
        Card = { fg = "#30495f" },
        Title = { fg = "#86dbf5", bold = true },
        Heading = { fg = "#f5b66c", bold = true },
        Muted = { fg = "#94a8ba" },
        Key = { fg = "#a9ddf1", bg = "#1e3548", bold = true },
    }) do
        vim.api.nvim_set_hl(0, "Cheat" .. name, spec)
    end
end

-- Wrap by screen cells, including wide Unicode characters. Highlight offsets
-- below still use bytes, as required by Neovim's extmark API.
local function wrap(text, width)
    local lines, current = {}, ""
    for word in text:gmatch("%S+") do
        if current ~= "" and vim.fn.strdisplaywidth(current .. " " .. word) <= width then
            current = current .. " " .. word
        else
            if current ~= "" then lines[#lines + 1] = current end
            current = word
            while vim.fn.strdisplaywidth(current) > width do
                local count, used = 0, 0
                while count < vim.fn.strchars(current) do
                    local char = vim.fn.strcharpart(current, count, 1)
                    local cells = vim.fn.strdisplaywidth(char)
                    if used + cells > width then break end
                    count, used = count + 1, used + cells
                end
                count = math.max(count, 1)
                lines[#lines + 1] = vim.fn.strcharpart(current, 0, count)
                current = vim.fn.strcharpart(current, count)
            end
        end
    end
    if current ~= "" or #lines == 0 then lines[#lines + 1] = current end
    return lines
end

local function pad(text, width)
    return text .. string.rep(" ", math.max(0, width - vim.fn.strdisplaywidth(text)))
end

local function card_lines(card, width)
    local inner = width - 4
    local keys = math.min(23, math.floor((inner - 2) * 0.42))
    local description = inner - keys - 2
    local result = {}
    local function full(text, group)
        result[#result + 1] = { { "│ ", "CheatCard" }, { pad(text, inner), group }, { " │", "CheatCard" } }
    end
    result[#result + 1] = { { "╭" .. string.rep("─", width - 2) .. "╮", "CheatCard" } }
    for _, line in ipairs(wrap(card.title, inner)) do full(line, "CheatHeading") end
    for _, line in ipairs(wrap(card.context, inner)) do full(line, "CheatMuted") end
    full("", "CheatNormal")
    for _, row in ipairs(card.rows) do
        local left, right = wrap(row[1], keys), wrap(row[2], description)
        for index = 1, math.max(#left, #right) do
            result[#result + 1] = {
                { "│ ", "CheatCard" }, { pad(left[index] or "", keys), "CheatKey" },
                { "  " }, { pad(right[index] or "", description), "CheatNormal" }, { " │", "CheatCard" },
            }
        end
    end
    full("", "CheatNormal")
    result[#result + 1] = { { "╰" .. string.rep("─", width - 2) .. "╯", "CheatCard" } }
    return result
end

local function dimensions()
    return math.max(1, math.min(122, vim.o.columns - 6)), math.max(1, math.min(46, vim.o.lines - 6))
end

render = function()
    if not valid() then return end
    local width, height = dimensions()
    vim.api.nvim_win_set_config(state.win, {
        relative = "editor", width = width, height = height,
        row = math.floor((vim.o.lines - height - 2) / 2),
        col = math.floor((vim.o.columns - width - 2) / 2),
    })
    local lines, marks = {}, {}
    local function add(chunks)
        local text = ""
        for _, chunk in ipairs(chunks) do
            local start = #text
            text = text .. chunk[1]
            if chunk[2] and #chunk[1] > 0 then
                marks[#marks + 1] = { #lines, start, #text, chunk[2] }
            end
        end
        lines[#lines + 1] = text
    end
    add({ { "  YOUR NEOVIM", "CheatTitle" }, { "   /   FIELD GUIDE", "CheatMuted" } })
    add({ { "  Space is your leader. Shortcuts are case-sensitive.", "CheatMuted" } })
    add({ { "" } })
    if state.query ~= "" then add({ { "  FILTER  " .. state.query .. "   (c clears)", "CheatHeading" } }) end
    add({ { "" } })

    local cards = {}
    for _, card in ipairs(state.cards) do
        if state.query == "" then
            cards[#cards + 1] = card
        else
            local filtered = { title = card.title, context = card.context, rows = {} }
            local heading_matches = (card.title .. " " .. card.context):lower():find(state.query, 1, true)
            for _, row in ipairs(card.rows) do
                if heading_matches or (row[1] .. " " .. row[2]):lower():find(state.query, 1, true) then
                    filtered.rows[#filtered.rows + 1] = row
                end
            end
            if #filtered.rows > 0 then cards[#cards + 1] = filtered end
        end
    end
    if width < 32 then
        for _, text in ipairs(wrap("Widen your terminal to at least 38 columns to view the cards.", math.max(1, width - 2))) do
            add({ { text, "CheatMuted" } })
        end
    else
        local columns = width >= 108 and 2 or 1
        local card_width = math.floor((width - 4 - (columns - 1) * 2) / columns)
        for index = 1, #cards, columns do
            local left = card_lines(cards[index], card_width)
            local right = columns == 2 and cards[index + 1] and card_lines(cards[index + 1], card_width) or {}
            for row = 1, math.max(#left, #right) do
                local chunks = { { "  " } }
                vim.list_extend(chunks, left[row] or { { string.rep(" ", card_width) } })
                if #right > 0 then
                    chunks[#chunks + 1] = { "  " }
                    vim.list_extend(chunks, right[row] or { { string.rep(" ", card_width) } })
                end
                add(chunks)
            end
            add({ { "" } })
        end
        if #cards == 0 then add({ { "  No matches. Press / to search again, or c to clear.", "CheatMuted" } }) end
    end
    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
    for _, mark in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(state.buf, ns, mark[1], mark[2], {
            end_col = mark[3], hl_group = mark[4],
        })
    end
    vim.bo[state.buf].modifiable = false
    vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
end

function M.close()
    if valid() then vim.api.nvim_win_close(state.win, true) end
    state.win = nil
end

function M.toggle()
    if valid() then M.close(); return end
    highlights()
    state.cards = require("config.cheatsheet_data").cards()
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].filetype = "neovim-cheatsheet"
    local width, height = dimensions()
    state.win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor", width = width, height = height, row = 1, col = 1,
        style = "minimal", border = "rounded", zindex = 60,
        title = "  NVIM  /  FIELD GUIDE  ", title_pos = "center",
        footer = "  /: find   c: clear   j/k: scroll   q: close  ", footer_pos = "center",
    })
    for name, value in pairs({
        winhighlight = "Normal:CheatNormal,FloatBorder:CheatBorder,FloatTitle:CheatTitle,FloatFooter:CheatMuted",
        wrap = false, spell = false, list = false, cursorline = false,
        signcolumn = "no", scrolloff = 0, sidescrolloff = 0,
    }) do vim.wo[state.win][name] = value end
    local function map(key, fn)
        vim.keymap.set("n", key, fn, { buffer = state.buf, silent = true, nowait = true })
    end
    for _, key in ipairs({ "q", "<Esc>", "<leader>?" }) do map(key, M.close) end
    map("/", function()
        vim.ui.input({ prompt = "Find a key, command, or feature: ", default = state.query }, function(query)
            if query == nil or not valid() then return end
            state.query = query:lower()
            render()
        end)
    end)
    map("c", function() state.query = ""; render() end)
    local group = vim.api.nvim_create_augroup("NeovimCheatSheet", { clear = true })
    vim.api.nvim_create_autocmd("VimResized", { group = group, callback = render })
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = group, buffer = state.buf, once = true,
        callback = function() vim.api.nvim_clear_autocmds({ group = group }) end,
    })
    render()
end

return M
