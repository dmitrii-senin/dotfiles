return {
  "swaits/zellij-nav.nvim",
  lazy = true,
  event = "VeryLazy",
  keys = {
    { "<c-h>", "<cmd>ZellijNavigateLeftTab<cr>",  silent = true, desc = "Zellij: nav left/tab" },
    { "<c-j>", "<cmd>ZellijNavigateDown<cr>",     silent = true, desc = "Zellij: nav down" },
    { "<c-k>", "<cmd>ZellijNavigateUp<cr>",       silent = true, desc = "Zellij: nav up" },
    { "<c-l>", "<cmd>ZellijNavigateRightTab<cr>", silent = true, desc = "Zellij: nav right/tab" },
  },
  opts = {},
}
