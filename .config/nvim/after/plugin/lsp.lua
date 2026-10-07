local group = vim.api.nvim_create_augroup('config_lsp', { clear = true })

vim.api.nvim_create_autocmd('LspAttach', {
	group = group,
	callback = function(args)
		local opts = { buffer = args.buf, desc = 'LSP: Format buffer' }
		vim.keymap.set({ 'n', 'x' }, '<F3>', function()
			vim.lsp.buf.format({ async = true })
		end, opts)
		vim.keymap.set('n', '<leader>dl', vim.diagnostic.open_float, {
			buffer = args.buf,
			desc = 'LSP: Show line diagnostics',
		})
	end,
})
