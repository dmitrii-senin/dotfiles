return {
  -- {
  --   "WhoIsSethDaniel/mason-tool-installer.nvim",
  --   dependencies = {
  --     "jay-babu/mason-null-ls.nvim",
  --   },
  -- },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonUpdate", "MasonInstall" },
    keys = { { "<Leader>M", "<Cmd>Mason<CR>", desc = "Run [M]ason" } },
  },
}
