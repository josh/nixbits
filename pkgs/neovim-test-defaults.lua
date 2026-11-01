vim.fn.writefile({
	vim.json.encode({
		colorscheme = vim.g.colors_name or "",
		background = vim.o.background,
		termguicolors = vim.o.termguicolors,
	}),
}, "defaults.json")
