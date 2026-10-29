return {
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "mason-org/mason-lspconfig.nvim",
        },
        config = function()
            require("config.lsp").setup()
        end,
    },
}
