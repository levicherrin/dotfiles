local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Theming and Typography
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({
  "Hack Nerd Font",
  "Cascadia Code",
  "Consolas",
})
config.font_size = 15.0


-- Window Styling and Ergonomics
config.window_background_opacity = 1.0
-- Temporarily commented out to keep a draggable titlebar and window controls:
-- config.use_fancy_tab_bar = false
-- config.hide_tab_bar_if_only_one_tab = true
-- config.window_decorations = "RESIZE"

-- Cross-Platform Blur and WSL2 Launch Configuration
if wezterm.target_triple:find("darwin") then
  config.macos_window_background_blur = 50
elseif wezterm.target_triple:find("windows") then
  config.default_domain = "WSL:Debian"
  config.default_cwd = "~"
end

-- Dynamic Unfocused Window Dimming (temporarily commented out for pure contrast testing)
-- local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
-- local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

return config

