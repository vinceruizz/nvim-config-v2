local M = {}

function M.setup()
    local current = require("config.theme").get()
    if not current.palette then return end
    local p, c = current.palette, current.palette.colors
    local theme = {}
    for mode, color in pairs({ normal = c.accent, insert = c.green, visual = c.purple, replace = c.orange, command = c.amber }) do
        theme[mode] = {
            a = { fg = c.bg, bg = color, gui = "bold" },
            b = { fg = c.fg, bg = c.surface }, c = { fg = c.fg, bg = c.surface },
        }
    end
    theme.inactive = { a = { fg = c.muted, bg = c.surface }, b = { fg = c.muted, bg = c.surface }, c = { fg = c.muted, bg = c.surface } }
    require("lualine").setup({
        options = { theme = theme, icons_enabled = not p.retro, component_separators = "", section_separators = "", globalstatus = true },
        sections = {
            lualine_a = { { "mode", separator = p.retro and "" or { left = "" }, padding = 1,
                fmt = function(mode) return p.retro and ("[ " .. mode .. " ]") or mode end } },
            lualine_b = { "branch" }, lualine_c = { "filename" },
            lualine_x = { "diagnostics", "filetype" }, lualine_y = { "progress" },
            lualine_z = { { "location", separator = p.retro and "" or { right = "" }, padding = 1,
                color = { fg = c.bg, bg = c.amber, gui = "bold" } } },
        },
        inactive_sections = {
            lualine_a = {}, lualine_b = {}, lualine_c = { "filename" },
            lualine_x = { "location" }, lualine_y = {}, lualine_z = {},
        },
    })
    require("lualine").refresh()
end

return M
