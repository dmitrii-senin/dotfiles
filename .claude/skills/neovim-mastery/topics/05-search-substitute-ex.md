---
session: 05
title: Search, Substitute, Ex Commands
phase: A
prerequisites: [2, 3]
duration: 60 min
---

# Session 05 — Search, Substitute, Ex Commands

## 1. Objective

Drive bulk edits with `/`, `:s`, `:g`, `:norm`, `:argdo`. Master very-magic mode (`\v`) and live preview (`inccommand=nosplit` is already on). After this session, "rename a thing across 200 files" is a single-line ex command.

## 2. Why it matters

C++: rename a method across a header + 5 sources. Python: convert `print x` to `print(x)` (Python 2 → 3). Rust: turn `unwrap()` to `expect("…")` with location-aware messages. All ex-command territory.

## 3. Core concepts

### Search

| Key   | Action                                                |
| ----- | ----------------------------------------------------- |
| `/`   | search forward (then enter pattern)                   |
| `?`   | search backward                                        |
| `n N` | repeat forward / backward                              |
| `*`   | search forward for word under cursor (whole word)      |
| `g*`  | search forward for word under cursor (substring)       |
| `#`   | backward for word under cursor                         |
| `:nohlsearch` (`:noh`) | clear highlights (your `<Esc>` does this) |
| `gn`  | operate on next search match (e.g. `dgn`, `cgn`)       |

`/<pattern>` accepts standard regex by default. **Very-magic mode** (`\v`) makes regex behave like PCRE — almost always what you want.

```
/\v(foo|bar)_id     " matches foo_id or bar_id
/\v\d+              " one or more digits
/\v\<\w+\>          " whole-word \w+ (very-magic word boundaries)
```

### Substitute

```
:[range]s/pattern/replacement/flags
```

Ranges:
- *(empty)* current line
- `%` whole file
- `'<,'>` last visual selection
- `5,12` lines 5–12
- `'a,'b` mark `a` to mark `b`
- `.,$` here to end

Flags: `g` all on line · `c` confirm · `i` case-insensitive · `e` no error if no match · `n` count only.

`inccommand = nosplit` (your config) live-previews substitutions as you type.

### Global commands `:g` and `:v`

```
:g/pattern/cmd     " run :cmd on every line matching pattern
:v/pattern/cmd     " run :cmd on every line NOT matching (inverse)
```

Examples:
- `:g/^$/d` — delete all blank lines.
- `:g/TODO/p` — print every line containing TODO (silly without context).
- `:g/^class /norm yyP` — duplicate every class declaration.
- `:g/foo/d` — delete every line containing `foo`.

### `:norm`

```
:[range]norm <keys>     " execute <keys> as normal-mode for each line in range
```

Examples:
- `:%norm A;` — append `;` to every line.
- `:'<,'>norm @a` — run macro `a` on each line in visual selection.
- `:g/^const/norm 0w~` — find lines starting with `const`, toggle case of the word after.

### `:args` and `:argdo`

```
:args **/*.cpp                " set arglist to all .cpp files (recursive glob)
:argdo %s/oldName/newName/ge | update    " run substitute + save in each
```

Variants: `:bufdo`, `:windo`, `:tabdo`, `:cdo` (over quickfix), `:cfdo` (over files in quickfix).

`update` (vs `write`) only writes if modified — safer for batch.

### Command-line history (`q:`)

`q:` opens a window of your last `:` commands. Navigate, edit, hit `<CR>` to re-run. Game-changer.

`q/` and `q?` do the same for search history.

## 4. Config notes

- `options.lua:42`: `grepprg = "rg --vimgrep"`. So `:grep <pattern>` invokes ripgrep.
- `options.lua:41`: `grepformat = "%f:%l:%c:%m"` — matches `rg --vimgrep` output.
- `options.lua:48`: `inccommand = nosplit` — substitution preview live.
- `options.lua:43-44`: `ignorecase` + `smartcase` — searches are case-insensitive UNLESS the pattern contains uppercase.
- Your `<Esc>` map clears `hlsearch` (line 33).

## 5. Concrete examples

### Rename across one file

```
:%s/\vrequire\(['"]custom\.utils\.globals['"]\)/-- moved to lazy spec/g
```
Replaces every `require("custom.utils.globals")` (or with single quotes) with a comment.

### Rename across multiple files (project-wide)

```
:args lua/custom/plugins/*.lua
:argdo %s/\vlocal\s+conform\s*=\s*require\(['"]conform['"]\)/local conform = require('conform') -- audited/ge | update
```

This is the **scripted refactor pattern** — `:args` to set the file list, `:argdo` to run a substitute in each, `update` to save.

### Confirm substitutions one by one

```
:%s/\vold_name/new_name/gc
```
Each match prompts: `y` yes, `n` no, `a` all, `q` quit, `l` last (do this one and stop), `<C-e>`/`<C-y>` scroll.

### Delete all comment-only lines from a Lua file

```
:g/^\s*--/d
```

### Sort and unique the visible lines

```
:'<,'>sort u
```

(`u` flag = remove duplicates.)

### Operate on search matches with `gn`

`/foo` then `cgn` — change the next `foo` match. Now `.` repeats the substitution. (Combined with `*`, this beats `:s` for one-off renames.)

## 6. Shortcuts to memorize

### ESSENTIAL
`/  ?  n N  *  #  :nohlsearch  :s  :%s  :s/pat/rep/gc  cgn  q:  q/`
`:g/pat/cmd  :v/pat/cmd  :%norm <keys>  :argdo cmd | update`
`:grep <pat>` (uses `grepprg` → ripgrep) `:cnext :cprev :copen`

### OPTIONAL
`gn dgn ygn  :let @/ = ''  (clear search register)
:cdo s/.../.../g | update  (over quickfix)
:cfdo s/.../.../g | update  (over files in quickfix)
:vimgrep /pat/g **/*.lua    (built-in grep — slower than rg, but no external dep)`

### ADVANCED
`:[range]g/pat/normal! @a  (run a macro on matching lines)
:%s//\=submatch(0).'X'/g  (substitution with Vimscript expression)
:argadd  :argdelete  :ar (show arglist)`

## 7. Drills

1. In `lspconfig.lua`, find every line with `vim.lsp.config` using `:g/vim\.lsp\.config/p` — confirm count = 4.
2. Practice substitute confirm: in any file, `:%s/\vlocal/LOCAL/gc` — accept some, reject others, then `u` to undo.
3. `:args lua/custom/plugins/*.lua` then `:argdo %s/foo/foo/g | update` (no-op, just to feel it). Then `:ar` to see the arglist.
4. `q:` — open the command-line history. Navigate with `j/k`, edit a line, `<CR>` to re-run.
5. `:norm` drill: open a file with several lines. Use `V` to select lines, then `:norm A;` — appends `;` to each.

## 8. Troubleshooting

- **"`:s/foo/bar` only changes one match per line."** Add `g` flag: `:s/foo/bar/g`.
- **"`:argdo` complains about modified buffers."** Use `:set hidden` (likely already on in your config) or save before running. Use `update` instead of `write` to skip unmodified buffers.
- **"My very-magic regex doesn't match."** Backslash is literal in `\v` mode for some chars. Use `:help magic` for the table. Common gotcha: `\<` and `\>` are still needed for word boundaries.
- **"`:grep` opens a useless empty buffer."** Your `grepprg` is set to `rg --vimgrep`, but `:grep` sometimes opens the shell output buffer. Use `:silent grep <pat>` and then `:copen` to view results in quickfix.

## 9. Optional config edit

None required, but two quality-of-life enhancements worth knowing about:

1. **Map `<Leader>sr` for "search and replace word under cursor across project":**
   ```lua
   vim.keymap.set("n", "<Leader>sr", function()
     local word = vim.fn.expand("<cword>")
     vim.cmd("silent grep " .. vim.fn.shellescape(word))
     vim.cmd("copen")
     vim.fn.feedkeys(":cdo s/" .. word .. "/", "n")
   end, { desc = "Search & replace word across project" })
   ```
   But — this collides with your `<Leader>s*` namespace if reserved. Check `references/keymaps.md` first. (Currently `<Leader>s*` is unused; safe to add.)
2. **Add `:Q` / `:Wq` aliases** for typo tolerance: `vim.cmd("command! W w")` etc. Optional taste call.

## 10. Next-step upgrades

- Once `:cdo`/`:argdo` patterns are reflex, scripted refactors stop feeling scary.
- Pair with telescope's `live_grep` (Session 10) → press `<C-q>` in the picker to send results to quickfix → `:cdo s/.../.../g | update`. This is the canonical "find-and-replace across project" workflow.
- For *truly* mechanical edits (regex over thousands of files), drop into a real shell with `sd` or `sed -i`. Vim's not always the right hammer.

## 11. Connects to

Next: **Session 6 — Lua Config Structure**. You're now fluent in Vim's editing primitives. Time to look at how to organize your *config* the way you organize your edits — small, composable, intentional.
