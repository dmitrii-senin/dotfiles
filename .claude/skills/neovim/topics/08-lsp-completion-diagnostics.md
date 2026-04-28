---
session: 08
title: LSP, Completion, Diagnostics
phase: C
prerequisites: [6, 7]
duration: 60 min
---

# Session 08 — LSP, Completion, Diagnostics

## 1. Objective

Master the **modern Neovim 0.11+ LSP API** (`vim.lsp.config()` + `vim.lsp.enable()`), the **built-in native completion** (`vim.lsp.completion.enable()`), and the **0.11+ default LSP keymaps**. Understand `vim.diagnostic.jump`, `vim.lsp.inlay_hint`, and the `LspAttach` autocmd pattern. After this session, you can configure any LSP server in your config with confidence and never reach for the legacy `lspconfig.X.setup{}` pattern.

## 2. Why it matters

LSP is *the* IDE feature. It powers go-to-definition (`gd`), references (`grr`), rename (`grn`), code actions (`gra`), hover (`K`), diagnostics, and (with `vim.lsp.completion.enable`) completion itself. Your three languages all have first-class LSPs:
- **C++** — clangd (heavy on `compile_commands.json`).
- **Python** — pyright / basedpyright (and ruff as a second LSP for diagnostics).
- **Rust** — rust-analyzer (rich code actions, runnables).

## 3. Core concepts

### Modern LSP API (0.11+)

The new declarative pattern:

```lua
vim.lsp.config('clangd', {
  cmd = { 'clangd', '--background-index' },
  settings = { ... },
})

vim.lsp.enable({ 'clangd', 'lua_ls', 'rust_analyzer', 'pyright' })
```

`vim.lsp.config(name, opts)` registers a server config. `vim.lsp.enable({...})` activates them. The pair replaces the old `require('lspconfig').X.setup{}` flow. **You still install `nvim-lspconfig`** because it ships sensible defaults (root_dir patterns, default cmds) that `vim.lsp.config` extends.

### `LspAttach` autocmd

Per-buffer behavior (keymaps, completion, document highlight, inlay hints) lives in an `LspAttach` autocmd. This is the canonical pattern. Your `lspconfig.lua:7-58` is a textbook example.

```lua
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    -- per-buffer keymaps, behavior toggles, capability checks
  end,
})
```

### Default LSP keymaps (0.11+)

Neovim 0.11 added these built-in defaults (no plugin, no config):

| Keys      | Action                  | Capability                              |
| --------- | ----------------------- | --------------------------------------- |
| `K`       | Hover                   | `textDocument/hover`                    |
| `gd`      | Goto definition         | `textDocument/definition`               |
| `gD`      | Goto declaration        | `textDocument/declaration`              |
| `grr`     | List references         | `textDocument/references`               |
| `gri`     | List implementations    | `textDocument/implementation`           |
| `gra`     | Code action             | `textDocument/codeAction`               |
| `grn`     | Rename                  | `textDocument/rename`                   |
| `gO`      | Document symbols        | `textDocument/documentSymbol`           |
| `<C-s>` (insert) | Signature help   | `textDocument/signatureHelp`            |
| `]d` / `[d` | Next/prev diagnostic  | `vim.diagnostic`                        |

Your config **overrides** `gd`, `grr`, `gri`, `gO`, and adds `gW`, `<Leader>ft` to use **telescope pickers** for richer UX. See `lspconfig.lua:17-22`.

### Native completion (`vim.lsp.completion.enable`)

```lua
vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
```

This activates the built-in completion menu (uses `ins-completion` under the hood) sourced from the LSP. With `autotrigger = true`, the menu appears as you type. Without, you trigger it with `<C-x><C-o>` (omnifunc).

What it covers:
- LSP completion items (functions, types, variables).
- Snippet expansion (when paired with `vim.snippet`).
- Item kind icons (when `vim.g.have_nerd_font` is set).

What it doesn't cover (yet):
- Multi-source merging (LSP + buffer + path + spell). For that → blink.cmp.
- Fuzzy matching. For that → blink.cmp.
- Inline docs popup tuning. For that → blink.cmp.

Your config uses native (`lspconfig.lua:25-28`). Stay there unless you have a *named* complaint.

### `vim.diagnostic`

The diagnostic API is shared across all sources (LSP, linters, treesitter). Your config:
- Custom severity icons via `vim.diagnostic.config({ signs = { text = ... } })` (lines 61-73).
- Custom severity-aware navigation: `]e/[e` for errors, `]w/[w` for warnings (`keymaps.lua:52-62`) using **`vim.diagnostic.jump({ count = ±1, severity = ... })`** — the modern API (NOT `goto_next/goto_prev`).
- `<Leader>cd` opens a floating window for the current line's diagnostics.

### Inlay hints

```lua
vim.lsp.inlay_hint.enable(true)         -- enable globally (or pass bufnr)
vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })   -- check
```

Your config gates inlay hints behind `<Leader>th` toggle (`lspconfig.lua:53-57`). Useful per-language (Rust shines here).

### LSP-driven folding (`vim.lsp.foldexpr`)

Available in 0.11+. Not yet wired in your config. Setup:

```lua
if client and client:supports_method('textDocument/foldingRange') then
  vim.wo[0][0].foldmethod = 'expr'
  vim.wo[0][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
end
```

This is the **highest-leverage audit upgrade** for your config. Currently you fold via treesitter (`v:lua.vim.treesitter.foldexpr()` in `treesitter.lua`); LSP folds are more semantic (track impl blocks, class members, etc.).

### Mason

`mason.nvim` installs language servers, formatters, debuggers, and linters into `~/.local/share/nvim/mason/`. Your config is minimal (`mason.lua` opens UI on `<Leader>M`; install on demand).

For a more declarative approach, `mason-tool-installer.nvim` (currently commented out in your `mason.lua`) lets you list required tools in the config. Optional.

## 4. Config notes — annotated tour of `lspconfig.lua`

Your file (let's walk it):

- **Lines 7-13** — `LspAttach` autocmd, augroup-grouped (correct pattern; clears on re-source).
- **Lines 17-22** — Telescope overrides for default LSP keymaps. `gd → telescope.lsp_definitions`, etc. **Why telescope?** When a symbol has multiple definitions (e.g. virtual functions), telescope shows all of them in a fuzzy list. Pure `vim.lsp.buf.definition` opens the first match.
- **Line 27** — `vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })`. **Native completion**. This is the modern path. No nvim-cmp.
- **Lines 30-51** — `textDocument/documentHighlight` capability check + `CursorHold`/`CursorHoldI` autocmd to highlight references under the cursor. The `LspDetach` cleanup is correct.
- **Lines 53-57** — Inlay-hint toggle map (`<Leader>th`).
- **Lines 61-73** — Diagnostic icon configuration (nerd-font icons, severity-keyed).
- **Lines 75-84** — `vim.lsp.config('lua_ls', { ... })` — Lua language server. `runtime.version = LuaJIT` (Neovim's Lua), `globals = { 'vim' }` (so `vim.api...` doesn't lint as undefined), `workspace.library = vim.api.nvim_get_runtime_file('', true)` (so `require('vim.api')` resolves), `checkThirdParty = false` (don't prompt about external libs).
- **Lines 86-96** — `vim.lsp.config('clangd', { cmd = { ... } })`. Flag walk:
  - `--background-index` — index your headers in the background, persists across sessions.
  - `--clang-tidy` — run clang-tidy diagnostics inline.
  - `--header-insertion=iwyu` — include-what-you-use semantics for auto-imports.
  - `--completion-style=detailed` — show full signatures in completion.
  - `--function-arg-placeholders` — completion inserts `(arg, arg)` placeholders.
  - `--fallback-style=Google` — formatting style when no `.clang-format` is present.
- **Lines 98-106** — `vim.lsp.config('rust_analyzer', { ... })`. `checkOnSave = clippy` (run clippy on save instead of cargo check), `cargo.allFeatures = true` (enable all features for indexing), `procMacro.enable = true` (support proc macros — needed for serde, tracing, etc.).
- **Line 108** — `vim.lsp.config('pyright', {})`. Default config. Audit candidate: try basedpyright instead.
- **Line 110** — `vim.lsp.enable({ 'lua_ls', 'clangd', 'rust_analyzer', 'pyright' })`. Activates all four.

## 5. Concrete examples

### Hover, definition, references in a real file

Open `~/x/dotfiles/.config/nvim/lua/custom/plugins/lspconfig.lua`. Cursor on `vim.lsp.config` (line 75).

- `K` — hover. Shows the function signature.
- `gd` — go to definition (telescope picker since you've overridden it).
- `grr` — references (telescope picker).
- `<C-o>` — jump back.

### Code action

In a Rust file with a missing `use`, cursor on the unimported symbol. `gra` opens the action menu. Select "Import …".

### Rename across project

Cursor on a symbol. `grn`, type new name, `<CR>`. LSP rewrites every reference, including in other files.

### Inspect what LSP is doing

```
:LspInfo                      " all attached clients for this buffer
:checkhealth vim.lsp          " full LSP health
:lua = vim.lsp.get_clients()  " programmatic
:lua = vim.lsp.get_log_path() " path to log; tail with :term
```

## 6. Shortcuts to memorize

### ESSENTIAL
`K` hover · `gd` definition · `gD` declaration · `grr` references · `gri` impl · `gra` action · `grn` rename · `gO` doc symbols · `gW` workspace symbols · `<C-s>` (insert) signature
`]d [d` next/prev diagnostic · `]e [e` next/prev error (your config) · `]w [w` next/prev warning (your config)
`<Leader>cd` line diagnostics float · `<Leader>cf` format · `<Leader>th` toggle inlay hints
`<Leader>ft` LSP type definition (telescope)

### OPTIONAL
`<C-x><C-o>` manual omnifunc completion (always works, even without autotrigger)
`vim.lsp.buf.workspace_symbol("query")` — programmatic workspace symbol search
`:LspRestart` — restart all attached clients

### ADVANCED
`vim.lsp.commands` — programmatic command registry
`:lua = vim.lsp.protocol.Methods.textDocument_definition` — typed method constants
`:lua = vim.lsp.semantic_tokens` — semantic token API

## 7. Drills

1. Open `lspconfig.lua`. Cursor on `vim.lsp.config` (line 75). Use `grr` to list references — confirm count = 4 (lua_ls, clangd, rust_analyzer, pyright).
2. Run `:LspInfo` in any file. Identify your attached clients and `root_dir`s.
3. In a C++ file, place cursor on a `std::vector<int>`. Use `K` to hover. Use `gd` on `vector` to follow into the standard library.
4. Press `]e` repeatedly across a file with multiple errors. Use `]w` for warnings only. Use `<Leader>cd` to open the floating diagnostic.
5. Toggle inlay hints with `<Leader>th` in a Rust file. See the difference.

## 8. Troubleshooting

- **"`gd` opens nothing."** Server doesn't support `textDocument/definition` for that token, OR client failed to attach. Check `:LspInfo` and `:checkhealth vim.lsp`.
- **"Completion menu doesn't appear."** Check `vim.lsp.completion.is_enabled(0)`. Confirm the server attached (`:LspInfo`). Try `<C-x><C-o>` manually.
- **"clangd indexes forever."** First-time index of a large project takes minutes. Watch `~/.cache/clangd/index/` grow. After the first pass, it's incremental. If it never stops: confirm `compile_commands.json` is valid (cd to its dir and run `clangd --check=path/to/file.cpp`).
- **"pyright can't find my imports."** Pyright uses the active venv. Activate it BEFORE launching Neovim. Or set `vim.lsp.config('pyright', { settings = { python = { pythonPath = "..." } } })`.
- **"rust-analyzer is slow."** `cargo.allFeatures = true` (your config) increases indexing cost on huge feature sets. Consider `cargo.features = "all"` only when needed; otherwise default.

## 9. Optional config edit

**Wire `vim.lsp.foldexpr` (HIGH-impact audit upgrade):**

```diff
--- a/.config/nvim/lua/custom/plugins/lspconfig.lua
+++ b/.config/nvim/lua/custom/plugins/lspconfig.lua
@@ -57,6 +57,11 @@
         end, "[T]oggle Inlay [H]ints")
       end
+
+      if client and client:supports_method('textDocument/foldingRange') then
+        vim.wo[0][0].foldmethod = 'expr'
+        vim.wo[0][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
+      end
     end,
   })
```

Test live: open a Rust or Python file after applying. Use `zR` to open all folds, `zM` to close all, `zo`/`zc` per fold. Compare to the treesitter-driven folds you had before.

**ASK before writing.**

## 10. Next-step upgrades

- **Add `ruff` as an LSP** (in addition to formatter): `vim.lsp.config('ruff', {})`, then add `'ruff'` to the `enable` list. Diagnostics show up immediately on save without conform's overhead.
- **Try `basedpyright`** in place of `pyright`: install via mason (`:MasonInstall basedpyright`), change `vim.lsp.config('pyright', {})` to `vim.lsp.config('basedpyright', {})`, update `enable` list.
- **Consider splitting `lspconfig.lua`** if it grows past 150 lines: per-server files under `lua/custom/plugins/lsp/{clangd,rust,python,lua}.lua`. Optional taste call.

## 11. Connects to

Next: **Session 9 — Treesitter & Structural Editing**. LSP gives you semantic understanding; treesitter gives you syntactic structure. Together they're the foundation of every IDE motion you'll ever do.
