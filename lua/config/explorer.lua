local M = {}
local editors = {}
local project_selected = false

function M.change_project(path)
    if not path or vim.trim(path) == "" then return false end
    path = vim.fs.normalize(vim.fs.abspath(vim.fs.normalize(vim.trim(path))))
    if vim.fn.isdirectory(path) ~= 1 then
        vim.notify("Not a directory: " .. path, vim.log.levels.WARN)
        return false
    end
    local api = require("nvim-tree.api")
    local ok, err = pcall(vim.api.nvim_set_current_dir, path)
    if not ok then
        vim.notify("Cannot open project folder: " .. tostring(err), vim.log.levels.ERROR)
        return false
    end
    project_selected = true
    api.tree.change_root(path)
    api.tree.open({ path = path, focus = false, find_file = false })
    vim.notify("Project folder: " .. path)
    return true
end

function M.prompt_project()
    -- Relative paths have the same meaning here as with :cd.
    vim.ui.input({ prompt = "Project folder (relative to " .. vim.fn.getcwd() .. "): ", completion = "dir" }, function(path)
        if path then M.change_project(path) end
    end)
end

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
    vim.api.nvim_create_user_command("Project", function(opts)
        if opts.args == "" then
            M.prompt_project()
        else
            -- fargs handles escaped spaces; strip the remaining Ex filename
            -- escapes added by directory completion (without executing them).
            local path = table.concat(opts.fargs, " "):gsub([[\([%[%]{}$#%%|!<>'"?*`])]], "%1")
            M.change_project(path)
        end
    end, { nargs = "*", complete = "dir", desc = "Change explorer and session project folder" })
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
        path = project_selected and vim.fn.getcwd()
            or (filepath ~= "" and vim.fn.fnamemodify(filepath, ":p:h") or vim.fn.getcwd()),
        find_file = not project_selected and filepath ~= "",
        focus = true,
    })
end

return M
