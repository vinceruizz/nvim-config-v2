local M = {}

function M.setup()
    -- Keep diagnostics accessible without writing messages over the code.
    vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = false,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
        jump = { on_jump = function() end },
        signs = {
            severity = { min = vim.diagnostic.severity.WARN },
            text = {
                [vim.diagnostic.severity.ERROR] = "●",
                [vim.diagnostic.severity.WARN] = "●",
            },
        },
        float = { border = "rounded", source = "if_many", focusable = false },
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("BasicLsp", { clear = true }),
        callback = function(event)
            local function map(key, action, description)
                vim.keymap.set("n", key, action, { buffer = event.buf, desc = description })
            end
            map("gd", vim.lsp.buf.definition, "Go to definition")
            map("gD", vim.lsp.buf.declaration, "Go to declaration")
            map("gr", vim.lsp.buf.references, "Find references")
            map("gi", vim.lsp.buf.implementation, "Go to implementation")
            map("K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Show documentation")
            map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
            map("<leader>la", vim.lsp.buf.code_action, "Show code actions")
            map("<leader>ld", vim.diagnostic.open_float, "Show diagnostics under cursor")
            map("<leader>lq", vim.diagnostic.setloclist, "List buffer diagnostics")

            -- Built-in completion is manual: Ctrl-X Ctrl-O in Insert mode.
            vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
            vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
            vim.lsp.document_color.enable(false, { bufnr = event.buf })
            -- Treesitter owns syntax colors, so server tokens cannot repaint them.
            vim.lsp.semantic_tokens.enable(false, { bufnr = event.buf, client_id = event.data.client_id })
        end,
    })

    vim.lsp.config("lua_ls", {
        settings = {
            Lua = {
                hint = { enable = false },
                codeLens = { enable = false },
                workspace = { checkThirdParty = false },
            },
        },
        on_init = function(client)
            if client.root_dir == vim.fn.stdpath("config") then
                client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                    runtime = { version = "LuaJIT" },
                    diagnostics = { globals = { "vim" } },
                    workspace = { library = { vim.env.VIMRUNTIME } },
                })
            end
        end,
    })
    vim.lsp.config("pyright", {
        settings = { python = { analysis = { diagnosticMode = "openFilesOnly", typeCheckingMode = "basic" } } },
    })
    local servers = { "lua_ls", "pyright", "ts_ls", "csharp_ls", "jdtls" }
    if vim.fn.executable("clangd") ~= 1 then
        servers[#servers + 1] = "clangd"
    end
    require("mason-lspconfig").setup({
        ensure_installed = servers,
        -- Java is started by nvim-jdtls to preserve its existing debug integration.
        automatic_enable = { "lua_ls", "pyright", "ts_ls", "csharp_ls", "clangd" },
    })
    -- Prefer existing developer tools; Mason supplies clangd when absent.
    vim.lsp.enable("clangd")
end

return M
