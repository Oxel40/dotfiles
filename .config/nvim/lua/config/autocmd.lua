-- Specific indentation
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'haskell,elixir',
	command = 'setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab'
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'elm,python',
	command = 'setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab'
})

-- No line numbers in terminal
-- autocmd TermOpen * setlocal nonumber norelativenumber
vim.api.nvim_create_autocmd('TermOpen', {
	pattern = '*',
	command = 'setlocal nonumber norelativenumber'
})

-- Auto resume
-- if has("autocmd")
--   au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
-- endif
vim.api.nvim_create_autocmd('BufReadPost', {
	pattern = '*',
	command = [[ if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif ]]
})
