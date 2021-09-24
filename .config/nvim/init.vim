set nocompatible

call plug#begin(stdpath('data') . '/plugged')

" Code completion
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'

" Explorer
Plug 'preservim/nerdtree'

" Syntax high lighting
Plug 'sheerun/vim-polyglot'

" Themes
Plug 'lifepillar/vim-gruvbox8'
Plug 'joshdick/onedark.vim'
Plug 'Mofiqul/dracula.nvim'

" Bottom bar
Plug 'itchyny/lightline.vim'

call plug#end()


" Colorscheme
set termguicolors
colorscheme onedark

" Lightline colorscheme
let g:lightline = {
  \ 'colorscheme': 'onedark',
  \ }

" Tabs
set tabstop=4
set shiftwidth=4
set noexpandtab

" Scrolling
set scrolloff=5

" Line numbers
set number

" Line endings
set ff=unix
set fileformat=unix

" Auto resume
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" Navigation
nnoremap ö }
nnoremap ä {

" Tab navigation
nnoremap <Tab> gt
nnoremap <S-Tab> gT

" Split focus keymaps
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Spelling shortcuts
command SV setlocal spelllang=sv | setlocal spell | setlocal wrap linebreak
command EN setlocal spelllang=en | setlocal spell | setlocal wrap linebreak
command Nospell setlocal nospell | setlocal nowrap

" Default wraping behavior
set nowrap

" NERDTree
"" Open the existing NERDTree on each new tab
autocmd BufWinEnter * silent NERDTreeMirror
"" Mirror the NERDTree before showing it. This makes it the same on all tabs
nnoremap <C-n> :NERDTreeMirror<CR>:NERDTreeToggle<CR>
" nnoremap <C-n> :NERDTreeMirror<CR>:NERDTreeFocus<CR>

" Completion setup
set completeopt=menuone,noinsert,noselect
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']

lua << EOF

	local custom_lsp_attach = function(client)
		-- Options
		local opts = { noremap=true }

		-- See `:help nvim_buf_set_keymap()` for more information
		vim.api.nvim_buf_set_keymap(0, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
		vim.api.nvim_buf_set_keymap(0, 'n', '<c-K>', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
		vim.api.nvim_buf_set_keymap(0, 'n', 'E', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
		vim.api.nvim_buf_set_keymap(0, 'n', 'F', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
		-- ... and other keymappings for LSP

		-- Use LSP as the handler for omnifunc.
		--    See `:help omnifunc` and `:help ins-completion` for more information.
		vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')


		-- For plugins with an `on_attach` callback, call them here. For example:
		require('completion').on_attach()

	end

	-- C/C++
	require('lspconfig').ccls.setup({
		on_attach = custom_lsp_attach
	})

	-- Python
	require('lspconfig').pylsp.setup({
		on_attach = custom_lsp_attach
	})

	-- Go
	require('lspconfig').gopls.setup({
		on_attach = custom_lsp_attach
	})

	-- Rust
	require('lspconfig').rust_analyzer.setup({
		on_attach = custom_lsp_attach
	})

	-- Elm
	require('lspconfig').elmls.setup({
		on_attach = custom_lsp_attach
	})

	-- Haskell
	require('lspconfig').hls.setup({
		on_attach = custom_lsp_attach
	})

EOF
