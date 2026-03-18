return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    icons = {
      breadcrumb = " \u{EAB6} ",
      separator = " \u{EA9C} ",
      group = " ",
      mappings = true,
    },
    win = {
      border = "rounded",
      padding = { 1, 2 },
    },
    spec = {
      { "<Leader>b", group = "Buffer", icon = "󰈚" },
      { "<Leader>c", group = "Code", icon = "" },
      { "<Leader>f", group = "File", icon = "" },
      { "<Leader>h", group = "Help", icon = "󰋖" },
      { "<Leader>q", group = "Quit", icon = "󰗼" },
      { "<Leader>t", group = "Toggle", icon = "" },
      { "<Leader>w", group = "Window", icon = "" },
      { "<Leader>l", group = "Lists", icon = "" },
      { "<Leader>x", group = "Execute", icon = "" },
      { "<Leader>g", group = "Git", icon = "" },
      { "<Leader><tab>", group = "Tab", icon = "󰓩" },
    },
  },
}
