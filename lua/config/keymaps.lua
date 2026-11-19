vim.g.mapleader = " "

local keymap = vim.keymap.set

keymap({ "n", "x", "o" }, "0", function()
    local first = vim.fn.match(vim.api.nvim_get_current_line(), [[\S]])
    local column = vim.api.nvim_win_get_cursor(0)[2]
    return (first < 0 or (first > 0 and column == first)) and "0" or "^"
end, { expr = true, desc = "First nonblank character or line start" })

-- Keep normal word boundaries, with extra stops at semicolons and closing
-- parentheses inside punctuation groups. Uppercase WORD motions stay standard.
local function before(a, b)
    return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
end
for _, motion in ipairs({
    { "w", false, "Next word, semicolon, or closing parenthesis" },
    { "b", true, "Previous word, semicolon, or closing parenthesis" },
    { "e", false, "Next word end, semicolon, or closing parenthesis" },
    { "ge", true, "Previous word end, semicolon, or closing parenthesis" },
}) do
    keymap({ "n", "x" }, motion[1], function()
        for _ = 1, vim.v.count1 do
            local start = vim.api.nvim_win_get_cursor(0)
            vim.cmd("normal! " .. motion[1])
            local target = vim.api.nvim_win_get_cursor(0)
            vim.api.nvim_win_set_cursor(0, start)
            local match = vim.fn.searchpos("[;)]", motion[2] and "bnW" or "nW", target[1])
            local stop = { match[1], match[2] - 1 }
            if match[1] > 0 and (motion[2] and before(target, stop)
                or not motion[2] and before(stop, target)) then
                target = stop
            end
            vim.api.nvim_win_set_cursor(0, target)
        end
    end, { desc = motion[3] })
end

keymap("n", "<leader>?", function()
    require("config.cheatsheet").toggle()
end, { desc = "Open Neovim cheat sheet" })

vim.api.nvim_create_user_command("CheatSheet", function()
    require("config.cheatsheet").toggle()
end, { desc = "Open the graphical Neovim cheat sheet" })

-- Save and quit
keymap("n", "<leader>w", "<cmd>w<CR>")
keymap("n", "<leader>q", "<cmd>q<CR>")

-- Window navigation
keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

-- Persistent terminal below the current editing pane
keymap("n", "<leader>tt", function()
    require("config.terminal").toggle()
end, { desc = "Toggle terminal in horizontal split" })

-- Clear search highlighting
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- File explorer: switch focus to/from the most recent editing pane.
require("config.explorer").setup()
vim.keymap.set("n", "<leader>e", function()
    require("config.explorer").toggle_focus()
end, {
    desc = "Switch focus between editor and explorer",
})
-- Get the intended search root
local function explorer_root()
    local ok, core = pcall(require, "nvim-tree.core")

    if ok then
        local explorer = core.get_explorer()

        if explorer and explorer.absolute_path then
            return explorer.absolute_path
        end
    end

    -- Fall back to the current file's directory
    local filepath = vim.api.nvim_buf_get_name(0)

    if filepath ~= "" then
        return vim.fn.fnamemodify(filepath, ":p:h")
    end

    -- No file open: use the working directory
    return vim.fn.getcwd()
end

-- Search file contents
vim.keymap.set("n", "<leader>fg", function()
    require("telescope.builtin").live_grep({
        cwd = explorer_root(),
        prompt_title = "Search Project Contents",
    })
end, {
    desc = "Search project contents",
})

-- Find files
vim.keymap.set("n", "<leader>ff", function()
    require("telescope.builtin").find_files({
        cwd = explorer_root(),
        hidden = true,
        prompt_title = "Find Project Files",
    })
end, {
    desc = "Find project files",
})

-- Search word under cursor
vim.keymap.set("n", "<leader>fw", function()
    require("telescope.builtin").grep_string({
        cwd = explorer_root(),
        prompt_title = "Find Word in Project",
    })
end, {
    desc = "Search current word",
})
