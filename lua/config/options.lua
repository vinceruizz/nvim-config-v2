local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.cursorlineopt = "both"

-- Only the active editing/explorer window shows a highlighted cursor line.
local function update_cursorline()
    local current = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local editing = vim.bo[buf].buftype == "" or vim.bo[buf].filetype == "NvimTree"
        local enabled = win == current and editing
            and vim.api.nvim_win_get_config(win).relative == ""
        if vim.wo[win].cursorline ~= enabled then
            vim.wo[win].cursorline = enabled
        end
    end
end
vim.api.nvim_create_autocmd({
    "WinEnter", "WinLeave", "BufEnter", "BufWinEnter", "TabEnter",
    "VimEnter", "UIEnter", "FocusGained", "SafeState",
}, {
    group = vim.api.nvim_create_augroup("ActiveWindowCursorLine", { clear = true }),
    callback = function(event)
        if event.event == "WinLeave" then
            vim.wo.cursorline = false
        elseif event.event == "VimEnter" or event.event == "UIEnter" then
            -- Startup plugins can change window options after options.lua loads.
            -- Reapply once startup/UI initialization has finished.
            vim.schedule(function()
                update_cursorline()
                vim.cmd("redraw")
            end)
        else
            update_cursorline()
        end
    end,
})
update_cursorline()

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true

-- Editing
opt.confirm = true -- Offer to save unsaved files when quitting or closing them.
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Scrolling
opt.scrolloff = 8

-- Hide ~ characters on empty lines
vim.opt.fillchars:append({ eob = " " })

return { update_cursorline = update_cursorline }
