-- Spelling commands
vim.api.nvim_create_user_command(
	'SpellSetup',
	"setlocal spell <bar> setlocal wrap linebreak <bar> execute 'nnoremap <buffer> j gj' <bar> execute 'nnoremap <buffer> k gk'"
	,
	{}
)
vim.api.nvim_create_user_command(
	'SV',
	'setlocal spelllang=sv <bar> SpellSetup',
	{}
)
vim.api.nvim_create_user_command(
	'EN',
	'setlocal spelllang=en <bar> SpellSetup',
	{}
)
vim.api.nvim_create_user_command(
	'Nospell',
	"setlocal nospell <bar> setlocal nowrap <bar> execute 'unmap <buffer> j' <bar> execute 'unmap <buffer> k'",
	{}
)
