local theme = vim.env.THEME or ""
for _, mapping in ipairs(vim.json.decode(vim.env.NIXBITS_NVIM_THEMES)) do
	if vim.fn.match(theme, vim.fn.glob2regpat(mapping.pattern)) ~= -1 then
		vim.opt.termguicolors = mapping.colorscheme ~= "default"
		vim.opt.background = mapping.background
		vim.cmd.colorscheme(mapping.colorscheme)
		break
	end
end
