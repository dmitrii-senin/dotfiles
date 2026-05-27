return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
  opts = {
    focus = true,
  },
  cmd = "Trouble",
  keys = {
    { "<leader>dd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
    { "<leader>dw", "<cmd>Trouble diagnostics toggle<CR>", desc = "Workspace diagnostics" },
    { "<leader>df", vim.diagnostic.open_float, desc = "Diagnostic float" },
    { "<leader>dt", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, desc = "Toggle diagnostics" },
    { "<leader>lq", "<cmd>Trouble quickfix toggle<CR>", desc = "Quickfix list" },
    { "<leader>ll", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
    { "<leader>lt", "<cmd>Trouble todo toggle<CR>", desc = "Todos" },
  },
}
