# `audit` mode (neovim domain) — config auditor

A tool, not a curriculum: read the real Neovim config, compare against 0.12+ best
practices and the reference inventory, and produce a ranked table of actionable
improvements. The user picks what to apply; apply with per-change confirmation.

Invoked as `/learn neovim audit [focus]` (or `/nvim audit [focus]`).
Focus: `full` | `keymaps` | `plugins` | `perf` | `lsp` | `options`. Empty → `full`.

Config lives at `~/x/dotfiles/.config/nvim/` (symlinked from `~/.config/nvim/`). All
reference paths below are relative to this domain dir (`domains/neovim/`).

---

## Reference files (read as needed)
- `references/current-config-snapshot.md` — cached config inventory (may be stale)
- `references/customization.md` — adaptation rules + upgrade candidates
- `references/anti-patterns.md` — forbidden patterns table
- `references/keymaps.md` — keymap taxonomy and rules
- `references/architecture.md` — plugin category matrix + swap criteria

## Audit protocol (10 steps — do not skip any)

1. **Read config files** (subset by mode):
   | Mode | Files |
   |---|---|
   | `full` | all `.lua` under `lua/custom/` + `init.lua` |
   | `keymaps` | `lua/custom/core/keymaps.lua` + all plugin `keys = {..}` specs |
   | `plugins` | all under `lua/custom/plugins/` |
   | `perf` | `init.lua` + plugin specs (`lazy`/`event`/`cmd`/`ft`) + `lua/custom/core/autocmds.lua` |
   | `lsp` | `lspconfig.lua` + `mason.lua` + `conform.lua` + `lint.lua` |
   | `options` | `lua/custom/core/options.lua` |
   Use `Read` on each — don't rely on the snapshot alone.
2. **Read references**: `current-config-snapshot.md` + `customization.md`; plus
   `keymaps.md` (keymaps mode), `architecture.md` (plugins mode), and `anti-patterns.md`
   (all modes).
3. **Detect snapshot drift** — diff actual config vs cached snapshot (new/removed plugins,
   changed keymaps/options/LSP, new files). Report drift before the upgrade evaluation.
4. **Evaluate upgrade candidates** in `customization.md` against the actual config (done?
   still applicable? new 0.12+ opportunities not listed?).
5. **Check forbidden patterns** (`anti-patterns.md` + the table below). Violations are
   HIGH-tier findings.
6. **Mode-specific checks:**
   - **keymaps** — missing `desc`, prefix collisions, shadows of Vim defaults, leader-map
     cap, drift from `keymaps.md`.
   - **plugins** — `lazy=false` that could trigger on event/cmd/ft, redundant plugins,
     missing plugins for the C++/Python/Rust workflow, outdated APIs vs 0.12 builtins.
   - **perf** — needless `lazy=false`, heavy `VimEnter`/`BufReadPre` autocmds, defer to
     `VeryLazy`/`LspAttach`/ft; suggest `nvim --startuptime` + `:Lazy profile`.
   - **lsp** — server config completeness, LspAttach wiring (completion/inlay/folding/
     highlight), `vim.diagnostic` config, missing servers.
   - **options** — missing 0.12+ options (`smoothscroll`, `fillchars`, `listchars`),
     deprecated/conflicting options, C++ QoL options.
7. **Output ranked table:**
   ```
   | # | Tier | Candidate | Cost | Rationale | Action |
   ```
   Tiers: **HIGH** (bug/anti-pattern/missing daily-workflow feature), **MED** (cleaner/
   faster/maintainable), **LOW** (nice-to-have/taste). Cost: **easy** (1–5 lines, 1 file),
   **medium** (5–30 lines, 1–2 files), **hard** (30+ lines, multi-file). Sort tier then cost.
8. **Wait for selection** — *"Select items by number (e.g. '1, 3, 5'), or 'all'."* Never auto-apply.
9. **Show diffs and apply** — per item: unified diff (`--- a/...` / `+++ b/...`, 3 lines
   context) → ask "Apply this change? (y/n)" → on yes, `Edit` using the **dotfiles path**
   `~/x/dotfiles/.config/nvim/...`, **never** `~/.config/nvim/...`. One at a time; never
   batch-apply. After each, remind: "Run `git diff` to review, commit when ready."
10. **Update state** — refresh `references/current-config-snapshot.md` for changed files
    (update its date); append to `data/session-log.md`:
    ```markdown
    ## YYYY-MM-DD — audit / <mode>
    - Findings: N (H high, M med, L low)
    - Applied: #X, #Y    Deferred: #A, #B
    ```

## Forbidden patterns (0.12+ discipline)
| Use (0.12+) | Don't (legacy) |
|---|---|
| `vim.lsp.config(name,opts)` + `vim.lsp.enable({...})` | `require('lspconfig').X.setup{}` |
| `vim.lsp.completion.enable(true,id,buf,{autotrigger=true})` | nvim-cmp / blink.cmp |
| `vim.diagnostic.jump({count=±1,severity=...})` | `vim.diagnostic.goto_next/goto_prev` |
| `vim.uv` | `vim.loop` |
| `vim.system()` | `vim.fn.system()` for new async |
| `require('nvim-treesitter').install(parsers)` | `require('nvim-treesitter.configs').setup{}` |

**Never recommend:** distro-first answers (LazyVim/NvChad/AstroNvim/Kickstart); plugins
without a named pain + breakage scenario + one alternative; keymap drift (check
`keymaps.md` first); aesthetic plugins unprompted; plugin swaps without a named pain;
plugins already installed (check snapshot + actual config first).

## Output style
Terse, tabular, actionable — a report, not a lesson. Lead with drift (step 3) if any.
No emojis; plain `HIGH`/`MED`/`LOW`. Start reading files immediately, no preamble. If a
mode has zero findings: "No findings for <mode>. Config is clean." and log it.

## Cross-references
Tie findings to learning sessions where useful:
`/nvim lsp mm 'completion'`, `/nvim config mm 'lazy.nvim'`, `/nvim core mm 'registers'`,
`/nvim tooling mm 'DAP'`.
