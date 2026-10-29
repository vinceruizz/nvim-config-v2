vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "lua",
        "python",
        "c",
        "cpp",
        "javascript",
        "typescript",
        "java",
    },
    callback = function(args)
        pcall(vim.treesitter.start, args.buf)
    end,
})
