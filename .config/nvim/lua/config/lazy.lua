-- Bootstrap packer (the nvim package manager)
local ensure_lazy = function()
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	local out = true
	if not vim.loop.fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable", -- latest stable release
			lazypath,
		})
		out = false
	end
	vim.opt.rtp:prepend(lazypath)
	return out
end

local lazy_bootstrap = ensure_lazy()

require('lazy').setup({
	'folke/lazy.nvim',
	-- My plugins here

	{
		'nvim-telescope/telescope.nvim',
		branch = '0.1.x',
		dependencies = { { 'nvim-lua/plenary.nvim' } }
	},

	-- Onedark theme
	{
		'ii14/onedark.nvim',
		lazy = false,
		priority = 1000,
	},

	-- Treestitter
	{
		'nvim-treesitter/nvim-treesitter',
		build = function()
			local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
			ts_update()
		end,
	},

	-- Harpoon
	-- ''

	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		}
	},

	-- LSP Zero
	-- {
	-- 	'VonHeikemen/lsp-zero.nvim',
	-- 	config = true,
	-- 	dependencies = {
	-- 		{ 
	-- 			'williamboman/mason.nvim', -- Optional
	-- 			lazy = false,
	-- 			config = true,
	-- 		},

	-- 		-- LSP Support
	-- 		{
	-- 			'neovim/nvim-lspconfig', -- Required
	-- 			cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
	-- 			event = { 'BufReadPre', 'BufNewFile' },
	-- 			dependencies = {
	-- 				{ 'hrsh7th/cmp-nvim-lsp' }, -- Required
	-- 				{ 'williamboman/mason-lspconfig.nvim' }, -- Optional
	-- 			},
	-- 		},

	-- 		-- Autocompletion
	-- 		{
	-- 			'hrsh7th/nvim-cmp', -- Required
	-- 			event = 'InsertEnter',
	-- 			dependencies = {
	-- 				{ 'hrsh7th/cmp-buffer' }, -- Optional
	-- 				{ 'hrsh7th/cmp-path' }, -- Optional
	-- 				{ 'saadparwaiz1/cmp_luasnip' }, -- Optional
	-- 				{ 'hrsh7th/cmp-nvim-lua' }, -- Optional
	-- 				-- Snippets
	-- 				{ 'L3MON4D3/LuaSnip' }, -- Required
	-- 				{ 'rafamadriz/friendly-snippets' }, -- Optional
	-- 			},
	-- 		},
	-- 	}
	-- },
	{
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v3.x',
		lazy = true,
		config = true,
		init = function()
			-- Disable automatic setup, we are doing it manually
			-- vim.g.lsp_zero_extend_cmp = 0
			-- vim.g.lsp_zero_extend_lspconfig = 0
		end,
	},
	{
		'williamboman/mason.nvim',
		lazy = false,
		config = true,
	},

	-- Autocompletion
	{
		'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		dependencies = {
			{ 'L3MON4D3/LuaSnip' },
			{ 'rafamadriz/friendly-snippets' },
			{ 'saadparwaiz1/cmp_luasnip' },
			{ 'hrsh7th/cmp-path' },
			{ 'hrsh7th/cmp-buffer' },
		},
		config = function()
			-- Here is where you configure the autocompletion settings.
			local lsp_zero = require('lsp-zero')
			lsp_zero.set_sign_icons({
				error = '>>',
				warn = '>>',
				hint = '>>',
				info = '>>'
			})
			lsp_zero.on_attach(function(client, bufnr)
				local opts = { buffer = bufnr, remap = false }

				vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
				vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
				vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
				vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
				vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
				vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
				vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
				vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
				vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
				vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
			end)
			lsp_zero.extend_cmp()

			-- And you can configure cmp even more, if you want to.
			local cmp = require('cmp')
			require("luasnip.loaders.from_vscode").lazy_load()
			local cmp_action = lsp_zero.cmp_action()

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				sources = {
					{ name = 'path' },
					{ name = 'nvim_lsp' },
					{ name = 'nvim_lua' },
					{ name = 'luasnip', keyword_length = 2 },
					{ name = 'buffer',	keyword_length = 3 },
				},
				formatting = lsp_zero.cmp_format(),
				mapping = cmp.mapping.preset.insert({
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-u>'] = cmp.mapping.scroll_docs(-4),
					['<C-d>'] = cmp.mapping.scroll_docs(4),
					['<C-f>'] = cmp_action.luasnip_jump_forward(),
					['<C-b>'] = cmp_action.luasnip_jump_backward(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				})
			})
		end
	},

	-- LSP
	{
		'neovim/nvim-lspconfig',
		cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
		event = { 'BufReadPre', 'BufNewFile' },
		dependencies = {
			{ 'hrsh7th/cmp-nvim-lsp' },
			{ 'williamboman/mason-lspconfig.nvim' },
		},
		config = function()
			-- This is where all the LSP shenanigans will live
			local lsp_zero = require('lsp-zero')
			lsp_zero.extend_lspconfig()
			--- if you want to know more about lsp-zero and mason.nvim
			--- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
			lsp_zero.on_attach(function(client, bufnr)
				-- see :help lsp-zero-keybindings
				-- to learn the available actions
				local opts = { buffer = bufnr }
				-- local bind = vim.keymap.set
				lsp_zero.default_keymaps(opts)
				-- bind('n', 'F', ':LspZeroFormat!<CR>', opts)
			end)

			require('mason-lspconfig').setup({
				ensure_installed = {},
				handlers = {
					lsp_zero.default_setup,
					lua_ls = function()
						-- (Optional) Configure lua language server for neovim
						local lua_opts = lsp_zero.nvim_lua_ls()
						require('lspconfig').lua_ls.setup(lua_opts)
					end,
				}
			})
		end
	},

	-- Color value highlighting
	{
		'norcalli/nvim-colorizer.lua',
		lazy = false,
	},

	-- Bottom bar
	{
		'itchyny/lightline.vim',
		dependencies = {
			'josa42/nvim-lightline-lsp'
		},
		config = function()
			vim.api.nvim_exec(
			[[
			let g:lightline = {
			  \ 'active': {
			  \   'left': [ [ 'mode' ], [ 'lsp_info', 'lsp_hints', 'lsp_errors', 'lsp_warnings', 'lsp_ok' ], [ 'lsp_status' ] ]
			  \ },
			  \ 'colorscheme': 'onedark',
			  \ }
			
			set noshowmode
			call lightline#lsp#register()
			]],
			true)
		end
	},

	-- Indent lines
	'lukas-reineke/indent-blankline.nvim',

	-- Startup time benchmark
	'tweekmonster/startuptime.vim',

	-- Zen mode
	'folke/zen-mode.nvim',

	-- Grammar check
	'rhysd/vim-grammarous',

	-- Undo tree
	'mbbill/undotree',

	-- Cheatsheet
	{
		'sudormrfbin/cheatsheet.nvim',
		dependencies = {
			{ 'nvim-telescope/telescope.nvim' },
			{ 'nvim-lua/popup.nvim' },
			{ 'nvim-lua/plenary.nvim' },
		}
	},

	-- Movement
	'easymotion/vim-easymotion',

	-- GitHub Copilot
	--'github/copilot.vim'
},
vim.diagnostic.config {
  virtual_text = true,
  update_in_insert = true,
})
