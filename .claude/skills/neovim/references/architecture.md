# Reference: Baseline Plugin Architecture (Neovim 0.12-tuned)

A principle-first view of what categories belong in a serious IDE-grade Neovim setup, with a default + alternative + tier per category. The user's existing implementation is named in the rightmost column.

## Principles

1. **Pick the category deliberately. The brand is replaceable.**
2. **Prefer 0.12 builtins** when they cover 80% of a plugin's value. Examples: `vim.lsp.completion.enable`, `vim.snippet`, `vim.lsp.foldexpr`, `vim.diagnostic.jump`, `vim.pack` (alt to lazy.nvim).
3. **Every plugin needs a problem statement.** If you can't say what breaks without it, drop it.
4. **Cap on essentials.** A productive setup runs on ~8 essential plugins. The rest are opt-in.

## Categories

| Category               | Why                                                                 | Default                                          | Alternative / Notes                          | Tier      | User has it?                          |
| ---------------------- | ------------------------------------------------------------------- | ------------------------------------------------ | -------------------------------------------- | --------- | ------------------------------------- |
| **Plugin manager**     | Declarative, lazy-loaded plugin lifecycle.                          | `lazy.nvim`                                      | `vim.pack` (0.12 builtin); `mini.deps`       | Essential | ✅ lazy.nvim (with rocks)             |
| **LSP setup**          | Wire language servers via the modern declarative API.               | `vim.lsp.config()` + `vim.lsp.enable()` (built-in) | `nvim-lspconfig` is now optional convenience | Essential | ✅ uses `vim.lsp.config/.enable`      |
| **LSP installer**      | Reproducible install of servers across machines.                    | `mason.nvim`                                     | system-installed servers                     | Essential | ✅ mason.nvim                          |
| **Completion**         | In-buffer LSP/snippet/path/buffer suggestions.                      | **`vim.lsp.completion.enable()` (built-in)**     | `blink.cmp` (modern, fast); `nvim-cmp` (legacy) | Essential | ✅ native completion                  |
| **Snippets**           | Expand boilerplate.                                                 | `vim.snippet` (built-in)                         | `LuaSnip` (only if you outgrow built-in)     | Optional  | ⚠️ no snippet engine wired             |
| **Treesitter**         | Real syntax tree → highlight, indent, text objects, motions.        | `nvim-treesitter` (new install API) + `nvim-treesitter-textobjects` | — | Essential | ✅ both, with new install API         |
| **Format**             | Single command to format any filetype.                              | `conform.nvim`                                   | `none-ls.nvim`                               | Essential | ✅ conform (format-on-save 1000ms)    |
| **Lint**               | Async lint runners feeding `vim.diagnostic`.                        | `nvim-lint`                                      | LSP-only (skip if your LSP covers it)        | Optional  | ✅ nvim-lint                           |
| **Debugger**           | Step-through debugging in the editor.                               | `nvim-dap` + `nvim-dap-ui` + `nvim-dap-virtual-text` | terminal `gdb` / `pdb` / `rust-lldb`     | Optional → Advanced | ✅ dap + dap-ui + dap-python; codelldb |
| **Fuzzy finder**       | Files, grep, buffers, symbols, references.                          | `telescope.nvim`                                 | `fzf-lua` (faster on huge repos); `mini.pick` | Essential | ✅ telescope                           |
| **File explorer**      | Project tree or buffer-as-directory editing.                        | `oil.nvim` (edit dirs as buffers — Vim-native)   | `neo-tree.nvim` (classic sidebar)            | Essential | ⚠️ both oil and neo-tree (can drop one) |
| **Git signs / hunks**  | Inline diff markers, stage hunks.                                   | `gitsigns.nvim`                                  | —                                            | Essential | ✅ gitsigns                            |
| **Git porcelain**      | Status, blame, log, rebase.                                         | `lazygit` in `:term` (the user has it integrated) | `vim-fugitive`; `neogit`                  | Optional  | ✅ lazygit                             |
| **Diff viewer**        | Three-way conflict resolution, branch diffs.                        | `diffview.nvim`                                  | `git difftool`                               | Optional  | — (not installed)                     |
| **Task runner / build** | Build/run/test from editor with structured output.                  | `overseer.nvim`                                  | plain `:term` + `:make`                      | Optional  | — (uses `<Leader>xf` to compile inline) |
| **Test runner**        | Discover/run/jump to failing tests.                                 | `neotest` + adapters                             | terminal `pytest` / `cargo test`             | Optional  | — (not installed)                     |
| **Terminal**           | Fast in-editor shell.                                               | built-in `:term` (small wrapper map)             | `toggleterm.nvim`                            | Essential | ✅ toggleterm                          |
| **Diagnostics UI**     | Quickfix-style panel for LSP diagnostics + refs.                    | `trouble.nvim`                                   | built-in `vim.diagnostic.setqflist()`        | Optional  | ✅ trouble                             |
| **Treesitter context** | Sticky function header at top of window.                            | `nvim-treesitter-context`                        | —                                            | Optional  | — (not installed)                     |
| **Which-key**          | Discoverable keymaps for new users; mute once internalized.         | `which-key.nvim`                                 | just memorize                                | Optional  | ✅ which-key                           |
| **Statusline**         | Aesthetics; built-in is fine.                                       | built-in `statusline`                            | `lualine.nvim`                               | Optional  | — (uses defaults + `laststatus=3`)    |
| **Multiplexer-aware navigation** | Move seamlessly between vim windows and terminal panes.   | none — built-in `<C-w>hjkl` for windows           | `zellij-nav` / `vim-tmux-navigator`          | Optional  | ✅ zellij-nav (zellij user)            |

## What changes vs Neovim 0.10

The 0.12 builtins absorb more value than they used to. Specifically:

- **Completion:** The native `vim.lsp.completion.enable()` plus `vim.snippet` together cover what most users need from nvim-cmp. blink.cmp is justified only for: docs popup tuning, fuzzy matching, multi-source merging. The user is already on the native path — don't push them off it.
- **LSP setup:** `vim.lsp.config()` + `vim.lsp.enable()` make `nvim-lspconfig` a convenience layer for default server configs, not a requirement. The user keeps `nvim-lspconfig` for the defaults but configures via the new API.
- **Folding:** `vim.lsp.foldexpr` is a one-liner per LspAttach — no plugin needed. The user's config does NOT yet wire this; it's the highest-leverage `audit` upgrade.
- **Plugin management:** `vim.pack.add` is the 0.12 built-in. Not yet a lazy.nvim replacement (no event-based loading, no UI polish), but worth knowing as the future direction.

## When to swap a plugin

Three rules:

1. **Pain you've felt.** The current plugin annoys you in a specific, namable way. "Newer is better" is not a reason.
2. **The replacement covers your essential workflow.** Don't trade a working setup for a broken one to chase a benchmark.
3. **You can revert in <10 minutes.** Pin lockfiles, keep the old config in git history, don't burn bridges.

## Integration with the user's actual setup

When proposing changes, **always read the user's plugin file first** (e.g. `~/x/dotfiles/.config/nvim/lua/custom/plugins/lspconfig.lua`) and propose a diff against it. Never recommend installing a plugin the snapshot already lists. Never recommend a category swap (e.g. nvim-cmp → blink.cmp) unless you can name the specific pain it solves for *this* user.
