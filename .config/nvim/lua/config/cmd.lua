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
	"setlocal nospell nowrap nolinebreak <bar> execute 'silent! nunmap <buffer> j' <bar> execute 'silent! nunmap <buffer> k'",
	{}
)
vim.api.nvim_create_user_command(
	'Line80',
	'set colorcolumn=80',
	{}
)
vim.api.nvim_create_user_command(
	'Line0',
	'set colorcolumn=0',
	{}
)
