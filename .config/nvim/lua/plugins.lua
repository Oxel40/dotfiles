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
	use 'junegunn/fzf.vim'

	-- Speedup neovim startup time
	use 'nathom/filetype.nvim'

	-- Startup time benchmark
	use 'tweekmonster/startuptime.vim'

end)
