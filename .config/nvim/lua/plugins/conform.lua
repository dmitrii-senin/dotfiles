return {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    lazy = true,
    cmd = "ConformInfo",
    keys = {
        {
            "<leader>cF",
            function()
                require("conform").format({ formatters = { "injected" } })
            end,
            mode = { "n", "v" },
            desc = "Format Injected Langs",
        },
    },
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            sh = { "shfmt" },
            python = { "isort", "black" },
            cpp = { "google_clang_format" },
            rust = { "rustfmt", lsp_format = "fallback" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            ["*"] = { "codespell" },
            ["_"] = { "trim_whitespace" },
        },
        format_on_save = {
            lsp_fallback = true,
            timeout_ms = 500,
        },
        format_after_save = {
            lsp_fallback = true,
        },
        log_level = vim.log.levels.ERROR,
        notify_on_error = true,
        formatters = {
            google_clang_format = {
                command = "clang-format",
                args = { "-style=Google" },
            },
        },
    },
}
