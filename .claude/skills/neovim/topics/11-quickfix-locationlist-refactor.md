---
session: 11
title: Quickfix, Location Lists, Project Refactor
phase: C
prerequisites: [5, 10]
duration: 45 min
---

# Session 11 — Quickfix, Location Lists, Project Refactor

## 1. Objective

Drive cross-file refactors with `:grep` → quickfix → `:cdo s/.../.../g | update`. Understand the difference between quickfix (global) and location list (window-local). After this session, "rename across 80 files" is one ex command, not a Python script.

## 2. Why it matters

Quickfix is Vim's universal "list of locations." Errors from `:make`, search results from `:grep`, references from LSP, telescope results — they all funnel into quickfix. Once you can drive a list, you can drive any list-based refactor.

## 3. Core concepts

### Quickfix vs Location list

| Quickfix                                      | Location list                                          |
| --------------------------------------------- | ------------------------------------------------------ |
| Global (one per Neovim instance)              | Window-local (one per window)                          |
| Filled by: `:make`, `:grep`, LSP, telescope `<C-q>` | Filled by: `:lmake`, `:lgrep`, LSP per-window, etc. |
| Open with `:copen`, close `:cclose`           | Open with `:lopen`, close `:lclose`                    |
| Navigate: `:cnext :cprev`                     | Navigate: `:lnext :lprev`                              |
| Drive batch edits: `:cdo`, `:cfdo`            | Drive: `:ldo`, `:lfdo`                                 |

**Rule of thumb:** use quickfix unless you specifically want a per-window list (e.g., per-window LSP diagnostics).

### Filling quickfix

| Source                        | Command                                       |
| ----------------------------- | --------------------------------------------- |
| ripgrep                       | `:grep <pattern>` (uses `grepprg`)             |
| Vim's built-in grep           | `:vimgrep /pat/g **/*.cpp`                    |
| Compiler errors               | `:make`                                        |
| LSP references / diagnostics  | `vim.diagnostic.setqflist()`, `vim.lsp.buf.references({...})` |
| Telescope                     | `<C-q>` in any picker                          |
| Manual                        | `:cexpr ['file1:1:foo', 'file2:5:bar']`        |

### Navigating quickfix

| Keys / Cmd     | Action                                       |
| -------------- | -------------------------------------------- |
| `:copen`       | Open quickfix window                         |
| `:cclose`      | Close quickfix window                        |
| `:cnext` `]q`  | Next entry (your config maps `]q`)           |
| `:cprev` `[q`  | Previous entry                               |
| `:cfirst` `:clast` | First / last                             |
| `:cnewer` `:colder` | Newer / older quickfix list (history)   |
| `:chistory`    | Show quickfix history                        |
| `<CR>` (in qf) | Jump to entry under cursor                   |

### Driving batch edits

`:cdo <ex-cmd>` — run `<ex-cmd>` on each entry's *line*.
`:cfdo <ex-cmd>` — run `<ex-cmd>` once per *file* in quickfix (not per entry).

Examples:

```
:cdo s/foo/bar/g                          " Substitute on each entry's line — DOES NOT save
:cdo s/foo/bar/g | update                 " Substitute and save — the canonical pattern
:cfdo %s/foo/bar/g | update               " Per-file substitute (covers entire file each time)
:cdo norm! @a                              " Run macro `a` on each entry
```

The `update` saves only if modified — safer than `write`.

### Trouble.nvim (your config has it)

`folke/trouble.nvim` is a richer UI for quickfix/loclist/diagnostics/LSP-references. Your config has it; check `trouble.lua` for keymaps. Common map: `<Leader>xx` → toggle (but yours is taken — verify your prefix).

## 4. Config notes

Your `keymaps.lua`:
- **Lines 45-46** — `<Leader>ll` opens loclist, `<Leader>lq` opens quickfix.
- **Lines 48-49** — `[q` and `]q` for cprev/cnext (very fast nav).
- **Lines 52-62** — diagnostic-specific: `]e/[e ]w/[w` use `vim.diagnostic.jump` (severity-aware).

`options.lua`:
- **Lines 41-42** — `grepformat = "%f:%l:%c:%m"`, `grepprg = "rg --vimgrep"`. So `:grep <pat>` → ripgrep → quickfix.
- **Line 48** — `inccommand = nosplit`. With quickfix open, `:cdo s/.../.../g` previews live.

## 5. Concrete examples

### Find-and-replace across project (the canonical pattern)

```
:silent grep "vim\.lsp\.config"            " or :Telescope live_grep -> <C-q>
:copen                                      " inspect what we caught
" looks good
:cdo s/vim\.lsp\.config/vim.lsp.config -- audited/g | update
```

If you want to be safe: add `c` flag for confirm — `:cdo s/.../.../gc | update`.

### LSP references → quickfix → review

```
" Cursor on a symbol
:lua vim.lsp.buf.references()
" By default opens telescope (your config). To send to quickfix:
:lua vim.lsp.buf.references(nil, { on_list = function(opts) vim.fn.setqflist({}, ' ', opts); vim.cmd('copen') end })
```

(Or simpler: `grr` opens telescope picker → `<C-q>` to send to quickfix.)

### Compile errors → quickfix → fix forward

```
:make                                       " runs makeprg, parses errors via errorformat
:copen                                      " review
]q                                          " next error
" fix it
:w
]q                                          " next
```

For C++/Rust this works if you set `makeprg` (e.g. `:setlocal makeprg=cargo\ build`).

### Macro over quickfix entries

```
" Quickfix has 50 lines containing "TODO:"
" Record a macro that fixes one line:
qa  " start recording
A REVIEWED<Esc>  " append text
:w<CR>           " save
q                " stop
" Apply to all 50:
:cdo norm! @a
```

### Filter quickfix

There's no built-in filter, but you can re-grep:

```
:cdo execute 'silent! lgrep <pat> %' | lopen      " complicated
" Easier: use telescope quickfix picker:
:Telescope quickfix
```

## 6. Shortcuts to memorize

### ESSENTIAL
`:grep <pat>  :copen  :cclose  ]q [q`  (your config)
`:cdo <cmd> | update  :cfdo <cmd> | update`
`<C-q>` (in any telescope picker — send to quickfix)
`<Leader>lq <Leader>ll`  (your maps)

### OPTIONAL
`:cnewer :colder :chistory`  (quickfix history navigation)
`:cexpr [list]`  (manual fill)
`:Telescope quickfix`  (browse the list with preview)

### ADVANCED
`:cdo norm! @a`  (run macro per entry)
`vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })` (LSP errors → qf)
Custom errorformat for non-standard build outputs (`:help errorformat`)

## 7. Drills

1. `:grep TODO` (or `:silent grep TODO` to skip the shell-output buffer). `:copen`. `]q` to navigate.
2. After step 1, run `:cdo s/TODO/REVIEW/g | update` (only if you want to actually do this — otherwise `:cdo s/TODO/TODO/g` is no-op for the drill). Confirm changes; `u` per-buffer to undo.
3. `:Telescope live_grep` → search "vim.lsp" → `<C-q>` → `:copen`.
4. In a Lua file with multiple `local foo = require(...)`, record a macro that converts one line to a different format. Then `:cdo norm! @a` to apply across quickfix.
5. Open `lspconfig.lua`. `:lua vim.lsp.buf.references()` after placing cursor on `vim.lsp.config` (line 75). If telescope opens, `<C-q>` → quickfix.

## 8. Troubleshooting

- **"`:grep` opens an empty buffer / shell prompt."** Use `:silent grep <pat>`. Or `:Silent grep` if you have a custom alias.
- **"`:cdo` says `no errors`."** Quickfix is empty. Re-fill with `:grep` or telescope `<C-q>`.
- **"`:cdo` modifies files I didn't expect."** That's the point — `:cdo` runs on every quickfix entry. Filter first, or use confirmation flag `gc`.
- **"`update` doesn't save."** `update` only saves if modified. If your `:s` matched no lines, no save needed.

## 9. Optional config edit

If you find yourself running `:silent grep` constantly, alias it:

```lua
vim.api.nvim_create_user_command("Grep", function(opts)
  vim.cmd("silent grep " .. opts.args)
  vim.cmd("copen")
end, { nargs = "+", complete = "shellcmd" })
```

Now `:Grep <pat>` runs silently and opens quickfix. ASK before adding (small but cluttery).

Or — equally useful — a `<Leader>sr` "search & replace word under cursor":

```lua
vim.keymap.set("n", "<Leader>sr", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("silent grep " .. vim.fn.shellescape(word))
  vim.cmd("copen")
  vim.fn.feedkeys(":cdo s/" .. word .. "/", "n")
end, { desc = "[S]earch and [R]eplace word under cursor" })
```

(Confirm `<Leader>s*` is unused before adding — your taxonomy doesn't claim it. ASK.)

## 10. Next-step upgrades

- **trouble.nvim** if quickfix UX feels too plain for diagnostics — your config has it. Test `:Trouble diagnostics toggle` and compare to `:copen`.
- **Diff-based refactor**: for refactors that aren't simple `:s`, use `:cdo` to run a complex macro or even a `:lua` snippet.
- **Drop to a real shell** for *truly mechanical* edits across thousands of files: `sd '...' '...' $(rg --files-with-matches '...')`. Vim's not always the right tool.

## 11. Connects to

Next: **Session 12 — C++ Workflow**. With foundations, config, LSP, treesitter, telescope, and quickfix in hand, time to assemble the pieces into a real C++ workflow.
