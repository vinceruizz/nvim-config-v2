local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.cursorlineopt = "both"

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true

-- Editing
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Scrolling
opt.scrolloff = 8

-- Hide ~ characters on empty lines
vim.opt.fillchars:append({ eob = " " })
