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
    "folke/which-key.nvim",
    opts_extend = { "spec" },
    opts = {
      spec = {
        { "<BS>", desc = "Decrement Selection", mode = "x" },
        { "<Leader>ss", desc = "Increment Selection", mode = { "x", "n" } },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "windwp/nvim-ts-autotag",
    },
    main = "nvim-treesitter.configs",
    keys = {
      { "<Leader>ss", desc = "Increment Selection" },
      { "<BS>", desc = "Decrement Selection", mode = "x" },
    },
    opts_extend = { "ensure_installed" },
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = parsers,
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<Leader>ss",
          node_incremental = "<Leader>ss",
          scope_incremental = false,
          node_decremental = "<BS>",
        },
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj
        keymaps = {
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ["<leader>a"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>A"] = "@parameter.inner",
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
    enabled = true,
    config = function()
      -- If treesitter is already loaded, we need to run config again for textobjects
      local utils = require("custom.utils")
      if utils.is_loaded("nvim-treesitter") then
        local opts = utils.opts("nvim-treesitter")
        require("nvim-treesitter.configs").setup({ textobjects = opts.textobjects })
      end
    end,
  },
}
