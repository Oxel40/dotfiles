set nocompatible

" Lua init
lua require('init')

" Colorscheme
"" let g:onedark_color_overrides = {
"" \ 'background': {'gui': '#1E222A', 'cterm': '235', 'cterm16': '0' },
"" \}
set termguicolors
colorscheme onedark

" " Lightline colorscheme
" let g:lightline = {
"   \ 'colorscheme': 'onedark',
"   \ }

" Lightline
let g:lightline = {
  \ 'active': {
  \   'left': [ [ 'mode' ], [ 'lsp_info', 'lsp_hints', 'lsp_errors', 'lsp_warnings', 'lsp_ok' ], [ 'lsp_status' ]]
  \ },
  \ 'colorscheme': 'onedark',
  \ }
"" Disable showmode, this is shown in line
set noshowmode
"" register lsp compoments:
call lightline#lsp#register()

" Tabs
set tabstop=4
set shiftwidth=4
set noexpandtab
autocmd FileType haskell setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
autocmd FileType elm setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

" Disable tabline in dashboard and terminal
let g:indent_blankline_bufname_exclude = ['dashboard', 'terminal']
let g:indent_blankline_buftype_exclude = ['dashboard', 'terminal']

" Tabline
set showtabline=2

" Scrolling
set scrolloff=5

" Line numbers
set number
autocmd TermOpen * setlocal nonumber norelativenumber

" Line endings
set ff=unix
set fileformat=unix

" Auto resume
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" Enable mouse suport
set mouse=nvi

" Mouse scroll, TODO: more smothness
" map <ScrollWheelUp> <C-Y>
" map <ScrollWheelDown> <C-E>
map <ScrollWheelUp> <C-y>
map <ScrollWheelDown> <C-e>

" Navigation
nnoremap ö }
nnoremap ä {
nnoremap Ö ]]
nnoremap Ä [[
" inoremap <C-h> <Left>
" inoremap <C-j> <Down>
" inoremap <C-k> <Up>
" inoremap <C-l> <Right>

" Tab navigation
nnoremap <Tab> gt
nnoremap <S-Tab> gT
nnoremap T :tabnew<CR>

" Split focus keymaps
" nnoremap <C-h> <C-w>h
" nnoremap <C-j> <C-w>j
" nnoremap <C-k> <C-w>k
" nnoremap <C-l> <C-w>l

" Spelling commands
command SpellSetup setlocal spell <bar> setlocal wrap linebreak <bar> execute 'nnoremap <buffer> j gj' <bar> execute 'nnoremap <buffer> k gk'
command SV setlocal spelllang=sv <bar> SpellSetup
command EN setlocal spelllang=en <bar> SpellSetup
command Nospell setlocal nospell <bar> setlocal nowrap <bar> execute 'unmap <buffer> j' <bar> execute 'unmap <buffer> k'

" Grammar check
let g:grammarous#default_comments_only_filetypes = {
            \ '*' : 1, 'help' : 0, 'markdown' : 0,
            \ }

" Default wraping behavior
set nowrap

"" " NERDTree
"" "" Open the existing NERDTree on each new tab
"" autocmd BufWinEnter * silent NERDTreeMirror
"" "" Mirror the NERDTree before showing it. This makes it the same on all tabs
"" nnoremap <C-n> :NERDTreeMirror<CR>:NERDTreeToggle<CR>
"" " nnoremap <C-n> :NERDTreeMirror<CR>:NERDTreeFocus<CR>

" Terminal mode
"" Exit terminal insert mode
tnoremap jk <C-\><C-n>

" Completion setup
set completeopt=menuone,noinsert,noselect
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']

" Dashboard setup (and related key bindings)
let g:mapleader="\<Space>"
" let g:dashboard_default_executive = 'fzf'
let g:dashboard_default_executive = 'telescope'
nmap <Leader>ss :<C-u>SessionSave<CR>
nmap <Leader>sl :<C-u>SessionLoad<CR>
nnoremap <silent> <Leader>fh :DashboardFindHistory<CR>
nnoremap <silent> <Leader>ff :DashboardFindFile<CR>
nnoremap <silent> <Leader>tc :DashboardChangeColorscheme<CR>
nnoremap <silent> <Leader>fa :DashboardFindWord<CR>
nnoremap <silent> <Leader>fb :DashboardJumpMark<CR>
nnoremap <silent> <Leader>cn :DashboardNewFile<CR>
" Dashboard image
let g:dashboard_custom_header =<< trim END
  ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣭⣿⣶⣿⣦⣼⣆         
   ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       
         ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷⠄⠄⠄⠄⠻⠿⢿⣿⣧⣄     
          ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    
         ⢠⣿⣿⣿⠈  ⠡⠌⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   
  ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘⠄ ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  
 ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   
⣠⣿⠿⠛⠄⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  
⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇⠄⠛⠻⢷⣄ 
     ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     
      ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     
END

source ~/.config/nvim/alphas.vim
source ~/.config/nvim/local.vim
