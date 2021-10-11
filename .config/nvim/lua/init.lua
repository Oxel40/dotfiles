-- Do not source the default filetype.vim
vim.g.did_load_filetypes = 1

require('plugins')
require('lspsetup')
require("indent_blankline").setup {
    show_current_context = true,
}

language_servers = {'ccls', 'pylsp', 'gopls', 'rust_analyzer', 'hls'}

setup_language_servers(language_servers)

