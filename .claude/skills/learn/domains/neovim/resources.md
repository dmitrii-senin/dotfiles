# Resources: neovim — vetted, citeable sources

Cite these over parametric memory, especially for API names and option behavior (the
0.11→0.12 API churn is exactly where parametric memory misleads). Flag anything
unattributable as `⚠ unsourced`.

## Primary / authoritative
- **`:help`** — the built-in docs are canonical. Cite the exact tag (`:help lsp-config`,
  `:help text-objects`, `:help usr_03.txt`).
- **Neovim 0.12 changelog / release notes** — new builtins, deprecations (the source of
  truth for "what's legacy now").
- **The user's actual config** — `~/x/dotfiles/.config/nvim/` (`init.lua`, `lua/custom/**`).
  Ground every example here with `file:line`.
- **`references/`** — `current-config-snapshot.md`, `customization.md`, `anti-patterns.md`,
  `keymaps.md`, `architecture.md` (used by the `audit` mode).

## Secondary
- **Practical Vim** (Drew Neil) — the definitive operator-motion composition reference (core).
- **Plugin docs** — lazy.nvim, telescope, oil, trouble, gitsigns, nvim-dap, conform, nvim-lint,
  treesitter (cite the plugin's own README/`:help` when recommending config).
- **Language servers** — clangd, pyright/basedpyright, rust-analyzer docs (languages/lsp).

## 0.12+ discipline (never teach the legacy form)
| Use (0.12+) | Not (legacy) |
|---|---|
| `vim.lsp.config(name,opts)` + `vim.lsp.enable({...})` | `require('lspconfig').X.setup{}` |
| `vim.lsp.completion.enable(...)` | nvim-cmp / blink.cmp |
| `vim.diagnostic.jump({count=±1,...})` | `vim.diagnostic.goto_next/goto_prev` |
| `vim.uv` | `vim.loop` |
| `vim.system()` | `vim.fn.system()` (new async) |
| `require('nvim-treesitter').install(...)` | `require('nvim-treesitter.configs').setup{}` |

No distro-first answers (LazyVim/NvChad/AstroNvim/Kickstart). No plugin recommendation
without a named pain + breakage scenario + one alternative.
