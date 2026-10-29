local M = {}
local buffer, job, timer
local hidden_timeout_ms = 5 * 60 * 1000

local function cancel_timeout()
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
end

local function visible(buf)
    return #vim.fn.win_findbuf(buf) > 0
end

local function terminate()
    cancel_timeout()
    local old_buffer, old_job = buffer, job
    buffer, job = nil, nil
    if old_job then
        vim.fn.jobstop(old_job)
    end
    if old_buffer and vim.api.nvim_buf_is_valid(old_buffer) then
        vim.api.nvim_buf_delete(old_buffer, { force = true })
    end
end

local function start_timeout(buf)
    if buffer ~= buf then return end
    cancel_timeout()
    if not vim.api.nvim_buf_is_valid(buf) or visible(buf) then
        return
    end
    timer = vim.defer_fn(function()
        timer = nil
        if buffer == buf and vim.api.nvim_buf_is_valid(buf) and not visible(buf) then
            terminate()
        end
    end, hidden_timeout_ms)
end

local function create_terminal()
    buffer = vim.api.nvim_get_current_buf()
    local buf = buffer
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    job = vim.fn.jobstart(vim.o.shell, { term = true })
    if job <= 0 then
        terminate()
        vim.notify("Unable to start terminal shell", vim.log.levels.ERROR)
        return false
    end

    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = buf, desc = "Leave terminal input mode" })
    vim.keymap.set("n", "q", M.toggle, { buffer = buf, desc = "Hide terminal split" })
    vim.keymap.set("t", "<C-g>", [[<C-\><C-n><Cmd>lua require("config.terminal").toggle()<CR>]], {
        buffer = buf,
        desc = "Hide terminal split",
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        buffer = buf,
        callback = function()
            vim.schedule(function() start_timeout(buf) end)
        end,
    })
    vim.api.nvim_create_autocmd("BufWinEnter", {
        buffer = buf,
        callback = cancel_timeout,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        callback = function()
            if buffer == buf then
                cancel_timeout()
                if job then vim.fn.jobstop(job) end
                buffer, job = nil, nil
            end
        end,
    })
    return true
end

function M.toggle()
    cancel_timeout()
    if buffer and vim.api.nvim_buf_is_valid(buffer) and visible(buffer) then
        for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
            -- Keep a usable editing window even if the terminal is the only pane.
            if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)) == 1 then
                vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
            else
                vim.api.nvim_win_close(win, true)
            end
        end
        start_timeout(buffer)
        return
    end

    if buffer and (not vim.api.nvim_buf_is_valid(buffer) or not job or vim.fn.jobwait({ job }, 0)[1] ~= -1) then
        terminate()
    end

    vim.cmd("belowright new")
    if buffer then
        local empty = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_set_buf(0, buffer)
        vim.api.nvim_buf_delete(empty, { force = true })
    elseif not create_terminal() then
        return
    end
    vim.cmd("startinsert")
end

return M
