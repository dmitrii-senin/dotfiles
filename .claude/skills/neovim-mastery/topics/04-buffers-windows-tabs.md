---
session: 04
title: Buffers, Windows, Tabs
phase: A
prerequisites: [1]
duration: 30 min
---

# Session 04 — Buffers, Windows, Tabs

## 1. Objective

Build the right mental model: **buffers are files in memory, windows are viewports onto buffers, tabs are layouts of windows.** After this session, you'll never use a tab where a buffer would do, and you'll understand why "I have 50 tabs open" is an antipattern in Neovim.

## 2. Why it matters

The single most common Neovim mistake among VSCode/Sublime refugees is treating tabs as "open files." Vim has *thousands of buffers* available with `<S-l>` / `<S-h>` / `:b <name>`. Tabs are a layout *feature*, not a file-management feature. Once this clicks, you stop tab-juggling and start buffer-jumping.

## 3. Core concepts

### Buffer
A file loaded into memory. May or may not be displayed in any window. List with `:ls` (or `:buffers`). Switch with `:b <substring>` (tab-completes), `:b#` (alternate), `<S-l>`/`<S-h>` (your config), or `[b`/`]b`.

### Window
A viewport that shows a buffer. Split with `<C-w>s` (horizontal) or `<C-w>v` (vertical), or your config maps `<Leader>ws`/`<Leader>wv`. Close with `<C-w>c` or `<Leader>wd`. Navigate with `<C-w>hjkl` (your config: plain `<C-h/j/k/l>` thanks to `remap=true`).

### Tab
A *layout* of windows. Useful for "I want a debug layout (3 windows)" vs "I want a code-review layout (2 windows)". NOT useful for "I have 12 files open." Open with `<Leader><tab><tab>`, navigate with `<Leader><tab>]`/`[`.

### Diagram

```
TAB 1 (debug layout)             TAB 2 (review layout)
┌──────────┬──────────┐          ┌────────────────────┐
│ buf:src  │ buf:test │          │ buf:diff           │
├──────────┴──────────┤          ├────────────────────┤
│ buf:dap-ui          │          │ buf:notes          │
└─────────────────────┘          └────────────────────┘
   3 windows, 3 bufs                2 windows, 2 bufs

But ALL buffers are accessible from EITHER tab via :b <name>.
```

## 4. Config notes

Your `keymaps.lua` already establishes the right mental model. Notable maps:

- **Buffers:** `<S-h>`/`<S-l>` (`:bprevious`/`:bnext`), `[b`/`]b` (alias), `<Leader>bb` (alt buffer = `:e #`), <code>&lt;Leader&gt;`</code> (also alt), `<Leader>bD` (delete buffer + window).
- **Windows:** `<Leader>ws/wv/wd` (split below/right/close), `<C-h/j/k/l>` to navigate (with `remap=true` so the zellij-nav plugin can intercept and jump to terminal panes too).
- **Resize:** `<M-S-Up/Down/Left/Right>` for height/width resize.
- **Tabs:** `<Leader><tab><tab>` new, `<Leader><tab>]`/`[` next/prev, `<Leader><tab>l/f/o/d` last/first/close-other/delete.

`options.lua` sets `splitbelow` and `splitright` so splits land where you expect (new pane goes right or below, never above/left). And `laststatus = 3` gives you a *single global statusline* across all windows — a small but meaningful clutter reduction.

## 5. Concrete examples

### Open three files, swap between them without tabs

```
:e lua/custom/plugins/lspconfig.lua
:e lua/custom/plugins/dap.lua
:e lua/custom/plugins/conform.lua
```

Now `:ls` shows three buffers. Use `<S-h>`/`<S-l>` to cycle. Or `:b lsp<Tab>` to fuzzy-jump (tab-completion).

### Build a 4-window layout

In a single tab:
- `<Leader>wv` → split right.
- `<Leader>ws` → split below in the right pane.
- `<C-h>` → back to left, `<Leader>ws` → split below in the left pane.

Now you have 4 panes. Open different buffers in each with `:b <name>`.

### Zoom a window

`<C-w>o` closes all other windows, leaving only the current one. Or `<C-w>_` (max height) and `<C-w>|` (max width) — useful for temporarily zooming.

### Window equalize

`<C-w>=` makes all windows equal size.

## 6. Shortcuts to memorize

### ESSENTIAL
`:e <file>  :ls  :b <name>  :b#  :bd  <S-h> <S-l>  [b ]b  <Leader>bb`
`<Leader>ws <Leader>wv <Leader>wd`
`<C-h> <C-j> <C-k> <C-l>`
`<C-w>= <C-w>o <C-w>_  <C-w>|`

### OPTIONAL
`<Leader><tab><tab> <Leader><tab>] <Leader><tab>[ <Leader><tab>o`
`<C-w>r` (rotate windows)  `<C-w>x` (swap with adjacent)
`:bufdo cmd`  `:windo cmd`  `:tabdo cmd`

### ADVANCED
`:b ##` (alt buffer with full path), `<C-^>` (same as `<C-6>` = alt buffer), `:vsp +<linenr> <file>` (open file at specific line in vertical split).

## 7. Drills

1. Open 5 files via `:e`. Use `:ls` to view the list. Switch between them with `<S-l>`/`<S-h>` and confirm `<S-h>` wraps from buffer 1 back to buffer 5.
2. Use `:b lsp<Tab>` — confirm tab-completion fills `lspconfig.lua` (or offers candidates).
3. Build a 3-window layout with `<Leader>wv` then `<Leader>ws`. Cycle with `<C-h/j/k/l>`. Close one with `<Leader>wd`.
4. Open two files with `:e a.lua` and `:e b.lua`. Use `<Leader>bb` (or `:b#`) to flip between them. This is the *fastest* file-switch in Vim — internalize it.
5. Open a file. Run `:bufdo set number` (sets `number` in every buffer). Confirm with `:ls`. Then `:bufdo set nonumber!`.

## 8. Troubleshooting

- **"`:b <name>` says `E94: No matching buffer`."** The file isn't loaded. Use `:e <file>` first. Or `:b <Tab>` to see what's available.
- **"`:bd` closes the window too."** That's the default. Use `:bp | bd #` to switch to previous buffer first, then delete the original. Or `:bdelete!` to force.
- **"`<C-h>` doesn't move me to the left window."** Could be the terminal eating `<BS>` (some terminals send `^H` for both). Verify with `:nmap <C-h>`. Your `zellij-nav` plugin also intercepts these — confirm zellij is configured to pass them through.
- **"My splits go in the wrong direction."** Check `splitbelow` and `splitright` are set (your config has both).

## 9. Optional config edit

None for this session — your buffer/window/tab maps are already complete.

If you ever feel `:ls` output is awkward, consider `telescope.builtin.buffers` (often mapped to `<Leader>fb` — verify via `telescope.lua`). Treat it as an *optional* upgrade, not a replacement for `:b<Tab>`.

## 10. Next-step upgrades

- Once buffers replace tabs in your head, you'll feel weirdly free. Most editors over-tax tabs because they have no other concept.
- Combine with `:argdo` (Session 5) for cross-buffer scripted edits.
- For visual buffer browsing with previews, `<Leader>fb` (telescope) is the right tool — but `:b<Tab>` remains faster for known names.

## 11. Connects to

Next: **Session 5 — Search, Substitute, Ex Commands**. Now that you can navigate and select, it's time to drive bulk transformations.
