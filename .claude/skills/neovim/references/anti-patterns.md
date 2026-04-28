# Reference: Anti-patterns the Coach Must Refuse

These are responses the skill must NOT produce, with reasons. Treat each as a reflex: if you're about to do this, stop and reframe.

## 1. Pre-0.11 LSP setup

**Don't:**
```lua
require('lspconfig').clangd.setup{
  cmd = {...},
  on_attach = function(...) ... end,
}
```
**Do:**
```lua
vim.lsp.config('clangd', { cmd = {...} })
vim.lsp.enable({ 'clangd' })
-- on_attach behavior goes in a vim.api.nvim_create_autocmd('LspAttach', ...)
```
**Why:** the user's config already uses the modern API. Recommending the legacy form would push them backwards.

## 2. `vim.diagnostic.goto_next` / `goto_prev`

**Don't:** `vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })`
**Do:** `vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })`
**Why:** `goto_next`/`goto_prev` are deprecated; `jump` unifies and uses `count` for direction.

## 3. `vim.loop` / `vim.fn.system` in new code

**Don't:** `vim.loop.new_timer(); vim.fn.system({ 'cargo', 'check' })`
**Do:** `vim.uv.new_timer(); vim.system({ 'cargo', 'check' }, {}, on_exit)`
**Why:** `vim.uv` is the maintained alias; `vim.system` is async and structured.

## 4. Old treesitter setup

**Don't:**
```lua
require('nvim-treesitter.configs').setup{
  ensure_installed = {...},
  highlight = { enable = true },
}
```
**Do:**
```lua
require('nvim-treesitter').install(parsers)
vim.api.nvim_create_autocmd('FileType', { callback = function() pcall(vim.treesitter.start) end })
```
**Why:** the new install API is what the user already runs (`treesitter.lua:47`).

## 5. Distro-first answers

**Don't:** "You should just use LazyVim."
**Do:** Acknowledge LazyVim/AstroNvim/NvChad/Kickstart exist as starting points; recommend them only if the user explicitly says "give me a distro." The user has already built their own config — pushing a distro is regressive.

## 6. Plugin recommendations without rationale

**Don't:** "Install lualine, nvim-tree, dashboard-nvim, alpha-nvim, …"
**Do:** Each recommendation must answer:
1. What problem does it solve?
2. What breaks (concretely) without it?
3. What's one credible alternative?

## 7. Aesthetic plugins, unprompted

**Don't:** Recommend statuslines, themes, dashboards, icons, or animation plugins unless the user asks. The user's setup uses `laststatus=3` with the built-in statusline + Catppuccin macchiato — that's a deliberate choice.

## 8. Recommending plugins the user already has

Always check `references/current-config-snapshot.md` first. If the user already runs telescope, don't suggest installing telescope. Suggest a tweak, a picker they don't know, or move on.

## 9. Keymap drift

**Don't:** Propose `<Leader>p` for "find files" (collides with no convention, ignores `<Leader>f*`).
**Do:** `<Leader>ff` (matches the established `<Leader>f*` find prefix). See `references/keymaps.md`.

## 10. Hidden complexity / magic abstractions

**Don't:** Recommend a wrapper plugin (e.g. rustaceanvim) without naming the underlying API it wraps and the cost of the abstraction (debug session config gets harder to customize, divergence from how other LSPs are wired).

## 11. Firehose teaching

**Don't:** Dump 50 keymaps, 200 lines of config, and 10 plugins in one response. Layer.

## 12. Workflow monoculture

**Don't:** "Use neotest for everything." C++ unit tests, Python pytest, and Rust cargo-test all have different ergonomics. Tell the truth about which workflow wins where.

## 13. Premature DAP / advanced features

**Don't:** Push `nvim-dap-virtual-text` setup before the user is fluent with `<Leader>db/dc/do/di`. Order matters.

## 14. Ignoring `:help`

**Don't:** Make up plugin APIs from training data. **Do:** Cite `:help <topic>` and reach for `https://neovim.io/doc/user/` when uncertain.

## 15. Auto-committing edits

**Don't:** `git add . && git commit` after applying a config change. **Do:** Apply the edit, remind the user to `git diff` and commit when ready.

## 16. Editing through `~/.config/nvim/...`

**Don't:** Path edits to `/Users/kairo5/.config/nvim/<file>` even though the symlink resolves. **Do:** Use `/Users/kairo5/x/dotfiles/.config/nvim/<file>` so edits stay in cwd boundary and are visibly version-controlled.

## 17. Recommending churn

**Don't:** "Switch from telescope to fzf-lua now, it's faster." The user has telescope wired to LSP overrides and a working flow. Switching is days of friction. Only recommend a swap when the user has a *named* pain.

## 18. Theme/colorscheme suggestions, unprompted

The user runs `catppuccin-macchiato`. Don't suggest tokyonight, gruvbox, or anything else unless asked.

## 19. Treating the snapshot as gospel

`references/current-config-snapshot.md` is a frozen-in-time inventory. Before recommending an edit based on it, **read the actual file** to confirm nothing has changed since the snapshot. Update the snapshot when you confirm a change.

## 20. Skipping the protocol

For full sessions, follow the 10-step structure even when individual steps are short. The structure is the teaching.
