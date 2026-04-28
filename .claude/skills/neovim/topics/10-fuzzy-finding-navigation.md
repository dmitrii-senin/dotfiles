---
session: 10
title: Fuzzy Finding & Project Navigation
phase: C
prerequisites: [5, 8]
duration: 45 min
---

# Session 10 — Fuzzy Finding & Project Navigation

## 1. Objective

Be fluent with telescope pickers — files, grep, buffers, symbols, references — and the `:grep + quickfix` fallback for when telescope is the wrong hammer. After this session, "find that thing" takes < 3 seconds in a million-line repo.

## 2. Why it matters

C++ codebases are big. Python monorepos sprawl. Rust workspaces have many crates. Without a fuzzy finder, you become a Linux superuser-by-default (cd, ls, grep). Telescope keeps your hands on the keyboard and your context in Neovim.

## 3. Core concepts

### What telescope is

A picker UI built on Neovim's window/buffer model. A picker has:
- **Source** — what to list (files, buffers, lines, LSP symbols, …).
- **Sorter** — how to fuzzy-rank.
- **Previewer** — what to show on the right (file content with highlight, diff, etc.).
- **Mappings** — actions in the picker buffer.

Pickers come from `telescope.builtin.<name>` (built-in) or extensions (`require("telescope").load_extension("foo")`).

### Built-in pickers (the ones you'll actually use)

| Picker                            | Purpose                                                                  |
| --------------------------------- | ------------------------------------------------------------------------ |
| `find_files`                      | Files in cwd (or `:Telescope find_files cwd=...`)                        |
| `live_grep`                       | Ripgrep-backed live search across project                                |
| `grep_string`                     | Grep for word under cursor (or arg)                                      |
| `buffers`                         | Open buffers                                                              |
| `oldfiles`                        | Recent files (uses `:oldfiles`)                                           |
| `current_buffer_fuzzy_find`       | Fuzzy lines in current buffer                                            |
| `lsp_definitions`                 | Definitions (used by your `gd`)                                          |
| `lsp_references`                  | References (used by your `grr`)                                          |
| `lsp_implementations`             | Implementations (used by your `gri`)                                     |
| `lsp_type_definitions`            | Type definitions (used by your `<Leader>ft`)                              |
| `lsp_document_symbols`            | Symbols in current file (used by your `gO`)                              |
| `lsp_dynamic_workspace_symbols`   | Symbols across project (used by your `gW`)                                |
| `diagnostics`                     | Diagnostics with preview                                                  |
| `git_files`                       | Files tracked by git                                                      |
| `git_status`                      | Git status (stage/unstage from picker)                                   |
| `keymaps`                         | All your keymaps (great discoverability)                                 |
| `help_tags`                       | `:help` tags                                                              |
| `commands`                        | All ex commands                                                          |
| `man_pages`                       | Man pages                                                                 |

### Picker mappings (the keys that matter inside the picker)

| Keys           | Action                                                |
| -------------- | ----------------------------------------------------- |
| `<C-n>`/`<C-p>`/`<Down>`/`<Up>` | Next/prev result                       |
| `<CR>`         | Open selected (in current window)                     |
| `<C-x>`        | Open in horizontal split                              |
| `<C-v>`        | Open in vertical split                                |
| `<C-t>`        | Open in new tab                                       |
| `<C-q>`        | Send all results to quickfix (game-changer)           |
| `<M-q>` / `<C-Q>` | Send selected to quickfix                          |
| `<Tab>`        | Multi-select toggle (then `<C-q>` for selection)      |
| `<Esc>` / `<C-c>` | Close picker                                       |
| `?`            | Show all picker mappings                              |

### Telescope vs `:grep`

- **Telescope live_grep**: interactive, fuzzy, previews. Best for "I'll know it when I see it."
- **`:grep <pattern>` then `:copen`**: scripted, repeatable, works without a UI. Best for "I know exactly what I want, and I want to drive `:cdo` next."

Your config sets `grepprg = rg --vimgrep` and `grepformat = %f:%l:%c:%m` — `:grep` invokes ripgrep and parses its output into the quickfix list.

### Telescope settings worth knowing

(Default unless your `telescope.lua` overrides — read it on demand.)

```lua
require("telescope").setup({
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    layout_strategy = "horizontal",
    layout_config = { horizontal = { preview_width = 0.55 } },
    file_ignore_patterns = { "%.git/", "node_modules/", "target/" },
    mappings = { i = { ["<C-h>"] = "which_key" } },
  },
  pickers = {
    find_files = { hidden = true },
    live_grep = { additional_args = function() return { "--hidden" } end },
  },
})
```

## 4. Config notes

Read `~/x/dotfiles/.config/nvim/lua/custom/plugins/telescope.lua` to see your specific picker maps. Your `lspconfig.lua:17-22` already wires LSP defaults to telescope pickers. Your global keymaps probably include `<Leader>ff`, `<Leader>fg`, `<Leader>fb` (verify in `telescope.lua`).

`grepprg = rg --vimgrep` (`options.lua:42`) means `:grep <pat>` ↔ `rg --vimgrep <pat>` ↔ feeds quickfix.

## 5. Concrete examples

### Find a file by partial name

`<Leader>ff` (telescope find_files). Type `lspc` — narrows to `lspconfig.lua`. `<CR>` to open.

### Live-grep then send to quickfix for batch refactor

`<Leader>fg` → type `vim\.lsp\.config` → results stream live. `<C-q>` to send all to quickfix. Now in normal Neovim:

```
:cdo s/vim\.lsp\.config/vim.lsp.config -- audited/g | update
```

(Hypothetical example; the point is the pipeline.)

### Find by symbol (LSP-backed)

`gW` (your map → `lsp_dynamic_workspace_symbols`). Type a function name. Picker shows matches across the project with previews. `<CR>` to jump.

### Switch buffers visually

`<Leader>fb` (telescope buffers, if mapped). Or stick with `<S-l>`/`<S-h>` for known recent buffers — faster.

### Ad-hoc: `:Telescope <picker_name>`

You don't need a keymap for every picker. `:Telescope keymaps` finds your own mappings. `:Telescope help_tags` searches `:help`. `:Telescope commands` lists ex commands.

## 6. Shortcuts to memorize

### ESSENTIAL
Your maps (verify in `telescope.lua`):
`<Leader>ff` files · `<Leader>fg` live grep · `<Leader>fb` buffers · `<Leader>fs` document symbols · `<Leader>fd` diagnostics · `<Leader>fh` help · `<Leader>fk` keymaps
LSP overrides: `gd  grr  gri  gO  gW  <Leader>ft`

In picker:
`<C-q>` send all to quickfix · `<M-q>` send selection · `<Tab>` multi-select · `<C-v>` vsplit · `<C-x>` hsplit

### OPTIONAL
`:Telescope grep_string` — grep for word under cursor (skip the typing)
`:Telescope current_buffer_fuzzy_find` — fuzzy lines in current buffer (mini-search)
`:Telescope oldfiles` — recents
`:Telescope resume` — re-open the last picker with the same query

### ADVANCED
Custom pickers via `require("telescope.pickers").new({...}, {...}):find()`
[`fzf-lua`](https://github.com/ibhagwan/fzf-lua) as an alternative, faster on huge repos. Don't switch unless telescope feels slow on a repo.

## 7. Drills

1. `<Leader>ff` and find any plugin file (e.g. `dap.lua`). Open with `<CR>`.
2. `<Leader>fg`, search for `vim.lsp`. Use `<C-q>` to send all hits to quickfix. Run `:copen`. Navigate with `]q`/`[q`.
3. In `lspconfig.lua`, place cursor on `vim.lsp.config`. Run `:Telescope grep_string` — should pre-fill with `vim.lsp.config`.
4. `:Telescope keymaps` — search for `<Leader>x`. Confirm you see your `<Leader>xf`/`<Leader>xx` maps.
5. `:Telescope resume` after step 4 — should re-open the same picker with the same query. Useful after accidentally `<Esc>`-ing out.

## 8. Troubleshooting

- **"Live-grep returns nothing on a big repo."** Check `rg` is installed: `which rg`. Check ignored patterns (`.gitignore` is respected by default). Use `:Telescope live_grep additional_args=function() return {"--no-ignore"} end` to override.
- **"Telescope is slow."** Confirm `fd` is installed for find_files (`which fd`). Otherwise telescope falls back to slower native traversal. For very large repos, consider `fzf-lua`.
- **"Picker doesn't preview."** Check `:Telescope find_files` works (basic test). Check `bat` or treesitter is loaded for preview highlighting.
- **"`<C-q>` doesn't send to quickfix."** Confirm the mapping in `telescope.lua` setup. Some configs override defaults.

## 9. Optional config edit

A common QoL tweak — add a "find in plugin spec dir" map:

```lua
vim.keymap.set("n", "<Leader>fp", function()
  require("telescope.builtin").find_files({
    cwd = vim.fn.stdpath("config") .. "/lua/custom/plugins",
    prompt_title = "Plugin specs",
  })
end, { desc = "[F]ind [P]lugin spec" })
```

ASK before adding. Belongs in `keymaps.lua` or a small `lua/custom/plugins/telescope.lua` extension.

## 10. Next-step upgrades

- **Pair with quickfix discipline (Session 11).** `<C-q>` from telescope into quickfix is the canonical "find → batch-edit" pipeline.
- **`fzf-lua`** if telescope feels slow. It's faster but loses some preview polish. Switch only if telescope is a bottleneck.
- **Telescope extensions** worth knowing (don't install yet): `telescope-frecency` (recent + frequency), `telescope-undo` (undo tree picker). Optional taste.

## 11. Connects to

Next: **Session 11 — Quickfix, Location Lists, Project Refactor**. You've sent results to quickfix. Now let's drive multi-file edits with `:cdo`/`:cfdo`.
