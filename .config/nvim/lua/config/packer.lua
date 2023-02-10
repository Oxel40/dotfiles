-- Bootstrap packer (the nvim package manager)
local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'
	-- My plugins here

	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.0',
		-- or                            , branch = '0.1.x',
		requires = { { 'nvim-lua/plenary.nvim' } }
	}

	-- Onedark theme
	use 'ii14/onedark.nvim'

	-- Treestitter
	use {
		'nvim-treesitter/nvim-treesitter',
		run = function()
			local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
			ts_update()
		end,
	}

	-- Harpoon
	-- use ''

	use {
		'VonHeikemen/lsp-zero.nvim',
		requires = {
			-- LSP Support
			{ 'neovim/nvim-lspconfig' }, -- Required
			{ 'williamboman/mason.nvim' }, -- Optional
			{ 'williamboman/mason-lspconfig.nvim' }, -- Optional

			-- Autocompletion
			{ 'hrsh7th/nvim-cmp' }, -- Required
			{ 'hrsh7th/cmp-nvim-lsp' }, -- Required
			{ 'hrsh7th/cmp-buffer' }, -- Optional
			{ 'hrsh7th/cmp-path' }, -- Optional
			{ 'saadparwaiz1/cmp_luasnip' }, -- Optional
			{ 'hrsh7th/cmp-nvim-lua' }, -- Optional

			-- Snippets
			{ 'L3MON4D3/LuaSnip' }, -- Required
			{ 'rafamadriz/friendly-snippets' }, -- Optional
		}
	}

	-- Color value highlighting
	use 'norcalli/nvim-colorizer.lua'

	-- Bottom bar
	-- use {
	-- 	'nvim-lualine/lualine.nvim',
	-- 	requires = { 'kyazdani42/nvim-web-devicons', opt = true }
	-- }
	use {
		'itchyny/lightline.vim',
		requires = {
			'josa42/nvim-lightline-lsp'
		}
	}

	-- Indent lines
	use 'lukas-reineke/indent-blankline.nvim'

	-- Startup time benchmark
	use 'tweekmonster/startuptime.vim'

	-- Zen mode
	use 'folke/zen-mode.nvim'

	-- Grammar check
	use 'rhysd/vim-grammarous'

	-- Undo tree
	use 'mbbill/undotree'

	-- Cheatsheet
	use {
		'sudormrfbin/cheatsheet.nvim',
		requires = {
			{ 'nvim-telescope/telescope.nvim' },
			{ 'nvim-lua/popup.nvim' },
			{ 'nvim-lua/plenary.nvim' },
		}
	}

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		require('packer').sync()
	end
end)
