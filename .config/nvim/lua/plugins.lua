return require('packer').startup(function()

	-- LSP and completion
	use 'neovim/nvim-lspconfig'
	-- use 'nvim-lua/completion-nvim'
	-- use 'ray-x/lsp_signature.nvim'
	-- use 'onsails/lspkind-nvim'
	-- use 'SirVer/ultisnips'
	-- use 'honza/vim-snippets'
	-- Coq
	use {'ms-jpq/coq_nvim', branch = 'coq'}
	use {'ms-jpq/coq.artifacts', branch = 'artifacts'}
	use {'ms-jpq/coq.thirdparty', branch = '3p'}

	-- Syntax highlighting
	use {
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate'
	}

	-- Color value highlighting
	use 'norcalli/nvim-colorizer.lua'

	-- Onedark theme
	-- use 'joshdick/onedark.vim'
	use 'ii14/onedark.nvim'


	-- Bottom bar
	use 'itchyny/lightline.vim'
	use 'josa42/nvim-lightline-lsp'

	-- Indent lines
	use 'lukas-reineke/indent-blankline.nvim'

	-- Dashboard
	use 'glepnir/dashboard-nvim'
	-- use 'junegunn/fzf.vim'
	use {
		'nvim-telescope/telescope.nvim',
		requires = { {'nvim-lua/plenary.nvim'},
		             {'kyazdani42/nvim-web-devicons'},
					 {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
				   }
	}
	
	use {
		'sudormrfbin/cheatsheet.nvim',
		requires = {
			{'nvim-telescope/telescope.nvim'},
			{'nvim-lua/popup.nvim'},
			{'nvim-lua/plenary.nvim'},
		}
	}

	-- Speedup neovim startup time
	use 'nathom/filetype.nvim'

	-- Startup time benchmark
	use 'tweekmonster/startuptime.vim'

	-- Smooth scroll
	-- use 'karb94/neoscroll.nvim'

	use 'ollykel/v-vim'

	-- File tree
	use {
		'kyazdani42/nvim-tree.lua',
		requires = {
			'kyazdani42/nvim-web-devicons', -- optional, for file icons
		},
		tag = 'nightly' -- optional, updated every week. (see issue #1193)
	}
end)
