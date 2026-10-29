return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local colors = {
                bg = "#070f1c",
                fg = "#e0d9c7",
                muted = "#9aafc2",
                cyan = "#86dbf5",
                blue = "#5db2f8",
                amber = "#f5b66c",
                orange = "#ea9472",
                green = "#a6d7a0",
                purple = "#c7a5e8",
                bar = "#142638",
            }
            
            local theme = {
                normal = {
                    a = { fg = colors.bg, bg = colors.cyan, gui = "bold" },
                    b = { fg = colors.fg, bg = colors.bar },
                    c = { fg = colors.fg, bg = colors.bar },
                },

                insert = {
                    a = { fg = colors.bg, bg = colors.green, gui = "bold" },
                    b = { fg = colors.fg, bg = colors.bar },
                    c = { fg = colors.fg, bg = colors.bar },
                },

                visual = {
                    a = { fg = colors.bg, bg = colors.purple, gui = "bold" },
                    b = { fg = colors.fg, bg = colors.bar },
                    c = { fg = colors.fg, bg = colors.bar },
                },

                replace = {
                    a = { fg = colors.bg, bg = colors.orange, gui = "bold" },
                    b = { fg = colors.fg, bg = colors.bar },
                    c = { fg = colors.fg, bg = colors.bar },
                },

                command = {
                    a = { fg = colors.bg, bg = colors.amber, gui = "bold" },
                    b = { fg = colors.fg, bg = colors.bar },
                    c = { fg = colors.fg, bg = colors.bar },
                },

                inactive = {
                    a = { fg = colors.muted, bg = colors.bar },
                    b = { fg = colors.muted, bg = colors.bar },
                    c = { fg = colors.muted, bg = colors.bar },
                },
            }

           require("lualine").setup({
                options = {
                    theme = theme,
                    icons_enabled = true,

                    -- Minimal separators
                   component_separators = "",
                   section_separators = "", 
                       -- One statusline across all windows
                       globalstatus = true,
                   },
sections = {
    lualine_a = {
        {
            "mode",
            separator = { left = ""},
            padding = { left = 1, right = 1 },
        },
    },

    lualine_b = { "branch" },
    lualine_c = { "filename" },

    lualine_x = {
        "diagnostics",
        "filetype",
    },

    lualine_y = { "progress" },

    lualine_z = {
        {
            "location",
            separator = { right = "" },
            padding = { left = 1, right = 1 },
            color = {
                fg = colors.bg,
                bg = colors.amber,
                gui = "bold",
            },
        },
    },
},
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { "filename" },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
            })
        end,
    },
}

