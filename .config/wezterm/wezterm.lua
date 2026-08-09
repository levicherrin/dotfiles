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
config.use_fancy_tab_bar = false
config.window_background_opacity = 0.8
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"


-- Cross-Platform Blur and WSL2 Launch Configuration
if wezterm.target_triple:find("darwin") then
  config.macos_window_background_blur = 50
elseif wezterm.target_triple:find("windows") then
  config.win32_system_backdrop = "Acrylic"
  config.default_domain = "WSL:Debian"
  config.default_cwd = "~"
end

-- Dynamic Unfocused Window Dimming
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

local function same_text_hsb(actual, expected)
  if actual == nil or expected == nil then
    return actual == expected
  end
  return actual.hue == expected.hue
    and actual.saturation == expected.saturation
    and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
  local overrides = window:get_config_overrides() or {}
  local text_hsb, opacity
  if not window:is_focused() then
    text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
    opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
  end

  if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
    return
  end

  overrides.foreground_text_hsb = text_hsb
  overrides.window_background_opacity = opacity
  window:set_config_overrides(overrides)
end)

return config
