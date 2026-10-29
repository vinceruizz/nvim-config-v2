return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "theHamsta/nvim-dap-virtual-text",
            { "mason-org/mason.nvim", opts = {} },
        },
        config = function()
            require("config.debug").setup()
        end,
    },
    {
        "mfussenegger/nvim-jdtls",
        ft = "java",
        dependencies = { "mfussenegger/nvim-dap" },
        config = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = function() require("config.java").start() end,
            })
            require("config.java").start()
        end,
    },
}
