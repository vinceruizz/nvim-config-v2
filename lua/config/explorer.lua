local M = {}
local editors = {}

function M.copy_path()
    local node = require("nvim-tree.api").tree.get_node_under_cursor()
    if not node or not node.absolute_path then return end
    local path = node.absolute_path
    vim.fn.setreg("+", path, "v")
    vim.notify("Copied path: " .. path)
end

local function is_editor(win)
    return vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

function M.setup()
    local group = vim.api.nvim_create_augroup("ExplorerEditorFocus", { clear = true })
    local function remember()
        local win = vim.api.nvim_get_current_win()
        if is_editor(win) then editors[vim.api.nvim_get_current_tabpage()] = win end
    end
    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, { group = group, callback = remember })
    vim.api.nvim_create_autocmd("TabClosed", {
        group = group,
        callback = function()
            for tab in pairs(editors) do
                if not vim.api.nvim_tabpage_is_valid(tab) then editors[tab] = nil end
            end
        end,
    })
    remember()
end

function M.toggle_focus()
    local api = require("nvim-tree.api")
    local tab = vim.api.nvim_get_current_tabpage()
    if vim.bo.filetype == "NvimTree" then
        local target = editors[tab]
        if target and is_editor(target) and vim.api.nvim_win_get_tabpage(target) == tab then
            vim.api.nvim_set_current_win(target)
            return
        end
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            if is_editor(win) then
                vim.api.nvim_set_current_win(win)
                return
            end
        end
        -- Recover gracefully if the last editing pane was closed.
        vim.cmd("botright vnew")
        return
    end

    local win = vim.api.nvim_get_current_win()
    if is_editor(win) then editors[tab] = win end
    if api.tree.is_visible() then
        api.tree.focus()
        return
    end
    local filepath = vim.api.nvim_buf_get_name(0)
    api.tree.open({
        path = filepath ~= "" and vim.fn.fnamemodify(filepath, ":p:h") or vim.fn.getcwd(),
        find_file = filepath ~= "",
        focus = true,
    })
end

return M
