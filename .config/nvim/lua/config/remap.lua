-- Leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- File exporer
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

-- Mouse scroll
-- vim.keymap.set('', '<ScrollWheelUp>', '<C-y>')
-- vim.keymap.set('', '<ScrollWheelDown>', '<C-e>')

-- Navigation
vim.keymap.set('n', 'ö', '}')
vim.keymap.set('n', 'ä', '{')
vim.keymap.set('n', 'Ö', ']]')
vim.keymap.set('n', 'Ä', '[[')
-- inoremap <C-h> <Left>
-- inoremap <C-j> <Down>
-- inoremap <C-k> <Up>
-- inoremap <C-l> <Right>

-- Tab navigation
vim.keymap.set('n', '<Tab>', 'gt')
vim.keymap.set('n', '<S-Tab>', 'gT')
vim.keymap.set('n', 'T', ':tabnew<CR>')

-- Terminal (exit insert mode)
vim.keymap.set('t', 'jk', '<C-\\><C-n>')

-- Indentation in visual mode
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('v', '<', '<gv')
