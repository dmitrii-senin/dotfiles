return {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    CustomOilBar = function()
      local path = vim.fn.expand("%")
      path = path:gsub("oil://", "")
      return "  " .. vim.fn.fnamemodify(path, ":.")
    end

    require("oil").setup({
      default_file_explorer = true,
      delete_to_trash = false,
      skip_confirm_for_simple_edits = true,
      columns = { "icon" },
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-k>"] = false,
        ["<C-j>"] = false,
        ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["<CR>"] = "actions.select",
      },
      win_options = {
        wrap = true,
        winbar = "%{v:lua.CustomOilBar()}",
      },
      view_options = {
        show_hidden = true,
        natural_order = "fast",
        is_always_hidden = function(name, _)
          local folder_skip = { "..", ".", ".git" }
          return vim.tbl_contains(folder_skip, name) or name == ".." or name == ".git"
        end,
      },
    })

    vim.keymap.set("n", "<Leader>-", require("oil").toggle_float, { desc = "Open parent directory" })
    vim.keymap.set("n", "<Leader>_", function()
      require("oil").toggle_float(vim.fn.getcwd())
    end, { desc = "Open current working directory" })
  end,
}
