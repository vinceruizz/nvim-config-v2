local M = {}
local ids = { "forest-cartridge", "midnight" }
local active, palette
local preferences = { theme = "forest-cartridge", transparency = {} }
local palette_dir = vim.fn.stdpath("config") .. "/lua/themes"
local state_file = vim.fn.stdpath("state") .. "/theme.json"
local pending
local required = {
    "bg", "fg", "muted", "comment", "surface", "raised", "border", "line", "selection", "line_nr",
    "accent", "amber", "blue", "cyan", "green", "purple", "orange", "red", "syntax_fg", "keyword",
    "string", "func", "type", "variable", "member", "number", "punctuation", "debug_line", "breakpoint",
}

local function load_palette(id)
    assert(vim.tbl_contains(ids, id), "Unknown theme: " .. tostring(id))
    local path = palette_dir .. "/" .. id .. ".lua"
    local chunk = assert(loadfile(path))
    local p = chunk()
    assert(type(p) == "table" and type(p.colors) == "table", "Theme must return a palette table")
    assert(type(p.name) == "string" and type(p.transparent) == "boolean" and type(p.retro) == "boolean", "Missing theme metadata")
    assert(p.border_style == "single" or p.border_style == "rounded", "Invalid border_style")
    for _, key in ipairs(required) do
        assert(type(p.colors[key]) == "string" and p.colors[key]:match("^#%x%x%x%x%x%x$"), "Invalid color: " .. key)
    end
    return p
end

function M.get()
    return { id = active, palette = palette, transparent = active and preferences.transparency[active] }
end

function M.border()
    return palette and palette.border_style or "rounded"
end

local function save()
    local ok, err = pcall(function()
        vim.fn.mkdir(vim.fs.dirname(state_file), "p")
        local temporary = state_file .. "." .. vim.uv.os_getpid() .. ".tmp"
        assert(vim.fn.writefile({ vim.json.encode(preferences) }, temporary) == 0)
        assert(vim.uv.fs_rename(temporary, state_file))
    end)
    if not ok then vim.notify("Could not save theme preference: " .. tostring(err), vim.log.levels.WARN) end
end

function M.highlights()
    if not palette then return end
    local c = palette.colors
    local background = preferences.transparency[active] and "NONE" or c.bg
    local set = function(name, spec) vim.api.nvim_set_hl(0, name, spec) end
    local groups = {
        Normal = { fg = c.fg, bg = background }, NormalNC = { fg = c.fg, bg = background },
        NormalFloat = { fg = c.fg, bg = c.surface }, FloatBorder = { fg = c.border, bg = c.surface },
        FloatTitle = { fg = c.accent, bg = c.surface, bold = true },
        SignColumn = { bg = background }, EndOfBuffer = { fg = background, bg = background },
        WinSeparator = { fg = c.border, bg = background }, LineNr = { fg = c.line_nr, bg = background },
        CursorLine = { bg = c.line }, CursorLineNr = { fg = c.amber, bg = c.line, bold = true },
        Cursor = { fg = c.bg, bg = c.accent }, Visual = { bg = c.selection },
        Search = { fg = c.bg, bg = c.accent }, IncSearch = { fg = c.bg, bg = c.amber },
        CurSearch = { fg = c.bg, bg = c.amber, bold = true }, MatchParen = { fg = c.amber, bg = c.selection, bold = true },
        Pmenu = { fg = c.fg, bg = c.surface }, PmenuSel = { fg = c.bg, bg = c.accent, bold = true },
        PmenuSbar = { bg = c.raised }, PmenuThumb = { bg = c.border },
        StatusLine = { fg = c.fg, bg = c.surface }, StatusLineNC = { fg = c.muted, bg = c.surface },
        TabLine = { fg = c.muted, bg = c.surface }, TabLineSel = { fg = c.bg, bg = c.accent, bold = true },
        TabLineFill = { bg = background }, Title = { fg = c.accent, bold = true },
        NonText = { fg = c.border }, Whitespace = { fg = c.border }, SpecialKey = { fg = c.border },
        Folded = { fg = c.muted, bg = c.surface }, FoldColumn = { fg = c.muted, bg = background },
        Directory = { fg = c.accent }, ErrorMsg = { fg = c.red, bold = true }, WarningMsg = { fg = c.amber },
        MoreMsg = { fg = c.accent }, Question = { fg = c.accent }, WinBar = { fg = c.fg, bg = c.surface },
        Comment = { fg = c.comment, italic = not palette.retro }, String = { fg = c.string }, Character = { fg = c.string },
        Number = { fg = c.number }, Float = { fg = c.number }, Boolean = { fg = c.number }, Constant = { fg = c.number },
        Function = { fg = c.func }, Statement = { fg = c.keyword }, Keyword = { fg = c.keyword, bold = palette.retro },
        Type = { fg = c.type }, Identifier = { fg = c.member }, Special = { fg = c.cyan }, PreProc = { fg = c.type },
        Operator = { fg = c.cyan }, Delimiter = { fg = c.punctuation },
        DiffAdd = { bg = c.debug_line }, DiffChange = { bg = c.raised },
        DiffDelete = { fg = c.red, bg = c.surface }, DiffText = { fg = c.bg, bg = c.blue },
        DiagnosticError = { fg = c.red }, DiagnosticWarn = { fg = c.amber },
        DiagnosticInfo = { fg = c.blue }, DiagnosticHint = { fg = c.muted },
        DiagnosticUnderlineError = { undercurl = true, sp = c.red }, DiagnosticUnderlineWarn = { undercurl = true, sp = c.amber },
        DapBreakpoint = { fg = c.breakpoint }, DapLogPoint = { fg = c.accent },
        DapStopped = { fg = c.amber, bold = true }, DapStoppedLine = { bg = c.debug_line },
        DapUIScope = { fg = c.accent, bold = true }, DapUIType = { fg = c.type },
        DapUIValue = { fg = c.fg }, DapUIVariable = { fg = c.blue }, DapUIDecoration = { fg = c.border },
        DapUIThread = { fg = c.accent }, DapUIStoppedThread = { fg = c.amber }, DapUIFrameName = { fg = c.blue },
        DapUIPlayPause = { fg = c.green }, DapUIStop = { fg = c.red }, DapUIRestart = { fg = c.amber },
        NvimTreeNormal = { fg = c.fg, bg = background }, NvimTreeNormalNC = { fg = c.fg, bg = background },
        NvimTreeFolderName = { fg = c.accent }, NvimTreeOpenedFolderName = { fg = c.amber, bold = true },
        NvimTreeRootFolder = { fg = c.amber, bold = true }, NvimTreeIndentMarker = { fg = c.border },
        NvimTreeGitDirty = { fg = c.amber }, NvimTreeGitNew = { fg = c.green }, NvimTreeGitDeleted = { fg = c.red },
        NoiceCmdlinePopup = { fg = c.fg, bg = c.surface }, NoiceCmdlinePopupBorder = { fg = c.accent, bg = c.surface },
        NoiceCmdlinePopupTitle = { fg = c.accent, bg = c.surface, bold = true },
        NoiceCmdlineIconCmdline = { fg = c.amber, bold = true }, NoiceCmdlineIconSearch = { fg = c.accent },
        TelescopeNormal = { fg = c.fg, bg = c.surface }, TelescopeBorder = { fg = c.border, bg = c.surface },
        TelescopeTitle = { fg = c.accent, bold = true }, TelescopeSelection = { bg = c.line, bold = true },
        TelescopeMatching = { fg = c.amber, bold = true }, TelescopePromptPrefix = { fg = c.accent },
        CheatNormal = { fg = c.fg, bg = c.surface }, CheatBorder = { fg = c.border, bg = c.surface },
        CheatCard = { fg = c.border }, CheatTitle = { fg = c.accent, bold = true },
        CheatHeading = { fg = c.amber, bold = true }, CheatMuted = { fg = c.muted },
        CheatKey = { fg = c.accent, bg = c.raised, bold = true },
    }
    for name, spec in pairs(groups) do set(name, spec) end
    local links = {
        NvimTreeCursorLine = "CursorLine", NvimTreeCursorLineNr = "CursorLineNr", NvimTreeLineNr = "LineNr",
        NvimTreeEndOfBuffer = "EndOfBuffer", NvimTreeWinSeparator = "WinSeparator", NvimTreeNormalFloat = "NormalFloat",
        NvimTreeNormalFloatBorder = "FloatBorder", DapUIFloatNormal = "NormalFloat", DapUIFloatBorder = "FloatBorder",
        NvimDapVirtualText = "Comment", NvimDapVirtualTextChanged = "DiagnosticWarn",
        ["@comment"] = "Comment", ["@string"] = "String", ["@character"] = "Character", ["@number"] = "Number",
        ["@boolean"] = "Boolean", ["@constant"] = "Constant", ["@function"] = "Function", ["@function.call"] = "Function",
        ["@function.builtin"] = "Special", ["@function.method"] = "Function", ["@function.method.call"] = "Function",
        ["@constructor"] = "Type", ["@keyword"] = "Keyword", ["@keyword.operator"] = "Keyword",
        ["@operator"] = "Operator", ["@type"] = "Type", ["@type.builtin"] = "Type", ["@module"] = "Type",
        ["@variable.member"] = "Identifier", ["@property"] = "Identifier", ["@tag"] = "Identifier",
        ["@tag.attribute"] = "Type", ["@punctuation"] = "Delimiter", ["@punctuation.delimiter"] = "Delimiter",
        ["@punctuation.bracket"] = "Delimiter", ["@punctuation.special"] = "Special",
    }
    for name, link in pairs(links) do set(name, { link = link }) end
    set("@variable", { fg = c.variable }); set("@variable.parameter", { fg = c.variable }); set("@variable.builtin", { fg = c.red })
    -- Applications in Neovim's terminal get the same 16-color palette.
    for index, color in ipairs({ c.bg, c.red, c.green, c.amber, c.blue, c.purple, c.cyan, c.fg,
        c.muted, c.red, c.green, c.amber, c.blue, c.purple, c.accent, c.fg }) do
        vim.g["terminal_color_" .. index - 1] = color
    end
end

local function update_borders()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" and type(config.border) == "table" and #config.border > 0 then
            vim.api.nvim_win_set_config(win, { border = M.border() })
        end
    end
end

local function refresh()
    if not palette then return end
    M.highlights()
    if package.loaded["lualine"] then require("config.theme_statusline").setup() end
    update_borders()
end

-- Called by colors/*.lua so :colorscheme works and ColorScheme events fire.
function M.apply(id)
    local p = pending and pending.id == id and pending.palette or load_palette(id)
    vim.cmd("highlight clear")
    if vim.g.syntax_on then vim.cmd("syntax reset") end
    active, palette = id, p
    if preferences.transparency[id] == nil then preferences.transparency[id] = p.transparent end
    preferences.theme = id
    vim.o.background = "dark"
    vim.o.winborder = p.border_style
    vim.g.colors_name = id
    M.highlights()
    if not pending or pending.persist then save() end
end

function M.set(id, persist)
    local ok, p = pcall(load_palette, id)
    if not ok then vim.notify("Theme unchanged: " .. tostring(p), vim.log.levels.ERROR); return false end
    local previous = { id = active, palette = palette, preferences = vim.deepcopy(preferences) }
    pending = { id = id, palette = p, persist = persist ~= false }
    local applied, err = pcall(vim.cmd.colorscheme, id)
    pending = nil
    if not applied then
        active, palette, preferences = previous.id, previous.palette, previous.preferences
        if palette then vim.g.colors_name = active; vim.o.winborder = palette.border_style; refresh() end
        vim.notify("Theme unchanged: " .. tostring(err), vim.log.levels.ERROR)
        return false
    end
    refresh()
    return true
end

function M.reload()
    return M.set(active or preferences.theme, false)
end

function M.toggle_transparency()
    preferences.transparency[active] = not preferences.transparency[active]
    refresh()
    save()
    vim.api.nvim_exec_autocmds("ColorScheme", { pattern = active, modeline = false })
end

function M.pick()
    vim.ui.select(ids, {
        prompt = "Choose a theme",
        format_item = function(id) return id == "forest-cartridge" and "Forest Cartridge" or "Midnight" end,
    }, function(id) if id then M.set(id) end end)
end

function M.setup(options)
    options = options or {}
    palette_dir = options.palette_dir or vim.fn.stdpath("config") .. "/lua/themes"
    state_file = options.state_file or vim.env.NVIM_THEME_STATE_FILE or vim.fn.stdpath("state") .. "/theme.json"
    if vim.fn.filereadable(state_file) == 1 then
        local ok, saved = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(state_file), "\n")) end)
        if ok and type(saved) == "table" and vim.tbl_contains(ids, saved.theme) then
            preferences.theme = saved.theme
            if type(saved.transparency) == "table" then
                for _, id in ipairs(ids) do
                    if type(saved.transparency[id]) == "boolean" then preferences.transparency[id] = saved.transparency[id] end
                end
            end
        end
    end
    local group = vim.api.nvim_create_augroup("SwitchableTheme", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = function()
        if vim.tbl_contains(ids, vim.g.colors_name) then refresh() end
    end })
    vim.api.nvim_create_autocmd("WinNew", { group = group, callback = function() vim.schedule(update_borders) end })
    vim.api.nvim_create_autocmd("BufWritePost", { group = group, pattern = "*.lua", callback = function(event)
        local path = vim.fs.normalize(vim.api.nvim_buf_get_name(event.buf))
        local directory = vim.uv.fs_realpath(vim.fs.dirname(path))
        if active and directory == vim.uv.fs_realpath(palette_dir) and vim.fs.basename(path) == active .. ".lua" then M.reload() end
    end })
    vim.api.nvim_create_user_command("Theme", function(args)
        if args.args == "" then M.pick() else M.set(args.args) end
    end, { nargs = "?", complete = function() return ids end })
    vim.api.nvim_create_user_command("ThemeReload", M.reload, {})
    vim.keymap.set("n", "<leader>ut", M.pick, { desc = "Choose theme" })
    vim.keymap.set("n", "<leader>ub", M.toggle_transparency, { desc = "Toggle theme transparency" })
    vim.opt.termguicolors = true
    vim.cmd("syntax enable")
    if not M.set(preferences.theme, false) then M.set("midnight", false) end
end

return M
