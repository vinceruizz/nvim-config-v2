vim.g.mapleader = " "

require("config.runtime").setup()
require("config.options")
require("config.keymaps")
require("config.theme").setup()
require("config.lazy")
require("config.treesitter")

