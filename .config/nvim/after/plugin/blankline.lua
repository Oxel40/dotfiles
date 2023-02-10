require("indent_blankline").setup {
	show_current_context = true,
}

-- Disable tabline terminal
vim.g.indent_blankline_bufname_exclude = { 'terminal' }
