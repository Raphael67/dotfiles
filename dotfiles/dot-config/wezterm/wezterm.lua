local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config = {
	automatically_reload_config = true,
	enable_tab_bar = false,
	window_close_confirmation = "NeverPrompt",
	-- window_decorations = ""RESIZE", -- disable the title but enable the resizable border
	default_cursor_style = "BlinkingBar",
	color_scheme = "Catppuccin Mocha",
	font = wezterm.font("JetBrains Mono"),
	font_size = 12.5,
	background = {
		{
			source = {
				File = "/Users/raphael/.config/wezterm/img/dark-desert.jpg",
			},
			hsb = {
				hue = 1.0,
				saturation = 1.02,
				brightness = 0.25,
			},
			width = "100%",
			height = "100%",
		},
		{
			source = {
				Color = "#282c35",
			},
			width = "100%",
			height = "100%",
			opacity = 0.55,
		},
	},
	window_padding = {
		left = 3,
		right = 3,
		top = 0,
		bottom = 0,
	},
}

return config

-- return {
-- 	adjust_window_size_when_changing_font_size = false,
-- 	-- color_scheme = 'termnial.sexy',
-- 	color_scheme = 'Catppuccin Mocha',
-- 	enable_tab_bar = false,
-- 	font_size = 16.0,
-- 	font = wezterm.font('JetBrains Mono'),
-- 	-- macos_window_background_blur = 40,
-- 	macos_window_background_blur = 30,
--     front_end = "WebGpu",

-- 	-- window_background_image = '/Users/raphael/Downloads/3840x1080-Wallpaper-041.jpg',
-- 	-- window_background_image_hsb = {
-- 	-- 	brightness = 0.01,
-- 	-- 	hue = 1.0,
-- 	-- 	saturation = 0.5,
-- 	-- },
-- 	-- window_background_opacity = 0.92,
-- 	window_background_opacity = 1.0,
-- 	-- window_background_opacity = 0.78,
-- 	-- window_background_opacity = 0.20,
-- 	window_decorations = 'RESIZE',
-- 	keys = {
-- 		{
-- 			key = 'q',
-- 			mods = 'CTRL',
-- 			action = wezterm.action.ToggleFullScreen,
-- 		},
-- 		{
-- 			key = '\'',
-- 			mods = 'CTRL',
-- 			action = wezterm.action.ClearScrollback 'ScrollbackAndViewport',
-- 		},
-- 	},
-- 	mouse_bindings = {
-- 	  -- Ctrl-click will open the link under the mouse cursor
-- 	  {
-- 	    event = { Up = { streak = 1, button = 'Left' } },
-- 	    mods = 'CTRL',
-- 	    action = wezterm.action.OpenLinkAtMouseCursor,
-- 	  },
-- 	},
-- }
