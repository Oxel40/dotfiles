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

language_servers = {
	clangd={},
	pylsp={},
	gopls={},
	rust_analyzer={},
	hls={},
	-- java_language_server={cmd = {'/usr/bin/java-language-server'}}
	elmls={},
	gdscript={},
}

setup_language_servers(language_servers)

