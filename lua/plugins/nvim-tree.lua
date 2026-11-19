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

    vim.keymap.set("n", "yd", function()
        require("config.explorer").copy_path()
    end, opts("Copy highlighted file or folder path"))

    -- Include the extension in both rename prompts.
    for _, key in ipairs({ "e", "r" }) do
        vim.keymap.set("n", key, api.fs.rename, opts("Rename including extension"))
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
        group_empty = false,
        highlight_git = true,
        indent_markers = {
            enable = true,
        },
    },

    filters = {
        dotfiles = false,
        git_ignored = false,
    },

    update_focused_file = {
        enable = true,
        update_root = false,
    },
})
            -- Directory startup reuses the first window and applies its options
            -- with autocommands suppressed. Refresh after the tree is drawn,
            -- when its buffer and window options are fully initialized.
            local events = require("nvim-tree.api").events
            local function refresh_focus()
                vim.schedule(function()
                    require("config.options").update_cursorline()
                    vim.cmd("redraw")
                end)
            end
            events.subscribe(events.Event.TreeOpen, refresh_focus)
            events.subscribe(events.Event.TreeRendered, refresh_focus)
            -- Theme colors are shared with the editor and refreshed on switching.
            require("config.theme").highlights()

        end,
    },
}

