
return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",

        dependencies = {
            "MunifTanjim/nui.nvim",
        },

        opts = {
            -- Floating command line
            cmdline = {
                enabled = true,
                view = "cmdline_popup",

                format = {
                    cmdline = {
                        pattern = "^:",
                        icon = "❯",
                        title = " Command ",
                    },

                    search_down = {
                        kind = "search",
                        pattern = "^/",
                        icon = "",
                        title = " Search ",
                    },

                    search_up = {
                        kind = "search",
                        pattern = "^%?",
                        icon = "",
                        title = " Search Backward ",
                    },
                },
            },

            -- Autocomplete suggestions
            popupmenu = {
                enabled = true,
                backend = "nui",
            },

            -- Keep notifications minimal
            messages = {
                enabled = true,
                view = "mini",
                view_error = "mini",
                view_warn = "mini",
            },

            -- Floating popup appearance
            views = {
                cmdline_popup = {
                    position = {
                        row = "40%",
                        col = "50%",
                    },
                    size = {
                        width = 60,
                        height = "auto",
                    },
                    border = {
                        style = "rounded",
                        padding = { 0, 1 },
                    },
                    win_options = {
                        winhighlight = {
                            Normal = "NoiceCmdlinePopup",
                            FloatBorder = "NoiceCmdlinePopupBorder",
                        },
                    },
                },

                popupmenu = {
                    relative = "editor",
                    position = {
                        row = "48%",
                        col = "50%",
                    },
                    size = {
                        width = 60,
                        height = 10,
                    },
                    border = {
                        style = "rounded",
                    },
                },
            },

            presets = {
                bottom_search = false,
                command_palette = false,
                long_message_to_split = true,
            },
        },
    },
}

