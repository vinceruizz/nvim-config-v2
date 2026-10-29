vim.g.mapleader = " "

local keymap = vim.keymap.set

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

-- File explorer: open or focus
vim.keymap.set("n", "<leader>e", function()
    local api = require("nvim-tree.api")

    if api.tree.is_visible() then
        api.tree.focus()
        return
    end

    local filepath = vim.api.nvim_buf_get_name(0)
    local directory = vim.fn.getcwd()

    if filepath ~= "" then
        directory = vim.fn.fnamemodify(filepath, ":p:h")
    end

    api.tree.open({
        path = directory,
        find_file = filepath ~= "",
        focus = true,
    })
end, {
    desc = "Open or focus file explorer",
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
