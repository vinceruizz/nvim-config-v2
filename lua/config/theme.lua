
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

    -- Basic syntax highlighting
    set(0, "Comment",    { fg = colors.muted, italic = true })
    set(0, "String",     { fg = colors.orange })
    set(0, "Number",     { fg = colors.green })
    set(0, "Boolean",    { fg = colors.green })
    set(0, "Constant",   { fg = colors.green })
    set(0, "Function",   { fg = colors.cyan })
    set(0, "Statement",  { fg = colors.blue })
    set(0, "Keyword",    { fg = colors.blue })
    set(0, "Type",       { fg = colors.purple })
    set(0, "Identifier", { fg = colors.fg })
    set(0, "Special",    { fg = colors.orange })
    set(0, "PreProc",    { fg = colors.purple })

    -- Common Treesitter groups
    set(0, "@keyword",  { link = "Keyword" })
    set(0, "@function", { link = "Function" })
    set(0, "@string",   { link = "String" })
    set(0, "@comment",  { link = "Comment" })
    set(0, "@type",     { link = "Type" })
    set(0, "@number",   { link = "Number" })
    set(0, "@boolean",  { link = "Boolean" })
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

