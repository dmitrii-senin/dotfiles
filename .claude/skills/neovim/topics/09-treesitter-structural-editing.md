---
session: 09
title: Treesitter & Structural Editing
phase: C
prerequisites: [2, 8]
duration: 45 min
---

# Session 09 — Treesitter & Structural Editing

## 1. Objective

Use treesitter parsers and `nvim-treesitter-textobjects` (`af/if/ac/ic/aa/ia`, `]m/[m`, swap) for real refactors in C++/Python/Rust. After this session, "select this function", "swap these two arguments", "jump to the next class" are reflex.

## 2. Why it matters

Vim's built-in `iw`/`ip`/`i(` text objects are character-or-bracket based. Treesitter gives you **syntactic** text objects: `af` is *the function*, not "the paragraph that happens to contain a function". For C++ template specializations, Python decorator stacks, and Rust impl blocks, that distinction is everything.

## 3. Core concepts

### What treesitter is

A library that parses your source into an actual syntax tree (CST). Plugins query the tree to:
- Highlight (more accurate than regex syntax).
- Indent (knows that a `}` closes a block).
- Fold (collapses by syntactic node, e.g. functions, classes).
- Provide text objects (the killer feature for editing).
- Power navigation (`]m` = next function start, etc.).

### `nvim-treesitter` (the plugin)

Wraps tree-sitter. Installs language parsers (compiled C grammars). Provides hooks for highlight/indent/fold. Your config uses the **new install API** (0.10+):

```lua
require("nvim-treesitter").install({ "cpp", "rust", "python", "lua", ... })
```

(Compare the legacy `require('nvim-treesitter.configs').setup{ ensure_installed = ... }` — DO NOT teach this.)

Your config also starts treesitter highlight per-buffer via a `FileType` autocmd (`treesitter.lua:49-54`):

```lua
vim.api.nvim_create_autocmd("FileType", {
  callback = function() pcall(vim.treesitter.start) end,
})
```

`pcall` swallows errors for filetypes without parsers. Folds are wired via `vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"` (lines 56-57).

### `nvim-treesitter-textobjects`

A separate plugin layered on top. Provides:
- **Selectors:** `select_textobject("@function.outer", "textobjects")` → cursor selects the function.
- **Movers:** `goto_next_start("@function.outer", ...)` → jump to next function start.
- **Swappers:** `swap_next("@parameter.inner")` → swap current parameter with the next.

Your config wires these (`treesitter.lua:80-134`). With `lookahead = true`, motions work even when cursor is *between* targets — Vim jumps to the next one.

### Treesitter queries

The `@function.outer`, `@class.inner`, etc. are **captures** defined in `.scm` query files shipped with treesitter-textobjects. Per-language. Look at any of them:

```
~/.local/share/nvim/lazy/nvim-treesitter-textobjects/queries/python/textobjects.scm
```

## 4. Config notes

Your `treesitter.lua` is well-tuned. Highlights:

- **Lines 1-36** — the `parsers` table is your "ensure installed" list. Tracks your stack: `c, cpp, python, rust, lua, bash, cmake, dockerfile, asm, nasm, json, yaml, …`.
- **Line 46** — `lazy = false` for treesitter. Correct: treesitter must be ready before any file opens, otherwise the first buffer won't get highlighted.
- **Line 47** — `require("nvim-treesitter").install(parsers)` — new install API.
- **Lines 49-54** — `FileType` autocmd starts treesitter per buffer.
- **Lines 56-57** — folds via treesitter foldexpr (this is your *current* fold provider; LSP folds (Session 8) would supplement, not replace).
- **Lines 70-77** — textobjects `select.lookahead = true`, `move.set_jumps = true` (so `<C-o>` returns from `]m` jumps).
- **Lines 80-99** — select keymaps: `aa/ia` parameter, `af/if` function, `ac/ic` class.
- **Lines 101-126** — move keymaps: `]m/[m` function start, `]M/[M` function end, `]]/[[` class start, `][/[]` class end. Modes: `n/x/o`.
- **Lines 128-134** — swap: `<Leader>a/<Leader>A` swap parameter next/previous.

The dependency `nvim-ts-autotag` (line 44) auto-closes HTML/JSX tags. Useful for web work.

## 5. Concrete examples

### C++ — extract a function

```cpp
int compute(int x, int y) {
  // 30 lines of logic
  // ^ cursor anywhere inside
}
```

`vaf` selects the entire function. `"ad` yanks-and-deletes into register `a`. Now use clangd `gra` → "Extract function" if available, OR paste with `"aP` elsewhere and edit signature.

### Python — yank a class

```py
class UserService:
    def __init__(self, db): ...
    def find(self, user_id): ...
    def update(self, user): ...
```

Cursor anywhere inside. `yac` yanks the entire class. `vac` to visually inspect first.

### Rust — swap two function arguments

```rs
fn process(input: String, options: Options) -> Result<()> { ... }
//          ^ cursor on `input`
```

`<Leader>a` swaps `input: String` with `options: Options` → result: `fn process(options: Options, input: String) ...`. (Your config does this via `swap.swap_next("@parameter.inner")`.)

### Universal — navigate functions in a long file

`]m` jumps to next function start. `[m` to previous. `]M` to next function *end* (useful for placing cursor right after a function for adding a new one). `<C-o>` to retrace.

### Inspect the tree

`:Inspect` (under cursor) → shows highlight groups. `:InspectTree` → opens a buffer with the parsed syntax tree of the current file. `:EditQuery` → a live query editor.

## 6. Shortcuts to memorize

### ESSENTIAL
`af if ac ic aa ia`  (textobjects)
`]m [m  ]M [M  ]] [[  ][ []`  (motions, your config)
`<Leader>a <Leader>A`  (swap parameter)
`zR zM  zo zc  zR za`  (folds — open all / close all / per-fold / toggle)

### OPTIONAL
`:Inspect  :InspectTree  :EditQuery`
`:TSInstallInfo` (legacy command, may not work with new API; prefer `:lua print(vim.inspect(require('nvim-treesitter').get_installed()))`)

### ADVANCED
Custom captures via `~/.config/nvim/queries/<lang>/textobjects.scm` (overrides plugin defaults)
`:lua vim.treesitter.query.parse('python', '(class_definition) @class')` — programmatic queries

## 7. Drills

1. Open `treesitter.lua`. Use `]m` to jump function starts. Count how many `function() ... end` blocks the file contains. Use `<C-o>` to return.
2. Open a C++ or Python file. Place cursor inside a function. Type `vaf` — confirm the entire function is selected. Then `dap` (delete *paragraph*) to compare and feel the difference.
3. Open a Rust file with a function taking 2-3 parameters. Cursor on first parameter. `<Leader>a` repeatedly to cycle parameters.
4. Open `lspconfig.lua`. Use `zM` to close all folds, then `zR` to open all. Use `za` to toggle the fold under cursor.
5. Run `:InspectTree` on any source file. Navigate the tree buffer with `j/k`. Note how nodes correspond to source structure.

## 8. Troubleshooting

- **"`af` selects nothing or selects too much."** Parser missing or stale. Run `:checkhealth nvim-treesitter`. Re-install with `:lua require('nvim-treesitter').install({'<lang>'})`.
- **"Highlighting is broken / colors are wrong."** Try `:e` to re-detect filetype. Check `:set filetype?`. Run `:Inspect` to see the highlight group under cursor.
- **"`]m` jumps to wrong places."** `lookahead = true` (your setup) means it jumps even when not on a function. Sometimes surprising; live with it or set `lookahead = false`.
- **"Folds are wrong."** Check `:set foldexpr?` — should be `v:lua.vim.treesitter.foldexpr()`. If LSP folds are also enabled (Session 8), the LspAttach setter may have overridden — that's intentional.

## 9. Optional config edit

If you find yourself wanting argument-list textobjects for Python decorator stacks (a niche need), consider [`mini.ai`](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-ai.md) for extensible custom textobjects. ASK before adding — your current treesitter-textobjects setup is already strong.

## 10. Next-step upgrades

- **`nvim-treesitter-context`** — sticky function header at top of window. Useful in long C++ functions; adds visual noise. LOW-priority audit candidate.
- **Custom treesitter queries** for project-specific captures (e.g., a `@todo` capture for your team's TODO format). Advanced; skip unless you have a real use case.

## 11. Connects to

Next: **Session 10 — Fuzzy Finding & Project Navigation**. You can navigate by structure within a file. Now let's navigate across the project.
