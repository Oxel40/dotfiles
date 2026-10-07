-- Specific indentation
local group = vim.api.nvim_create_augroup('config', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
	group = group,
	pattern = 'haskell',
	command = 'setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab'
})

vim.api.nvim_create_autocmd('TermOpen', {
	group = group,
	pattern = '*',
	command = 'setlocal nonumber norelativenumber'
})

vim.api.nvim_create_autocmd('BufReadPost', {
	group = group,
	pattern = '*',
	command = [[ if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif ]]
})
