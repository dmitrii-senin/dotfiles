return {
  "nvim-telescope/telescope.nvim",
  lazy = false,
  cmd = "Telescope",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
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
    map("n", "<Leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
    map("n", "<Leader>fs", builtin.live_grep, { desc = "[F]ind [S]tring" })
    map("n", "<Leader>fb", builtin.buffers, { desc = "[F]ind [B]uffers" })
    map("n", "<Leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp tags" })

    map("n", "<leader>fc", function()
      builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "[F]ind Neovim [C]onfig files" })

    map("n", "<leader>fp", function()
      local plugins = vim.fn.stdpath("data") .. "/lazy"
      builtin.find_files({ cwd = plugins })
    end, { desc = "[F]ind Neovim [P]lugin files" })

    map("n", "<Leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
    map("n", "<Leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
    map("n", "<Leader>fm", builtin.man_pages, { desc = "[F]ind [M]an pages" })
    map("n", "<Leader>f'", builtin.marks, { desc = "[F]ind Marks" })
    map("n", "<Leader>f\"", builtin.registers, { desc = "[F]ind Registers" })
  end,
}
