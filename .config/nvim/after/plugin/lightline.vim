let g:lightline = {
  \ 'active': {
  \   'left': [ [ 'mode' ], [ 'lsp_info', 'lsp_hints', 'lsp_errors', 'lsp_warnings', 'lsp_ok' ], [ 'lsp_status' ] ]
  \ },
  \ 'colorscheme': 'onedark',
  \ }

set noshowmode
call lightline#lsp#register()
