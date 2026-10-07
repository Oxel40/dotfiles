-- Bootstrap lazy.nvim (the plugin manager)
local ensure_lazy = function()
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not vim.uv.fs_stat(lazypath) then
		local output = vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable", -- latest stable release
			lazypath,
		})
		if vim.v.shell_error ~= 0 then
			error('Failed to clone lazy.nvim:\n' .. output)
		end
	end
	vim.opt.rtp:prepend(lazypath)
end

ensure_lazy()

vim.diagnostic.config {
	virtual_text = true,
	update_in_insert = false,
	severity_sort = true,
}

require('lazy').setup({
		{
			'nvim-telescope/telescope.nvim',
			dependencies = {
				'nvim-lua/plenary.nvim',
				{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
			}
		},

		-- Onedark theme
		{
			'ii14/onedark.nvim',
			lazy = false,
			priority = 1000,
		},

		-- Treesitter (main branch: new API, requires nvim 0.12+)
		{
			'nvim-treesitter/nvim-treesitter',
			branch = 'main',
			lazy = false,
			build = ':TSUpdate',
			config = function()
				-- Install parsers on startup. This is a no-op if already installed.
				require('nvim-treesitter').install({ 'c', 'lua', 'python' })
			end,
		},

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
				{ 'hrsh7th/cmp-nvim-lsp' },
			},
			config = function()
				local cmp = require('cmp')
				local luasnip = require('luasnip')
				require("luasnip.loaders.from_vscode").lazy_load()

				cmp.setup({
					snippet = {
						expand = function(args) luasnip.lsp_expand(args.body) end,
					},
					completion = {
						completeopt = "menu,menuone,noinsert",
					},
					sources = {
						{ name = 'path' },
						{ name = 'nvim_lsp' },
						{ name = 'luasnip', keyword_length = 2 },
						{ name = 'buffer',  keyword_length = 3 },
					},
					mapping = cmp.mapping.preset.insert({
						['<C-Space>'] = cmp.mapping.complete(),
						['<C-u>'] = cmp.mapping.scroll_docs(-4),
						['<C-d>'] = cmp.mapping.scroll_docs(4),
						['<C-f>'] = cmp.mapping(function()
							if luasnip.locally_jumpable(1) then luasnip.jump(1) end
						end, { 'i', 's' }),
						['<C-b>'] = cmp.mapping(function()
							if luasnip.locally_jumpable(-1) then luasnip.jump(-1) end
						end, { 'i', 's' }),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
					})
				})
			end
		},

		{
			'mason-org/mason-lspconfig.nvim',
			dependencies = {
				{ 'mason-org/mason.nvim', opts = {} },
				'neovim/nvim-lspconfig',
			},
			config = function()
				vim.lsp.config('*', {
					capabilities = require('cmp_nvim_lsp').default_capabilities(),
				})

                vim.lsp.config('rust_analyzer', {
                    settings = {
                        ['rust-analyzer'] = {
                            rustc = {
                                   source = "discover",
                            },
                        }
                    }
                })
				require('mason-lspconfig').setup()
			end
		},

		-- Color value highlighting
		{
			'norcalli/nvim-colorizer.lua',
			config = function()
				vim.opt.termguicolors = true
				require('colorizer').setup()
			end,
		},

		-- Bottom bar
		{
			'itchyny/lightline.vim',
			dependencies = {
				'josa42/nvim-lightline-lsp'
			},
			config = function()
				vim.g.lightline = {
					active = {
						left = {
							{ 'mode' },
							{ 'lsp_info', 'lsp_hints', 'lsp_errors', 'lsp_warnings', 'lsp_ok' },
							{ 'lsp_status' },
						},
					},
					colorscheme = 'onedark',
				}
				vim.o.showmode = false
				vim.fn['lightline#lsp#register']()
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
			}
		},

		-- Movement
		'easymotion/vim-easymotion',

		-- GitHub Copilot
		'github/copilot.vim',

	})
