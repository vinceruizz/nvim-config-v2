return {
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        config = function()
            
local function on_attach(bufnr)
    local api = require("nvim-tree.api")

    -- Preserve default nvim-tree mappings
    api.map.on_attach.default(bufnr)

    local function opts(desc)
        return {
            desc = "nvim-tree: " .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
        }
    end

    -- L: Expand folder or open file
    vim.keymap.set("n", "l", function()
        local node = api.tree.get_node_under_cursor()
        if not node then return end

        if node.type == "directory" then
            -- Only expand; don't collapse an open folder
            if not node.open then
                api.node.open.edit()
            end
        else
            api.node.open.edit()
        end
    end, opts("Expand folder or open file"))

    -- H: Navigate to parent, then collapse
    vim.keymap.set("n", "h", function()
        local node = api.tree.get_node_under_cursor()
        if not node then return end

        if node.type == "directory" and node.open then
            -- On expanded directory: collapse it
            api.node.open.edit()
        else
            -- On file or collapsed directory: go to parent
            api.node.navigate.parent()
        end
    end, opts("Go to parent or collapse folder"))
end
require("nvim-tree").setup({
    on_attach = on_attach,

    view = {
        width = 32,
        side = "left",
        signcolumn = "no",
    },

    renderer = {
        group_empty = true,
        highlight_git = true,
        indent_markers = {
            enable = true,
        },
    },

    filters = {
        dotfiles = false,
    },

    update_focused_file = {
        enable = true,
        update_root = false,
    },
})
             -- Match our Midnight Glass theme
            local set = vim.api.nvim_set_hl

            set(0, "NvimTreeNormal", {
                fg = "#e0d9c7",
                bg = "NONE",
            })

            set(0, "NvimTreeNormalNC", {
                fg = "#e0d9c7",
                bg = "NONE",
            })

            set(0, "NvimTreeEndOfBuffer", {
                bg = "NONE",
            })

            set(0, "NvimTreeWinSeparator", {
                fg = "#46657e",
                bg = "NONE",
            })

            set(0, "NvimTreeFolderName", {
                fg = "#86dbf5",
            })

            set(0, "NvimTreeOpenedFolderName", {
                fg = "#f5b66c",
                bold = true,
            })

            set(0, "NvimTreeRootFolder", {
                fg = "#f5b66c",
                bold = true,
            })
        end,
    },
}

