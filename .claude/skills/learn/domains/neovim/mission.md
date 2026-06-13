# Mission: neovim

## Why
Neovim is my *only* editor for C++/Python/Rust infra work — no JetBrains, no VSCode, no
fallback. The driver isn't aesthetics or productivity bragging rights: it's **staying in
flow on complex C++ codebases**. Market data work means reading large, unfamiliar code
(SBE codecs, FIX parsers, protocol handlers, vendor SDKs) under time pressure during
incidents and market hours. Every GUI context-switch — mouse, dialog, popup — breaks the
mental model I'm building. A terminal-native editor I fully own keeps thought and edit on
the same surface, and works identically over SSH to any dev host.

## What success looks like
- **Project-wide symbol navigation matches CLion**: find references, call hierarchy, type
  hierarchy, jump-to-def across headers/templates in a large C++ repo without friction.
- **Multi-file refactors beat GUI IDEs on the same task**: rename across project, extract,
  reshape APIs in SBE/FIX/protocol code using LSP code actions, quickfix lists, macros.
- **DAP debug loop is faster than clicking through a GUI debugger**: breakpoint → run →
  inspect → re-run with keystrokes, for C++ (gdb/lldb), Python, Rust.
- **Editing composition is automatic**: operator + motion + text object, registers, macros,
  dot-repeat — no conscious lookup, no cheatsheet during real work.
- **Clean Neovim ≥ 0.12 setup**: native LSP, native completion, treesitter — no legacy APIs
  (`require('lspconfig').X.setup{}`, nvim-cmp, `vim.loop`), no distro (LazyVim/NvChad/etc).
- **Config I understand line-by-line** at `~/x/dotfiles/.config/nvim/`, audited regularly,
  every plugin justified.

## Primary work anchor
**Reading unfamiliar C++ to understand and debug market data systems** is the most common
real task. Live incident debugging and SBE/FIX refactors come second. Bias learning toward
navigation and comprehension speed first, edit-heavy refactor second, fresh authoring last.

## Deadline
Continuous mastery — daily small reps indefinitely. No ramp deadline; the goal is the
practice, not a finish line. Pace by consistency.

## Constraints / style
- Skip absolute basics — assume comfort with modes, basic motions, `:w`/`:q`, buffers.
- Anchor to my real config at `~/x/dotfiles/.config/nvim/` with `file:line` citations and
  before/after buffer examples.
- Hold **0.12+ discipline**: never teach `require('lspconfig').X.setup{}`, nvim-cmp,
  `vim.loop`, or distro-first answers.
- Stay scoped to **C++ / Python / Rust** — skip LSP/tooling guides for languages I don't
  use at work.
- No vimscript-era plugins or vim-plug; Lua-native only.
- No cosmetic tinkering (themes, statuslines, dashboards) — function over form.
- Flashcards don't suit motor skill — learn via `mm` + `drill` + `cheatsheet`, not `flash`.
