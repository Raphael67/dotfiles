local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config = {
	automatically_reload_config = true,
	enable_tab_bar = false,
	animation_fps = 60,
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE", -- disable the title but enable the resizable border
	default_cursor_style = "BlinkingBar",
	color_scheme = "Catppuccin Macchiato",
	font = wezterm.font("JetBrains Mono"),
	macos_window_background_blur = 30,
	window_background_opacity = 1.0,
	font_size = 13,
	underline_thickness = 3,
	underline_position = -4,
	window_padding = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	},
}

return config
