-- nvim-treesitter (main branch) dropped the configs module.
-- Highlighting is now handled by Neovim's built-in treesitter via vim.treesitter.start().
local group = vim.api.nvim_create_augroup('config_treesitter', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
	group = group,
	-- Add or remove filetypes here to control which ones get treesitter highlighting.
	-- markdown is intentionally excluded.
	pattern = { 'c', 'lua', 'python' },
	callback = function() vim.treesitter.start() end,
})
