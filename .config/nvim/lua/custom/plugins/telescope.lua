return {
  "nvim-telescope/telescope.nvim",
  lazy = false,
  cmd = "Telescope",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
    "BurntSushi/ripgrep",
    "sharkdp/fd",
  },
  config = function()
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        path_display = { "smart" },
      },
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        },
      },
    })

    telescope.load_extension("fzf")

    -- set keymaps
    local map = vim.keymap.set -- for conciseness
    local builtin = require("telescope.builtin")
    map("n", "<Leader>ff", builtin.find_files, { desc = "Telescope find files" })
    map("n", "<Leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
    map("n", "<Leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    map("n", "<Leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

    map("n", "<leader>fc", function()
      builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "[F]ind Neovim [C]onfig files" })

    map("n", "<leader>fp", function()
      local plugins = vim.fn.stdpath("data") .. "/lazy"
      builtin.find_files({ cwd = plugins })
    end, { desc = "[F]ind Neovim [C]onfig files" })
  end,
}
