# Mission: neovim

## Why
Neovim is my primary editor for C++/Python/Rust infra work. I've outgrown the basics and
want *systematic* depth — fluent operator-motion composition, fast navigation, a modern
0.12+ LSP/treesitter setup, and a config I fully own and can evolve. Editing speed and a
frictionless IDE-grade workflow compound every hour I spend in the editor.

## What success looks like
- Compose edits fluently (text objects, registers, macros, dot-repeat) without thinking.
- Navigate buffers/quickfix/telescope/marks/jumps without breaking flow.
- Run a clean Neovim ≥ 0.12 LSP + native completion + treesitter setup — no legacy APIs.
- C++/Python/Rust IDE workflows (clangd/pyright/rust-analyzer, DAP, format/lint) dialed in.
- A config I understand line-by-line, audited regularly against best practices.

## Deadline
Continuous mastery for daily work. Pace by consistency.

## Constraints / style
Skip absolute basics. Anchor to my real config at `~/x/dotfiles/.config/nvim/` with
`file:line` citations and before/after buffer examples. Hold 0.12+ discipline — never
teach `require('lspconfig').X.setup{}`, nvim-cmp, `vim.loop`, or distro-first answers.
Flashcards don't suit motor skill — learn via `mm` + `drill` + `cheatsheet`, not `flash`.
