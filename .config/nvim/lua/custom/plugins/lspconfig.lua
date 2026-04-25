return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
  },
  config = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Override built-in LSP mappings with Telescope pickers
        map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        map("gO", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
        map("<Leader>ft", require("telescope.builtin").lsp_type_definitions, "[F]ind [T]ype Definition")
        map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace Symbols")

        -- Native completion
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client then
          vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
        end

        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup("custom-lsp-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("custom-lsp-detach", { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = "custom-lsp-highlight", buffer = event2.buf })
            end,
          })
        end

        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map("<Leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
          end, "[T]oggle Inlay [H]ints")
        end

        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange) then
          local win = vim.api.nvim_get_current_win()
          vim.wo[win][0].foldmethod = "expr"
          vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
        end
      end,
    })

    if vim.g.have_nerd_font then
      local signs = {
        ERROR = "\u{EA87}",
        WARN = "\u{EA6C}",
        INFO = "\u{EA74}",
        HINT = "\u{EA61}",
      }
      local diagnostic_signs = {}
      for type, icon in pairs(signs) do
        diagnostic_signs[vim.diagnostic.severity[type]] = icon
      end
      vim.diagnostic.config({ signs = { text = diagnostic_signs } })
    end

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    })

    vim.lsp.config("clangd", {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=Google",
      },
    })

    vim.lsp.config("rust_analyzer", {
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = { command = "clippy" },
          cargo = { allFeatures = true },
          procMacro = { enable = true },
        },
      },
    })

    vim.lsp.config("pyright", {})

    vim.lsp.enable({ "lua_ls", "clangd", "rust_analyzer", "pyright" })
  end,
}
