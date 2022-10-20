-- Do not source the default filetype.vim
vim.g.did_load_filetypes = 1
-- Autostart COQ
vim.g.coq_settings = { auto_start = 'shut-up' }
-- Terminal colors
vim.o.termguicolors = true

require('plugins')
require('lspsetup')
require("indent_blankline").setup {
    show_current_context = true,
}
require('colorizer').setup()
require('nvim-treesitter.configs').setup({
	highlight = {enable = true}
})
require('telescope').load_extension('fzf')
require('telescope').load_extension('file_browser')
-- require('neoscroll').setup()

require("nvim-tree").setup()

local db = require('dashboard')
-- db.preview_file_height = 11
-- db.preview_file_width = 70
db.session_directory = os.getenv('HOME') .. '/.local/share/nvim/sessions/'
db.hide_statusline = false
db.hide_tabline = false
db.custom_center = {
	{icon = '  ',
	desc = 'Recently latest session                 ',
	shortcut = 'SPC s l',
	action ='SessionLoad'},
	{icon = '  ',
	desc = 'Recently opened files                   ',
	action =  'Telescope oldfiles',
	shortcut = 'SPC f h'},
	{icon = '  ',
	desc = 'Find  File                              ',
	action = 'Telescope find_files',
	shortcut = 'SPC f f'},
	{icon = '  ',
	desc ='File Browser                            ',
	action =  'Telescope file_browser',
	shortcut = 'SPC f b'},
	{icon = '𝔐  ',
	desc = 'Find word                               ',
	action = 'Telescope live_grep',
	shortcut = 'SPC f g'},
}
db.custom_header = {
    '',
    '  ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣭⣿⣶⣿⣦⣼⣆         ',
    '   ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ',
    '         ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷⠄⠄⠄⠄⠻⠿⢿⣿⣧⣄     ',
    '          ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ',
    '         ⢠⣿⣿⣿⠈  ⠡⠌⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ',
    '  ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘⠄ ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ',
    ' ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ',
    '⣠⣿⠿⠛⠄⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ',
    '⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇⠄⠛⠻⢷⣄ ',
    '     ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ',
    '      ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ',
    '',
}

language_servers = {
	clangd={},
	pylsp={},
	gopls={},
	gdscript={},
	rust_analyzer={},
	hls={},
	elmls={},
	gdscript={},
	java_language_server={cmd = {'/usr/bin/java-language-server'}},
	elixirls={cmd = {'/usr/bin/elixir-ls'}},
	tsserver={},
}

setup_language_servers(language_servers)

