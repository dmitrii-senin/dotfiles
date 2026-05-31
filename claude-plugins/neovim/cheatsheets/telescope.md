# telescope pickers and patterns

## Core pickers (your keymaps)

| Key | Picker | Description |
|-----|--------|-------------|
| `<Leader>ff` | `find_files` | find files (respects .gitignore) |
| `<Leader>fs` | `live_grep` | grep across project (ripgrep) |
| `<Leader>fb` | `buffers` | open buffers |
| `<Leader>fh` | `help_tags` | vim help tags |
| `<Leader>fd` | `diagnostics` | all diagnostics |
| `<Leader>fk` | `keymaps` | all keymaps |
| `<Leader>fm` | `man_pages` | man pages |
| `<Leader>f'` | `marks` | marks |
| `<Leader>fr` | `registers` | registers |
| `<Leader>fc` | `find_files` | neovim config files (cwd = stdpath config) |
| `<Leader>fp` | `find_files` | plugin files (cwd = lazy data dir) |

## LSP pickers (set on LspAttach)

| Key | Picker | Description |
|-----|--------|-------------|
| `gd` | `lsp_definitions` | go to definition |
| `grr` | `lsp_references` | find references |
| `gri` | `lsp_implementations` | find implementations |
| `gO` | `lsp_document_symbols` | document symbols |
| `gW` | `lsp_dynamic_workspace_symbols` | workspace symbols |
| `<Leader>ft` | `lsp_type_definitions` | type definition |

## Insert-mode actions (inside picker)

| Key | Action |
|-----|--------|
| `C-n` / `C-p` | navigate results down / up |
| `<CR>` | open in current window |
| `C-s` | open in horizontal split (your override; default C-x) |
| `C-v` | open in vertical split |
| `C-t` | open in new tab |
| `C-u` / `C-d` | scroll preview up / down |
| `<Esc>` | close telescope |

Normal mode: press `<Esc>` once to enter normal mode in picker, again to close.

## Multi-select and quickfix

| Key | Action |
|-----|--------|
| `Tab` | toggle selection on current item + move down |
| `S-Tab` | toggle selection on current item + move up |
| `C-q` | send all results to quickfix |
| `M-q` | send selected items to quickfix |

After sending to quickfix: `:copen`, `]q`/`[q` to navigate, `:cdo` to batch-modify.

## Live grep tips

### Regex patterns in live_grep

```
foo.*bar         foo followed by bar on same line
\bword\b         exact word match
foo|bar          foo or bar
^fn              lines starting with fn
TODO:.*\bfix\b   TODO lines containing fix
```

### File type filtering with glob

Type your search query, then append glob filters:

```
-- In telescope prompt:
search_term --glob *.cpp         only C++ files
search_term --glob !test_*       exclude test files
search_term -g '*.{h,hpp,cpp}'   C++ headers and sources
search_term -t cpp               ripgrep type filter
```

You can also call with args from Lua:
```lua
require("telescope.builtin").live_grep({
  glob_pattern = "*.cpp",
})
```

### Grep for exact string (no regex)

```lua
require("telescope.builtin").grep_string({ search = "exact match" })
```

Or use `live_grep` and prefix with `\Q` to disable regex (ripgrep `--fixed-strings`):
```
-- In prompt, use -F flag by passing additional_args:
require("telescope.builtin").live_grep({
  additional_args = { "--fixed-strings" },
})
```

## Config notes

- Sorter: fzf-native (`telescope-fzf-native`), `smart_case`, fuzzy matching.
- `path_display = "smart"` -- shows relative paths, truncates common prefixes.
- Horizontal split override: `C-s` instead of default `C-x` (both insert and normal mode).

## Useful ad-hoc pickers

```lua
-- grep in current buffer
:Telescope current_buffer_fuzzy_find

-- search git commits
:Telescope git_commits

-- search git branches
:Telescope git_branches

-- search git status (changed files)
:Telescope git_status

-- search colorschemes
:Telescope colorscheme

-- resume last picker
:Telescope resume
```
