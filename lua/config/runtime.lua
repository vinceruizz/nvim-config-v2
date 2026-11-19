local M = {}

function M.setup()
    local file = vim.fn.stdpath("data") .. "/installer/environment.json"
    if vim.fn.filereadable(file) ~= 1 then return end
    local ok, environment = pcall(function()
        return vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
    end)
    if not ok then
        vim.notify("Cannot read installer environment: " .. file, vim.log.levels.WARN)
        return
    end
    local paths = {}
    for _, path in ipairs(environment.path or {}) do
        if vim.fn.isdirectory(path) == 1 then paths[#paths + 1] = path end
    end
    for key, value in pairs(environment.env or {}) do vim.env[key] = value end
    if #paths > 0 then
        local separator = vim.fn.has("win32") == 1 and ";" or ":"
        vim.env.PATH = table.concat(paths, separator) .. separator .. vim.env.PATH
    end
end

return M
