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
-- require('neoscroll').setup()

require("nvim-tree").setup()

language_servers = {
	clangd={},
	pylsp={},
	gopls={},
	gdscript={},
	rust_analyzer={},
	hls={},
	elmls={},
	gdscript={},
	java_language_server={cmd = {'/usr/bin/java-language-server'}}
}

setup_language_servers(language_servers)

