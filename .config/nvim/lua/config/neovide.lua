if vim.g.neovide then
	vim.o.guifont = "UbuntuMono Nerd Font:h14"
	
	local function save() vim.cmd.write() end
	local function copy() vim.cmd([[normal! "+y]]) end
	local function paste() vim.api.nvim_paste(vim.fn.getreg("+"), true, -1) end
	
	vim.keymap.set({ "n", "i", "v" }, "<S-C-s>", save, { desc = "Save" })
	vim.keymap.set("v", "<S-C-c>", copy, { silent = true, desc = "Copy" })
	vim.keymap.set({ "n", "i", "v", "c", "t" }, "<S-C-v>", paste, { silent = true, desc = "Paste" })
end
