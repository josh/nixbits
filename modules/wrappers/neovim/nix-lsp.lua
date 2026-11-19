vim.lsp.config("nil_ls", {
	cmd = { "nil" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	settings = {
		["nil"] = {
			nix = { flake = { autoArchive = false } },
			formatting = { command = { "nixfmt" } },
		},
	},
})
vim.lsp.enable("nil_ls")
