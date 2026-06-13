# Domain: neovim — Neovim 0.12+ mastery

title: Neovim ≥ 0.12 Mastery (C++ / Python / Rust dev)
level: intermediate — comfortable with basics; wants systematic depth. Skip "what is Vim".

## Areas

`core`, `navigation`, `lsp`, `config`, `languages`, `tooling`

- **core** — operator-motion grammar, motions, text objects, operators, registers, macros, search, substitute, ex
- **navigation** — buffers, windows, tabs, marks, jumps, fuzzy finding, quickfix, location lists, oil, telescope, trouble
- **lsp** — `vim.lsp.config/enable`, native completion, diagnostics, inlay hints, treesitter, structural editing, format/lint
- **config** — Lua structure, lazy.nvim, plugin architecture, options, autocmds, `vim.api`, custom textobjects/operators, ts queries
- **languages** — C++/Python/Rust IDE workflows: clangd, pyright, rust-analyzer, DAP, format/lint, per-language text objects
- **tooling** — gitsigns/lazygit, DAP debugging, terminal, build integration, startup performance, plugin management

### Area prerequisites
- `core` is foundational — prefer before everything else.
- `lsp` and `config` precede `languages` (language workflows build on both).

## Modes

enabled: `mm`, `drill`, `cheatsheet`, `audit`, `status`
**`flash` is OFF** — flashcards don't suit motor/editing skill (no `flashcards/` dir).

- `audit` is a **domain-specific** mode → `modes/audit.md` (audits the real nvim config).
- `drill` is enabled (the originally-wished-for scenario practice — see drill flavor below).

## Session style (mm)
`mm` sessions are **15–30 min**. Step 2 (Concept) uses **tables/diagrams**, **real config
examples** from `~/x/dotfiles/.config/nvim/` with `file:line` annotations, and
**before/after buffer examples** (buffer state → keystrokes → result, using `█` U+2588 for
the cursor). End each topic with its `:help` anchor. Hold the **0.12+ discipline** (see
forbidden patterns in `modes/audit.md`): never teach legacy LSP/treesitter/`vim.loop` APIs.

## Drill flavor
Present a realistic **editing task**: a buffer with cursor `█`, a goal state, and a
constraint (*fewest keystrokes* / *text objects only* / *without leaving normal mode*).
Ask for the keystroke sequence (the user tries it in Neovim first). Score the 3 criteria
as: **identification** = right approach, **next step** = optimal/idiomatic sequence,
**reasoning** = why it composes (and dot-repeatability). Interleave across areas by default.

## Cheatsheets
default: `motions`
available: `motions`, `navigation`, `telescope`, `lsp-keymaps`, `vim-api`, `cpp-symbol-nav`

## Config anchor
Real config: `~/x/dotfiles/.config/nvim/` (symlinked from `~/.config/nvim/`). Edit only
the dotfiles path, never `~/.config/nvim/` directly. See `resources.md`.
