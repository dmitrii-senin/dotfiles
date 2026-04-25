---
session: 16
title: Git, Performance, Long-Term Config Evolution
phase: E
prerequisites: [7, 15]
duration: 60 min
---

# Session 16 — Git, Performance, Long-Term Config Evolution

## 1. Objective

Master the git workflow inside Neovim (gitsigns + lazygit + diffview) without dependence on external GUIs. Profile startup with `nvim --startuptime` and `:Lazy profile`. Establish conventions for keeping your `init.lua` healthy and prunable at year five. After this session, the config is a *system you maintain*, not a fragile snowflake.

## 2. Why it matters

A Neovim config that grows for a year without pruning becomes its own debugging burden. Most "Neovim is slow" complaints are actually "I added 50 plugins without measuring." This session shows you how to keep the config small, fast, and intentional indefinitely.

## 3. Core concepts

### Git inside Neovim — three layers

**Layer 1 — `gitsigns.nvim`** (already installed). Inline sign-column markers (`+`/`~`/`-`) for hunks. Hunk navigation. Stage/reset hunks from the editor.

Common maps (verify in `gitsigns.lua`):
- `]g` `[g` — next/prev hunk
- `<Leader>gp` — preview hunk
- `<Leader>gs` — stage hunk
- `<Leader>gr` — reset hunk
- `<Leader>gb` — blame line

**Layer 2 — `lazygit`** (already installed). Full TUI for status, log, branch, rebase. The right tool for branch management and interactive rebase. Map (likely): `<Leader>gg` opens it.

**Layer 3 — `vim-fugitive` or `diffview.nvim`** (NOT installed). For line-level integration:
- `:G` (fugitive) → `git status` in a buffer; press `s` to stage hunks, `<CR>` to view diff. The OG of git plugins.
- `diffview.nvim` → three-way diff for merges; branch-to-branch diff browsing.

For your stack, **lazygit + gitsigns covers 95%**. diffview is worth adding for merge conflicts; fugitive is optional.

### Performance — the three tools

**`nvim --startuptime <file>`** — log every step of startup with timing. Run:

```
nvim --startuptime /tmp/startup.log +q
sort -k2 -n /tmp/startup.log | tail -30
```

Look for:
- Plugin `setup()` calls > 5ms
- `lazy = false` plugins doing heavy work
- Treesitter parsers (treesitter `lazy = false` is fine; the *FileType autocmd* is what runs per buffer)

**`:Lazy profile`** (`<Leader>L` → `p`) — per-plugin load times AND when each loaded. Look for:
- Plugins loaded eagerly that could be `event = "VeryLazy"` or `keys = ...` or `cmd = ...`.
- Plugins with > 50ms load time — investigate.

**`:profile`** — Vimscript profiler. Less useful in modern Lua-heavy configs but still works:

```
:profile start /tmp/nvim.profile
:profile func *
:profile file *
" do something slow
:profile pause
:e /tmp/nvim.profile
```

For Lua, prefer `vim.uv.hrtime()` around suspect code:

```lua
local t = vim.uv.hrtime()
-- code
print(string.format("took %.2f ms", (vim.uv.hrtime() - t) / 1e6))
```

### Long-term config evolution — the rules

1. **Commit your config to git.** You already do (`~/x/dotfiles/`). Commit `lazy-lock.json` too — it's the reproducibility anchor.
2. **One commit per change.** Even small ones. Future-you will run `git log -p init.lua` and want clean diffs.
3. **Per-plugin file commits.** Adding a plugin = one commit touching one file. Avoid grab-bag "config tweaks" commits.
4. **Annotate per-plugin files** with a top-of-file comment: `-- Purpose: <X>. Without it: <Y>. Alternative: <Z>.` This is cheap insurance against "why did I add this?" amnesia.
5. **Audit quarterly.** Run `/neovim-mastery audit` (this skill). Identify plugins you no longer use; remove them.
6. **Resist churn.** "There's a new completion plugin" is not a reason to swap. The cost of swapping is days; the benefit is usually marginal. Swap when you have a *named* pain.
7. **Track Neovim major versions.** When 0.13 lands, read the breaking changes; don't blindly upgrade.
8. **Prune `lazy-lock.json` after big upgrades.** `:Lazy update` followed by smoke-test, then commit the new lockfile.
9. **Per-machine overrides** via a `lua/custom/local.lua` that's `require()`ed conditionally and `.gitignored`. Useful for work vs personal differences.
10. **Documentation > comments.** Maintain a top-level `~/x/dotfiles/.config/nvim/README.md` describing the config's philosophy. Future-you reads this.

### Pruning checklist

Each plugin in your `lua/custom/plugins/` deserves an annual question:
- Have I used this in the last 30 days?
- If I removed it tomorrow, what specifically would break?
- Is there a 0.12 builtin (or simpler plugin) that covers 80% of its value now?

If two of three answers are "no," prune.

## 4. Config notes

- `gitsigns.lua` — read on demand for current maps.
- `lazygit.lua` — read on demand. Likely `<Leader>gg` opens.
- `init.lua:25-27` — `checker.enabled = true`, `notify = false` — silent automatic plugin update checks.
- `lazy-lock.json` — committed in your dotfiles. Good.
- No diffview, no fugitive. lazygit covers most needs.

Notable for evolution:
- Your `init.lua` is 41 lines — clean.
- Your `lua/custom/plugins/` has 18 files — manageable, all justifiable.
- Commit history (`git log --oneline -20` in dotfiles) shows incremental, focused commits — you already follow good evolution hygiene.

## 5. Concrete examples

### Stage and commit changes from inside Neovim (gitsigns + lazygit)

1. Edit a file. Make a logical change.
2. `]g` to navigate to the hunk you just made.
3. `<Leader>gp` to preview (confirm it's right).
4. `<Leader>gs` to stage the hunk only (not the whole file).
5. `<Leader>gg` (or whatever your map is) → opens lazygit.
6. In lazygit: `c` to commit, type message, `<CR>`.
7. `q` to close lazygit.

For full-file staging, `git add file` in a `:term` is also fine.

### Profile startup

```
:! nvim --startuptime /tmp/startup.log +q
:e /tmp/startup.log
" sort by 3rd column (time per step) descending
:%!sort -k2 -n
G
```

The biggest entries are usually plugin loads. Anything > 5ms in `lazy = false` is suspect.

Then in Neovim:
```
<Leader>L
" press p
" inspect the per-plugin load times and triggers
```

### Identify a slow autocmd

```lua
-- in your config, wrap suspect callbacks:
local t = vim.uv.hrtime()
-- existing callback
print((vim.uv.hrtime() - t) / 1e6, "ms")
```

Or add `pcall` + duration check + `vim.notify` if you want instrumentation.

### Bootstrap a fresh machine reproducibly

Two pieces work together:

1. **`mason-tool-installer`** declares the full external-tool set (LSPs, formatters, debuggers, linters) in `lua/custom/plugins/mason.lua`. On a new machine, opening Neovim runs `:MasonToolsInstall` automatically (`run_on_start = true`). No more "wait, did I install codelldb on this laptop?"

2. **`:checkhealth custom`** runs `lua/custom/health.lua`, which asserts:
   - **Required-on-PATH**: `rg`, `fd`, `git`, `lazygit`.
   - **Recommended runtimes**: `python3`, `cargo`, `node`, `g++`, `make`.
   - **Mason-managed binaries**: every entry in `ensure_installed`, checked under `~/.local/share/nvim/mason/bin/`.
   - **Neovim version**: ≥ 0.11 required, ≥ 0.12 unlocks `vim.lsp.foldexpr` etc.

After installing dotfiles on a new machine: open Neovim, wait for `:Lazy` and `:Mason` to settle, run `:checkhealth custom`. Anything red is a real blocker.

### Add a CHANGELOG to your config

`~/x/dotfiles/.config/nvim/CHANGELOG.md`:

```markdown
## 2026-04-20
- Added vim.lsp.foldexpr to clangd LspAttach (faster folds for large translation units).
- Removed neo-tree.nvim — oil.nvim covers all needs.

## 2026-03-15
- Switched pyright → basedpyright. Faster, catches more.
```

Optional but valuable. ASK before adding (it's process, not code).

## 6. Shortcuts to memorize

### ESSENTIAL
`]g [g`  (gitsigns hunk nav)
`<Leader>gp gs gr gb`  (gitsigns: preview/stage/reset/blame — verify your map prefix)
`<Leader>gg`  (lazygit toggle — verify map)
`:Lazy` (`<Leader>L`) — UI; `p` for profile

### OPTIONAL
`:!nvim --startuptime /tmp/log +q`  (startup audit from current shell)
`:Lazy log <plugin>`  (commit history of one plugin)
`:Lazy restore`  (roll back to lockfile after a bad update)
`vim.uv.hrtime()`  (microsecond timestamps for ad-hoc profiling)

### ADVANCED
`:profile` (full Vimscript profiler — rarely needed in Lua-heavy configs)
Per-plugin lazy-spec triggers (revisit Session 7 for tightening)
Custom autocmd to log slow operations (instrumentation)

## 7. Drills

1. Run `nvim --startuptime /tmp/startup.log +q`. Open `/tmp/startup.log`. Identify the top 5 slowest steps. (Hint: `:%!sort -k2 -n | tail -10`.)
2. In Neovim, `<Leader>L` then `p` (Lazy profile). Identify the slowest plugin. Is it `lazy = false`? Could it be `event = "..."` instead?
3. Edit a file with gitsigns. Make 3 small hunks in different parts of the file. Use `]g`/`[g` to navigate. Stage one with `<Leader>gs`. Reset another with `<Leader>gr` (verify maps).
4. Open lazygit (`<Leader>gg` or whatever your map is). Practice: stage, commit, view log, return to nvim.
5. Audit one plugin in your config. Read its `plugins/<name>.lua` file. Answer: when does it load? Could the trigger be tighter? If you removed it, what would break?

## 8. Troubleshooting

- **"`<Leader>L` doesn't open Lazy."** Verify the map: `:nmap <Leader>L`. Or just run `:Lazy`.
- **"Profile shows 200ms+ startup but everything's lazy."** Treesitter parsers (`lazy = false` is correct) might be slow on first parse. Or a `lazy = false` plugin's `setup()` is doing heavy work.
- **"gitsigns hunks don't show."** Check `:Gitsigns toggle_signs`. Ensure you're inside a git repo. `:Gitsigns refresh`.
- **"lazygit can't find git."** Ensure `git` is on your `$PATH`. Test in `:term git status`.
- **"`lazy-lock.json` keeps changing."** Some plugins update on `:Lazy sync`. Commit the lockfile after stable updates; don't fight the lockfile.

## 9. Optional config edit

**Annotate plugin files (a discipline change, not a code change).** For each `lua/custom/plugins/*.lua`, add at top:

```lua
-- Purpose: format any filetype with one keystroke.
-- Without it: I'd reach for :term <formatter> per language.
-- Alternative: none-ls.nvim (heavier; mostly redundant with conform).
return {
  "stevearc/conform.nvim",
  ...
}
```

ASK before doing this in bulk; it's optional but pays dividends in 6 months.

**Add a CHANGELOG.md** at `~/x/dotfiles/.config/nvim/CHANGELOG.md`. Format above. Optional.

## 10. Next-step upgrades

- **`diffview.nvim`** for in-buffer three-way diff (merge conflicts).
- **`vim-fugitive`** if you want `:G` status integration (some swear by it; lazygit covers most cases).
- **Per-machine config overrides** via `lua/custom/local.lua` (gitignored).
- **Run `/neovim-mastery audit`** quarterly. The skill is designed for this rhythm.
- **Read the Neovim release notes** for each major version (`0.12 → 0.13`). Often there are features that obsolete plugins you have.

## 11. Connects to

You've completed the curriculum. From here:

- Re-run `/neovim-mastery audit` — apply the highest-impact items first.
- Use `/neovim-mastery review <topic>` as a refresher.
- Use `/neovim-mastery free <question>` for ad-hoc help.
- Re-run any session by number when you want a deep refresh.

The skill stays useful indefinitely because your config evolves. The next session is whatever you pick.
