---
session: 17
title: ":help discipline & the Neovim API surface"
phase: F
prerequisites: [01, 06, 08]
duration: 45 min
---

# Session 17 — `:help` Discipline & the Neovim API Surface

## 1. Objective

Stop guessing. By the end of this session you can navigate `:help` with the same fluency as your code, locate any function in `vim.api` / `vim.lsp` / `vim.diagnostic` / `vim.treesitter` from a cold start, and read source for any builtin in under 30 seconds.

## 2. Why it matters

Half of "advanced Vim" is just being able to look something up. The user has a config full of `vim.lsp.completion.enable(...)` and `vim.diagnostic.jump(...)` calls — every one of those has a `:help <name>()` entry that tells you exactly what arguments are valid and what it returns. Once `:help` is reflex, you stop relying on Reddit threads from 2019 to tell you the API. You also stop fearing 0.13/0.14 changes — `:help news` is the canonical changelog.

## 3. Core concepts

**The four discovery surfaces.**

| Surface          | What it answers                                   | How to enter                              |
| ---------------- | ------------------------------------------------- | ----------------------------------------- |
| `:help <topic>`  | "How does X work? What flags?"                    | tag completion via `<Tab>`                |
| `:helpgrep`      | "Where is X mentioned?"                           | populates quickfix                        |
| `:lua = <expr>`  | "What's the actual value? What methods exist?"   | live introspection                        |
| `:scriptnames`   | "What sourced files are loaded right now?"        | exposes runtimepath layering              |

**Tag jumping inside help:**
- `<C-]>` follows tag under cursor.
- `<C-t>` pops back.
- `<C-o>`/`<C-i>` work too — help respects the jumplist.
- `:tag <pattern>` jumps to any tag (with `<Tab>`).
- `:helptags <dir>` rebuilds tags for a runtimepath dir (you'll do this for your own plugin in Session 19).

**API namespaces (the ones that matter):**
- `vim.api.*` — the C API exposed to Lua. Stable. Anything starting with `nvim_` is here.
- `vim.fn.*` — call any Vimscript function (`vim.fn.expand("%")`, `vim.fn.systemlist(...)`).
- `vim.lsp.*` — LSP client API (the 0.11+ refactor; what your config already uses).
- `vim.diagnostic.*` — diagnostic UI + jumping + filtering.
- `vim.treesitter.*` — parser + query API; `vim.treesitter.foldexpr` lives here.
- `vim.uv` — libuv async (the 0.10+ rename of `vim.loop`). Timers, file IO, processes.
- `vim.system()` — modern process spawn (replaces `vim.fn.system` for new code).
- `vim.snippet.*` — built-in snippet engine; what your `<C-l>`/`<C-h>` keymaps drive after Session 8's bundle.
- `vim.hl.*` — `vim.hl.on_yank()` is the 0.11+ replacement for the old `vim.highlight.on_yank()`.

**The two best `:help` files to bookmark:**
- `:help news` — the changelog, organized by version. Read on every Neovim update.
- `:help lua-guide` — the canonical Lua-in-Neovim primer. Skim once a year.

## 4. Config notes

- Your `lspconfig.lua:75-110` defines an `LspAttach` callback that uses raw method strings and `vim.lsp.completion.enable`. Anything mysterious in those calls has a `:help` entry — try `:help vim.lsp.completion.enable()`.
- `keymaps.lua` calls `vim.keymap.set` everywhere; `:help vim.keymap.set()` documents every option (`silent`, `expr`, `buffer`, `nowait`, `desc`, `remap`).
- `treesitter.lua` calls `require('nvim-treesitter').install(...)`; that's the *plugin's* function, not Neovim core. To find its docs: `:help nvim-treesitter` then `<C-]>` on `install`.
- Built-in vs plugin: if a help tag starts with `nvim_*` or `vim.*`, it's core. Anything else is a plugin (look in `~/.local/share/nvim/lazy/<plugin>/doc/`).

## 5. Concrete examples

In a running Neovim:

1. Discover what `vim.lsp` actually exports:
   ```vim
   :lua = vim.lsp
   ```
   You'll see a Lua table dumped with every function key. `=` is shorthand for `print(vim.inspect(...))`.

2. Find the source for a builtin:
   ```vim
   :lua = require'vim.lsp.completion'
   :lua = debug.getinfo(vim.lsp.completion.enable).source
   ```
   The second prints something like `@/usr/local/share/nvim/runtime/lua/vim/lsp/completion.lua`. `:e <that path>` opens it.

3. From a hover doc on a builtin function (`K` on `vim.system`), follow `<C-]>` to drill into related tags, `<C-t>` to climb back.

4. `:helpgrep autocmd .* BufWritePre` — search every help file for a pattern. Quickfix opens with hits; `:cn`/`:cp` to jump.

5. `:scriptnames` — print every Lua/Vim script Neovim has sourced this session, in order. Useful when a plugin "doesn't work" — confirm it actually loaded.

6. `:checkhealth` (no args) — run every `health` provider Neovim knows about. Then `:checkhealth nvim` for core, `:checkhealth lsp` for LSP, etc. (Session 16 / Bucket 4 wires `:checkhealth custom` for your own toolchain.)

7. `:messages` — every message Neovim has printed (errors, deprecations, your own `print` calls). When something silently fails, this is the first stop.

## 6. Shortcuts to memorize

### ESSENTIAL
`:h <topic>  <C-]>  <C-t>  :lua = <expr>  :messages  :checkhealth`

### OPTIONAL
`:helpgrep <pat>  :scriptnames  :verbose <cmd>  :verbose map <lhs>  :Lazy profile`

### ADVANCED
`debug.getinfo(fn).source  :tag <pat>  :ptag <pat>  :helptags ALL  :runtime <file>  :lua = vim.api.nvim_get_runtime_file('lua/**/*.lua', true)`

## 7. Drills

Run each in your own Neovim. Confirm with `done N` / `stuck N <details>`.

1. From a fresh Neovim, type `K` while hovering over `vim.system` in any Lua file. Then follow `<C-]>` until you reach the function signature in the help. Pop back twice with `<C-t>`.
2. Use `:lua =` to inspect three different namespaces: `vim.diagnostic`, `vim.snippet`, `vim.uv`. Note the differences in shape.
3. Type `:verbose imap <C-l>` (after your snippet keymap is wired) — confirm Neovim prints the file:line where the mapping was defined.
4. Run `:helpgrep vim%.snippet%.jump` — find every place this is mentioned. Open the second result with `:cn`.

## 8. Troubleshooting

- **"`:help vim.lsp.config` says E149."** Tag table out of date. Run `:helptags ALL` or restart.
- **"`:lua = vim.something` prints `nil`."** That namespace doesn't exist (or hasn't been required yet). Try `:lua = package.loaded` to see what's been loaded.
- **"`<C-]>` does nothing in help."** Cursor not on a recognizable tag. Look for the `|tag|` markup; that's what's clickable.

## 9. Optional config edit

None — this is a meta-skill session. The config is fine.

## 10. Next-step upgrades

- Bind `<Leader>?` to a snippet that opens `:lua = ` waiting for input. (Optional; some users find it overkill.)
- Once `:lua =` is reflex, you stop opening browsers for "what does this function do" — the answer is in the buffer in 2 seconds.

## 11. Connects to

Next: **Session 18 — Custom textobjects & operators.** Now that you can find any builtin, you can start writing your own — operators via `g@` + `opfunc`, textobjects via `nvim_buf_set_keymap` in operator-pending mode.
