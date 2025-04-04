local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

config.set_environment_variables = {
	THEME = "@theme@",
}

if "@colorScheme@" ~= "" then
	config.color_scheme = "@colorScheme@"
end
config.font = wezterm.font({ family = "JetBrains Mono", weight = "Regular" })
config.font_size = 16

config.tab_bar_at_bottom = true

local tabline = wezterm.plugin.require("file://@tabline@")
tabline.setup({
	options = {
		theme = config.color_scheme,
	},
	sections = {
		tabline_y = { "datetime" },
	},
})
tabline.apply_to_config(config)

config.initial_cols = 120
config.initial_rows = 35
local initial_width = 2300
local initial_height = 1568

config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}

wezterm.on("gui-startup", function(cmd)
	local screen = wezterm.gui.screens().active
	local x = (screen.width - initial_width) * 0.5
	local y = (screen.height - initial_height) * 0.5

	local tab, pane, window = mux.spawn_window(cmd or {
		position = { x = x, y = y },
	})

	local dimensions = window:gui_window():get_dimensions()
	if dimensions.pixel_height ~= initial_height then
		wezterm.log_warn("Initial height mismatch: " .. dimensions.pixel_height)
	end
	if dimensions.pixel_width ~= initial_width then
		wezterm.log_warn("Initial width mismatch: " .. dimensions.pixel_width)
	end

	x = (screen.width - dimensions.pixel_width) * 0.5
	y = (screen.height - dimensions.pixel_height) * 0.5
	window:gui_window():set_position(x, y)
end)

config.keys = {
	{
		key = ",",
		mods = "CMD",
		action = act.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { "nvim", wezterm.config_file },
		}),
	},
	{
		key = "k",
		mods = "CMD",
		action = act.Multiple({
			act.ClearScrollback("ScrollbackAndViewport"),
			act.SendKey({ key = "L", mods = "CTRL" }),
		}),
	},
}

return config
