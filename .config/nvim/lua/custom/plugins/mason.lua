return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonUpdate", "MasonInstall" },
    keys = { { "<Leader>M", "<Cmd>Mason<CR>", desc = "Run [M]ason" } },
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        -- LSP servers (also wired in lspconfig.lua via vim.lsp.config/.enable)
        "lua-language-server",
        "clangd",
        "rust-analyzer",
        "pyright",
        -- Formatters (used by conform.nvim)
        "stylua",
        "clang-format",
        "prettier",
        "ruff",
        "rustfmt",
        -- Linters (used by nvim-lint)
        "clangtidy",
        -- Debuggers (used by nvim-dap configurations)
        "codelldb",
        "debugpy",
      },
      auto_update = false,
      run_on_start = true,
      start_delay = 3000, -- ms; let LSP/treesitter settle first
    },
  },
}
