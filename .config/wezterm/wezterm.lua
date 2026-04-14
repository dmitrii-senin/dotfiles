local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Color scheme
config.color_scheme = "Catppuccin Macchiato"

-- Font
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 15

-- Background image (subtly visible behind text, aspect-ratio preserved)
config.background = {
  {
    source = { File = wezterm.home_dir .. "/Pictures/phoenix.jpeg" },
    hsb = {
      brightness = 0.01,
      hue = 1.0,
      saturation = 1.0,
    },
    width = "Cover",
    height = "Cover",
    horizontal_align = "Center",
    vertical_align = "Middle",
  },
}

-- Window
config.window_decorations = "RESIZE"
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- No tab bar (using tmux)
config.enable_tab_bar = false

-- macOS: Option as Meta for zsh vi-mode and tmux Alt bindings
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- Terminal
config.term = "xterm-256color"

-- Open URL on Cmd-click
local act = wezterm.action
config.bypass_mouse_reporting_modifiers = 'SUPER'
config.mouse_bindings = {
  -- Cmd-click opens hyperlink; if no link, completes selection
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = act.CompleteSelectionOrOpenLinkAtMouseCursor 'ClipboardAndPrimarySelection',
  },
}

return config
