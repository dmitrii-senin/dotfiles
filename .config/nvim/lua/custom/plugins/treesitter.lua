local parsers = {
  "asm",
  "awk",
  "bash",
  "c",
  "cmake",
  "cpp",
  "css",
  "csv",
  "cuda",
  "diff",
  "disassembly",
  "dockerfile",
  "doxygen",
  "go",
  "graphql",
  "html",
  "java",
  "javascript",
  "jq",
  "json",
  "json5",
  "lua",
  "luadoc",
  "make",
  "markdown",
  "markdown_inline",
  "nasm",
  "objdump",
  "python",
  "rust",
  "scala",
  "sql",
  "starlark",
  "strace",
  "swift",
  "thrift",
  "tmux",
  "tsx",
  "typescript",
  "vim",
  "xml",
  "yaml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
      "windwp/nvim-ts-autotag",
    },
    config = function()
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("custom-treesitter-highlight", { clear = true }),
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })

      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      -- Select keymaps
      for _, mode in ipairs({ "x", "o" }) do
        vim.keymap.set(mode, "aa", function()
          select.select_textobject("@parameter.outer", "textobjects")
        end, { desc = "Select outer parameter" })
        vim.keymap.set(mode, "ia", function()
          select.select_textobject("@parameter.inner", "textobjects")
        end, { desc = "Select inner parameter" })
        vim.keymap.set(mode, "af", function()
          select.select_textobject("@function.outer", "textobjects")
        end, { desc = "Select outer function" })
        vim.keymap.set(mode, "if", function()
          select.select_textobject("@function.inner", "textobjects")
        end, { desc = "Select inner function" })
        vim.keymap.set(mode, "ac", function()
          select.select_textobject("@class.outer", "textobjects")
        end, { desc = "Select outer class" })
        vim.keymap.set(mode, "ic", function()
          select.select_textobject("@class.inner", "textobjects")
        end, { desc = "Select inner class" })
      end

      -- Move keymaps
      local modes = { "n", "x", "o" }
      vim.keymap.set(modes, "]m", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function start" })
      vim.keymap.set(modes, "]]", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class start" })
      vim.keymap.set(modes, "]M", function()
        move.goto_next_end("@function.outer", "textobjects")
      end, { desc = "Next function end" })
      vim.keymap.set(modes, "][", function()
        move.goto_next_end("@class.outer", "textobjects")
      end, { desc = "Next class end" })
      vim.keymap.set(modes, "[m", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Prev function start" })
      vim.keymap.set(modes, "[[", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Prev class start" })
      vim.keymap.set(modes, "[M", function()
        move.goto_previous_end("@function.outer", "textobjects")
      end, { desc = "Prev function end" })
      vim.keymap.set(modes, "[]", function()
        move.goto_previous_end("@class.outer", "textobjects")
      end, { desc = "Prev class end" })

      -- Swap keymaps
      vim.keymap.set("n", "<leader>a", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap next parameter" })
      vim.keymap.set("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap previous parameter" })
    end,
  },
}
