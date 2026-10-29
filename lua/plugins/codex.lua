return {
    {
        "nwiizo/codex.nvim",
        event = "VeryLazy",
        cmd = {
            "Codex", "CodexOpen", "CodexClose", "CodexFocus", "CodexStop",
            "CodexAsk", "CodexAskVisual", "CodexEdit", "CodexFollowUp",
            "CodexAdd", "CodexAddVisual", "CodexTreeAdd", "CodexSend",
            "CodexSendVisual", "CodexSendText", "CodexPrompt", "CodexDiff",
            "CodexResume", "CodexContinue", "CodexFork", "CodexReview",
            "CodexImage", "CodexInterrupt", "CodexStatus", "CodexHealth",
        },
        keys = {
            { "<leader>cc", "<cmd>Codex<CR>", desc = "Toggle Codex panel" },
            { "<leader>ca", "<cmd>CodexAsk<CR>", desc = "Ask Codex about current file" },
            { "<leader>cb", "<cmd>CodexAdd<CR>", desc = "Attach current file to Codex" },
            { "<leader>cf", "<cmd>CodexFollowUp<CR>", desc = "Compose Codex follow-up" },
            { "<leader>cd", "<cmd>CodexDiff<CR>", desc = "View Codex session Git diff" },
            { "<leader>cr", "<cmd>CodexResume<CR>", desc = "Resume Codex session" },
            { "<leader>cq", "<cmd>CodexStop<CR>", desc = "Stop Codex session" },
        },
        config = function(_, opts)
            require("codex").setup(opts)
            vim.api.nvim_create_autocmd("User", {
                group = vim.api.nvim_create_augroup("CodexNormalModeHide", { clear = true }),
                pattern = { "CodexStarted", "CodexOpened" },
                callback = function(event)
                    local buf = event.data and event.data.bufnr
                    if buf and vim.api.nvim_buf_is_valid(buf) then
                        vim.keymap.set("n", "q", "<cmd>CodexClose<CR>", {
                            buffer = buf,
                            desc = "Hide Codex panel",
                        })
                    end
                end,
            })
        end,
        opts = function()
            local executable = vim.fn.exepath("codex")
            -- Also work when Kitty's PATH does not include the app-bundled CLI.
            local bundled = "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
            if executable == "" then
                executable = vim.fn.executable(bundled) == 1 and bundled or "codex"
            end
            return {
                backend = "terminal",
                cmd = { executable },
                app_server = { cmd = { executable, "app-server" } },
                cwd = "root",
                terminal = {
                    layout = "split",
                    split_side = "right",
                    split_width_percentage = 0.4,
                    hide_keys = { "<C-g>" },
                    normal_mode_keys = { "<Esc>", "<M-n>" },
                    window_navigation = {
                        left = "<C-h>", down = "<C-j>",
                        up = "<C-k>", right = "<C-l>",
                    },
                },
                selection = { keymaps = { ask = "<leader>ca", edit = "<leader>ce" } },
            }
        end,
    },
}
