
-- ==================================================
-- Custom Midnight Theme
-- Matches Kitty's background, opacity, and blur
-- ==================================================

vim.opt.termguicolors = true
vim.opt.background = "dark"

-- Built-in syntax highlighting
vim.cmd("syntax enable")

local colors = {
    fg      = "#e0d9c7", -- Default text
    muted   = "#8297aa", -- Comments and line numbers
    cyan    = "#86dbf5", -- Functions and accents
    blue    = "#5db2f8", -- Keywords
    orange  = "#ea9472", -- Strings
    purple  = "#c7a5e8", -- Types
    green   = "#a6d7a0", -- Constants
    border  = "#46657e",
}

local set = vim.api.nvim_set_hl

local function apply_theme()
    -- Transparent backgrounds
    set(0, "Normal",       { fg = colors.fg, bg = "NONE" })
    set(0, "NormalNC",     { fg = colors.fg, bg = "NONE" })
    set(0, "NormalFloat",  { fg = colors.fg, bg = "NONE" })
    set(0, "SignColumn",   { bg = "NONE" })
    set(0, "EndOfBuffer",  { fg = "NONE", bg = "NONE" })
    set(0, "FloatBorder",  { fg = colors.border, bg = "NONE" })
    set(0, "WinSeparator",{ fg = colors.border, bg = "NONE" })
    set(0, "LineNr",       { fg = "#9aafc2", bg = "NONE" })
    set(0, "CursorLine", { bg = "#24394b" })
    set(0, "CursorLineNr", {
        fg = "#f5b66c",
        bg = "#24394b",
        bold = true,
    })
    set(0, "Visual",       { bg = "#29465e" })
    set(0, "Search",       { fg = "#070f1c", bg = colors.cyan })
    set(0, "IncSearch",    { fg = "#070f1c", bg = colors.orange })
    set(0, "Pmenu",        { fg = colors.fg, bg = "NONE" })
    set(0, "PmenuSel",     { fg = "#070f1c", bg = colors.cyan })
    set(0, "StatusLine",   { fg = colors.fg, bg = "NONE" })
    set(0, "StatusLineNC", { fg = colors.muted, bg = "NONE" })

    -- One Dark-inspired syntax; keep the existing transparent UI styling.
    local syntax = {
        fg = "#abb2bf", comment = "#7f848e", red = "#e06c75",
        green = "#98c379", yellow = "#e5c07b", blue = "#61afef",
        purple = "#c678dd", cyan = "#56b6c2", orange = "#d19a66",
    }
    local groups = {
        Comment = { fg = syntax.comment, italic = true },
        String = { fg = syntax.green },
        Character = { fg = syntax.green },
        Number = { fg = syntax.orange },
        Float = { fg = syntax.orange },
        Boolean = { fg = syntax.orange },
        Constant = { fg = syntax.orange },
        Function = { fg = syntax.blue },
        Statement = { fg = syntax.purple },
        Keyword = { fg = syntax.purple },
        Type = { fg = syntax.yellow },
        Identifier = { fg = syntax.red },
        Special = { fg = syntax.cyan },
        PreProc = { fg = syntax.yellow },
        Operator = { fg = syntax.cyan },
        Delimiter = { fg = syntax.fg },
        DiagnosticError = { fg = syntax.red },
        DiagnosticWarn = { fg = syntax.yellow },
        DiagnosticInfo = { fg = syntax.blue },
        DiagnosticHint = { fg = syntax.comment },
    }
    for group, definition in pairs(groups) do
        set(0, group, definition)
    end

    local captures = {
        ["@comment"] = "Comment", ["@string"] = "String",
        ["@character"] = "Character", ["@number"] = "Number",
        ["@boolean"] = "Boolean", ["@constant"] = "Constant",
        ["@function"] = "Function", ["@function.builtin"] = "Special",
        ["@function.call"] = "Function", ["@function.method"] = "Function",
        ["@function.method.call"] = "Function", ["@constructor"] = "Type",
        ["@keyword"] = "Keyword", ["@keyword.operator"] = "Keyword",
        ["@operator"] = "Operator", ["@type"] = "Type",
        ["@type.builtin"] = "Type", ["@module"] = "Type",
        ["@variable.member"] = "Identifier", ["@property"] = "Identifier",
        ["@tag"] = "Identifier", ["@tag.attribute"] = "Type",
        ["@punctuation"] = "Delimiter", ["@punctuation.delimiter"] = "Delimiter",
        ["@punctuation.bracket"] = "Delimiter", ["@punctuation.special"] = "Special",
    }
    set(0, "@variable", { fg = syntax.fg })
    set(0, "@variable.parameter", { fg = syntax.fg })
    set(0, "@variable.builtin", { fg = syntax.red })
    for capture, group in pairs(captures) do
        set(0, capture, { link = group })
    end
    -- Noice floating command popup
set(0, "NoiceCmdlinePopup", {
    fg = "#e0d9c7",
    bg = "#142638",
})

set(0, "NoiceCmdlinePopupBorder", {
    fg = "#86dbf5",
    bg = "#142638",
})

set(0, "NoiceCmdlineIconCmdline", {
    fg = "#f5b66c",
    bold = true,
})

set(0, "NoiceCmdlineIconSearch", {
    fg = "#86dbf5",
})

-- Autocomplete menu
set(0, "Pmenu", {
    fg = "#e0d9c7",
    bg = "#142638",
})

set(0, "PmenuSel", {
    fg = "#070f1c",
    bg = "#86dbf5",
    bold = true,
})
end

apply_theme()

