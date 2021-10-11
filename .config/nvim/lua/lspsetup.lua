local nvim_lsp = require('lspconfig')

-- Function for setting lsp related keybindings
local custom_lsp_attach = function(client)
	-- Options
	local opts = { noremap=true }

	-- See `:help nvim_buf_set_keymap()` for more information
	vim.api.nvim_buf_set_keymap(0, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
	vim.api.nvim_buf_set_keymap(0, 'n', '<c-K>', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
	vim.api.nvim_buf_set_keymap(0, 'n', 'E', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
	vim.api.nvim_buf_set_keymap(0, 'n', 'F', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
	vim.api.nvim_buf_set_keymap(0, 'n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
	vim.api.nvim_buf_set_keymap(0, 'n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
	vim.api.nvim_buf_set_keymap(0, 'n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)

	-- ... and other keymappings for LSP

	-- Use LSP as the handler for omnifunc.
	--    See `:help omnifunc` and `:help ins-completion` for more information.
	vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')


	-- For plugins with an `on_attach` callback, call them here. For example:
	require('completion').on_attach()
	require('lsp_signature').on_attach()
end

-- Lsp setup
function setup_language_servers(server_list)
	for _, server in ipairs(server_list) do
		nvim_lsp[server].setup({
			on_attach = custom_lsp_attach
		})
	end

	-- Configure lspkind (symbols in completion menu)
	require('lspkind').init() -- might want to add a symbol map
end
