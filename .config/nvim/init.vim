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

" Sub/Super-script alphas
execute "digraphs as " . 0x2090
execute "digraphs es " . 0x2091
execute "digraphs hs " . 0x2095
execute "digraphs is " . 0x1D62
execute "digraphs js " . 0x2C7C
execute "digraphs ks " . 0x2096
execute "digraphs ls " . 0x2097
execute "digraphs ms " . 0x2098
execute "digraphs ns " . 0x2099
execute "digraphs os " . 0x2092
execute "digraphs ps " . 0x209A
execute "digraphs rs " . 0x1D63
execute "digraphs ss " . 0x209B
execute "digraphs ts " . 0x209C
execute "digraphs us " . 0x1D64
execute "digraphs vs " . 0x1D65
execute "digraphs xs " . 0x2093

execute "digraphs aS " . 0x1d43
execute "digraphs bS " . 0x1d47
execute "digraphs cS " . 0x1d9c
execute "digraphs dS " . 0x1d48
execute "digraphs eS " . 0x1d49
execute "digraphs fS " . 0x1da0
execute "digraphs gS " . 0x1d4d
execute "digraphs hS " . 0x02b0
execute "digraphs iS " . 0x2071
execute "digraphs jS " . 0x02b2
execute "digraphs kS " . 0x1d4f
execute "digraphs lS " . 0x02e1
execute "digraphs mS " . 0x1d50
execute "digraphs nS " . 0x207f
execute "digraphs oS " . 0x1d52
execute "digraphs pS " . 0x1d56
execute "digraphs rS " . 0x02b3
execute "digraphs sS " . 0x02e2
execute "digraphs tS " . 0x1d57
execute "digraphs uS " . 0x1d58
execute "digraphs vS " . 0x1d5b
execute "digraphs wS " . 0x02b7
execute "digraphs xS " . 0x02e3
execute "digraphs yS " . 0x02b8
execute "digraphs zS " . 0x1dbb

execute "digraphs AS " . 0x1D2C
execute "digraphs BS " . 0x1D2E
execute "digraphs DS " . 0x1D30
execute "digraphs ES " . 0x1D31
execute "digraphs GS " . 0x1D33
execute "digraphs HS " . 0x1D34
execute "digraphs IS " . 0x1D35
execute "digraphs JS " . 0x1D36
execute "digraphs KS " . 0x1D37
execute "digraphs LS " . 0x1D38
execute "digraphs MS " . 0x1D39
execute "digraphs NS " . 0x1D3A
execute "digraphs OS " . 0x1D3C
execute "digraphs PS " . 0x1D3E
execute "digraphs RS " . 0x1D3F
execute "digraphs TS " . 0x1D40
execute "digraphs US " . 0x1D41
execute "digraphs VS " . 0x2C7D
execute "digraphs WS " . 0x1D42
