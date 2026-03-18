return {
  "akinsho/toggleterm.nvim",
  lazy = false,
  version = "*",
  opts = {
    open_mapping = "<Leader>tt",
    insert_mapping = false,
    direction = "float",
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)
    vim.keymap.set("t", "<Esc><Esc>", "<Cmd>ToggleTerm<CR>", { desc = "Hide terminal" })
  end,
}
