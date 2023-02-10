local lsp = require('lsp-zero')

lsp.preset('recommended')
lsp.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr }
	local bind = vim.keymap.set

	bind('n', 'F', ':LspZeroFormat!<CR>', opts)
end)
lsp.setup()
