# LSP keymaps, diagnostics, completion

## LSP keymaps (0.11+ defaults + your overrides)

Your config overrides several defaults with Telescope pickers (marked with `*`).

| Key | Action | Source |
|-----|--------|--------|
| `K` | hover documentation | default |
| `gd` | go to definition `*` | telescope `lsp_definitions` |
| `gD` | go to declaration | `vim.lsp.buf.declaration` |
| `grr` | go to references `*` | telescope `lsp_references` |
| `gri` | go to implementations `*` | telescope `lsp_implementations` |
| `gO` | document symbols `*` | telescope `lsp_document_symbols` |
| `gW` | workspace symbols `*` | telescope `lsp_dynamic_workspace_symbols` |
| `grn` | rename symbol | default |
| `gra` | code action | default |
| `<Leader>ca` | code action | `vim.lsp.buf.code_action` |
| `<Leader>ft` | type definition | telescope `lsp_type_definitions` |
| `<Leader>th` | toggle inlay hints | `vim.lsp.inlay_hint.enable` |

`gd` with telescope gives a multi-result picker; `C-s` to open in split, `C-v` for vsplit.

## Diagnostics

### Navigation

| Key | Action |
|-----|--------|
| `]e` / `[e` | next / prev error |
| `]w` / `[w` | next / prev warning |
| `]d` / `[d` | next / prev diagnostic (any severity, default) |

All use `vim.diagnostic.jump({ count = ..., severity = ... })`.

### Trouble.nvim diagnostics

| Key | Action |
|-----|--------|
| `<Leader>dd` | buffer diagnostics (Trouble) |
| `<Leader>dw` | workspace diagnostics (Trouble) |
| `<Leader>df` | diagnostic float (`vim.diagnostic.open_float`) |
| `<Leader>dt` | toggle diagnostics on/off |
| `<Leader>lt` | toggle TODO comments (Trouble) |

### Diagnostic config (your setup)

```lua
-- virtual_text = false, virtual_lines = { current_line = true }
-- Signs: ERROR=, WARN=, INFO=, HINT=
```

## Completion (native vim.lsp.completion)

Your config: `autotrigger = true`, `completeopt = "menuone,noinsert,popup"`.

| Key | Action |
|-----|--------|
| `C-n` | trigger/open completion menu (mapped to `C-x C-o`) |
| `C-n` / `C-p` | navigate down / up in popup |
| `Tab` | confirm selected item (your mapping: pumvisible -> `C-y`) |
| `C-y` | accept completion (default) |
| `C-e` | cancel / close popup |
| `C-l` / `C-h` | snippet jump forward / backward (insert/select mode) |

Completion triggers automatically on `.`, `::`, `->` etc. via autotrigger.

## Formatting

| Key | Action |
|-----|--------|
| `<Leader>cf` | format file (normal) or range (visual) |
| (auto) | format on save via conform.nvim |

Formatters: C/C++ = clang-format (Google style), Lua = stylua, Python = ruff, Rust = rustfmt, JS/TS/JSON/YAML = prettier.

## Treesitter text objects

### Selection (visual/operator-pending)

| Object | Inner | Outer |
|--------|-------|-------|
| function | `if` | `af` |
| class | `ic` | `ac` |
| parameter | `ia` | `aa` |

### Navigation (normal/visual/operator-pending)

| Key | Action |
|-----|--------|
| `]m` / `[m` | next / prev function start |
| `]M` / `[M` | next / prev function end |
| `]]` / `[[` | next / prev class start |
| `][` / `[]` | next / prev class end |

### Swap

| Key | Action |
|-----|--------|
| `<Leader>a` | swap parameter with next |
| `<Leader>A` | swap parameter with previous |

## Folding

LSP foldexpr takes priority when LSP attaches (your config sets `foldmethod=expr`, `foldexpr=vim.lsp.foldexpr()`). Fallback: treesitter foldexpr.

| Key | Action |
|-----|--------|
| `za` | toggle fold |
| `zo` / `zc` | open / close fold |
| `zR` / `zM` | open / close all folds |
| `zr` / `zm` | reduce / more fold level |
| `[z` / `]z` | start / end of current fold |
| `zj` / `zk` | next / prev fold |

`foldlevel = 99` -- files open fully unfolded.

## Document highlights

Cursor hold highlights all references to symbol under cursor (via `textDocument/documentHighlight`). Clears on cursor move. Configured in your LspAttach autocmd.
