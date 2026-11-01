local defaults = vim.json.decode(table.concat(vim.fn.readfile("defaults.json"), "\n"))
local cases = {
	{ "tokyonight_day", "tokyonight-day", "light" },
	{ "tokyonight_moon", "tokyonight-moon", "dark" },
	{ "tokyonight_storm", "tokyonight-storm", "dark" },
	{ "tokyonight_night", "tokyonight-night", "dark" },
	{ "tokyonight_bogus", "tokyonight-night", "dark" },
	{ "catppuccin_frappe", "catppuccin-frappe", "dark" },
	{ "catppuccin_latte", "catppuccin-latte", "light" },
	{ "catppuccin_macchiato", "catppuccin-macchiato", "dark" },
	{ "catppuccin_mocha", "catppuccin-mocha", "dark" },
	{ "catppuccin_bogus", "catppuccin-mocha", "dark" },
	{ "rosepine_moon", "rose-pine-moon", "dark" },
	{ "rosepine_dawn", "rose-pine-dawn", "light" },
	{ "rosepine", "rose-pine-main", "dark" },
	{ "rosepine_bogus", "rose-pine-main", "dark" },
	{ "ansi_light", "default", "light" },
	{ "ansi_dark", "default", "dark" },
	{ "ansi_bogus", "default", "dark" },
	{ "", defaults.colorscheme, defaults.background, defaults.termguicolors },
	{ "unknown", defaults.colorscheme, defaults.background, defaults.termguicolors },
}

local check = [[
assert(vim.v.errmsg == "", vim.v.errmsg)
assert(vim.o.ignorecase and vim.o.smartcase)
assert(vim.o.tabstop == 4 and vim.o.shiftwidth == 4 and vim.o.expandtab)
assert(vim.g.local_plugin_loaded == nil)
assert(vim.g.loaded_python3_provider == 0)
assert(vim.g.loaded_node_provider == 0)
assert(vim.g.loaded_ruby_provider == 0)
assert(package.loaded.jj ~= nil)
assert(vim.fn.exists(":J") == 2)
assert(vim.fn.exepath("jj") == vim.env.JJ_BIN)
assert(vim.fn.system({ "jj", "--version" }):match("^jj "))
assert(vim.v.shell_error == 0)
assert(vim.fn.stdpath("state") == vim.env.XDG_STATE_HOME .. "/nvim")
assert(vim.fn.stdpath("cache") == vim.env.XDG_CACHE_HOME .. "/nvim")
if EXPECTED.colorscheme:match("^rose%-pine%-") then
  assert(vim.g.colors_name == "rose-pine", vim.inspect(vim.g.colors_name))
  assert(require("rose-pine.config").options.variant == EXPECTED.colorscheme:sub(11))
else
  assert((vim.g.colors_name or "") == EXPECTED.colorscheme, vim.inspect(vim.g.colors_name))
end
assert(vim.o.background == EXPECTED.background, vim.o.background)
assert(vim.o.termguicolors == EXPECTED.termguicolors)
]]

for _, case in ipairs(cases) do
	local expected = {
		colorscheme = case[2],
		background = case[3],
		termguicolors = case[4],
	}
	if expected.termguicolors == nil then
		expected.termguicolors = case[2] ~= "default"
	end
	local script = vim.fn.tempname() .. ".lua"
	vim.fn.writefile(vim.split("local EXPECTED = " .. vim.inspect(expected) .. "\n" .. check, "\n"), script)
	local command = 'lua local ok, err = pcall(dofile, "'
		.. script
		.. '"); if not ok then print(err); vim.cmd("cquit 1") end'
	local result = vim.system({ vim.fn.exepath("nvim"), "--headless", "-i", "NONE", "-c", command, "-c", "qa!" }, {
		env = { THEME = case[1] },
		text = true,
	}):wait()
	assert(result.code == 0, "THEME=" .. case[1] .. "\n" .. result.stdout .. result.stderr)
	assert(result.stderr == "", "THEME=" .. case[1] .. "\n" .. result.stderr)
	vim.fn.delete(script)
end

-- The parent was launched with THEME unset.
assert((vim.g.colors_name or "") == defaults.colorscheme)
assert(vim.o.background == defaults.background)
assert(vim.o.termguicolors == defaults.termguicolors)
