return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("telescope").setup({
                defaults = {
                    sorting_strategy = "ascending",

                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            width = 0.9,
                            height = 0.85,
                            preview_width = 0.55,
                        },
                    },

                    border = true,
                    winblend = 0,
                },
            })
        end,
    },
}
