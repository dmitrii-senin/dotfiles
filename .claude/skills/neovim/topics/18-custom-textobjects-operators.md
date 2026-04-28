---
session: 18
title: Custom textobjects & operators
phase: F
prerequisites: [02, 03, 09]
duration: 60 min
---

# Session 18 — Custom Textobjects & Operators

## 1. Objective

Stop reaching for plugins for one-off textobject ideas. By the end of this session you can write a custom textobject (e.g. `iI` for "inside same-indent block") and a custom operator (e.g. `gx` to open URLs) using only built-in Neovim APIs and `~50 lines of Lua. You also know when to delegate to `mini.ai`.

## 2. Why it matters

Every team has a recurring textual pattern that no built-in textobject covers — a Python decorator, a C++ template parameter, a Rust attribute. Wrapping it in a textobject (`vai` then `c`/`d`/`y`) is the operator-grammar equivalent of giving the team a custom function name. Operators (`g@` + `opfunc`) let you compose any text transformation with any motion — once.

## 3. Core concepts

### Custom textobjects — three implementation paths

| Approach              | Where to put it                                   | Best for                           |
| --------------------- | ------------------------------------------------- | ---------------------------------- |
| `vim.keymap.set` in `o`/`x` mode invoking a Lua fn that selects a region with `nvim_buf_set_mark` + `:normal! v...` | `lua/custom/core/textobjects.lua` (loaded from `init.lua`) | One-off, project-specific |
| `mini.ai` custom spec | The `mini.ai` plugin spec in `lua/custom/plugins/` | Anything that fits a pattern: pairs, regex, treesitter |
| `nvim-treesitter-textobjects` capture | `~/.config/nvim/queries/<lang>/textobjects.scm` (Session 19) | Per-language structural objects |

### The opfunc machinery (custom operators)

The recipe (Neovim ≥ 0.7):

```lua
-- 1) Set up the keymap. `g@` waits for a motion, then calls `opfunc`.
vim.keymap.set('n', 'gx', function()
  vim.o.operatorfunc = 'v:lua.MyOperator'
  return 'g@'  -- returning 'g@' from <expr> map enters operator-pending
end, { expr = true, desc = 'Open URL operator' })

-- 2) Define the function. It receives a `motion` arg ("char"/"line"/"block").
function _G.MyOperator(motion)
  -- Read the marks `[ and `] which Vim sets to the motion's range.
  local s = vim.api.nvim_buf_get_mark(0, '[')
  local e = vim.api.nvim_buf_get_mark(0, ']')
  local lines = vim.api.nvim_buf_get_text(0, s[1]-1, s[2], e[1]-1, e[2]+1, {})
  local text  = table.concat(lines, '\n')
  vim.system({ 'open', text })
end
```

### Visual-mode operators

For `gx{motion}` and `{Visual}gx` to both work, also bind in visual:

```lua
vim.keymap.set('x', 'gx', ':<C-u>lua MyOperator(vim.fn.visualmode())<CR>', { silent = true })
```

Visual mode passes `'V'`, `'v'`, or `'<C-V>'` as the mode string instead of `"line"`/`"char"`/`"block"` — convert if your `opfunc` body cares.

## 4. Config notes

- Your `treesitter.lua` already loads `nvim-treesitter-textobjects` — you have `vaf`, `vif`, `vac`, `vic`, `]m`, `[m`, swap. Custom textobjects you add live alongside, not in place of these.
- No `lua/custom/core/textobjects.lua` exists yet. The Optional config edit below proposes creating it as the home for new textobjects/operators.
- `vim.keymap.set` is the only correct API for new mappings (your config uses it everywhere). Avoid `vim.api.nvim_set_keymap` for new code — it doesn't accept Lua callbacks naturally.

## 5. Concrete examples

### Example A — `iI` / `aI`: inside-same-indent text object

```lua
-- lua/custom/core/textobjects.lua
local function indent_object(around)
  local cur_line = vim.fn.line('.')
  local cur_indent = vim.fn.indent(cur_line)
  if cur_indent == 0 then return end
  local last = vim.fn.line('$')
  local s, e = cur_line, cur_line
  while s > 1 and vim.fn.indent(s - 1) >= cur_indent and vim.fn.getline(s - 1):match('%S') do
    s = s - 1
  end
  while e < last and vim.fn.indent(e + 1) >= cur_indent and vim.fn.getline(e + 1):match('%S') do
    e = e + 1
  end
  if around then
    if s > 1 then s = s - 1 end
    if e < last then e = e + 1 end
  end
  vim.cmd(('normal! %dGV%dG'):format(s, e))
end

vim.keymap.set({ 'o', 'x' }, 'iI', function() indent_object(false) end, { desc = 'inside indent' })
vim.keymap.set({ 'o', 'x' }, 'aI', function() indent_object(true)  end, { desc = 'around indent' })
```

Try `viI` inside any nested Python block — the whole block at this indent level highlights. `daI` deletes the block plus its outer fence lines.

### Example B — `gx` operator: open URLs/paths

```lua
local function open_url_op(motion)
  local s = vim.api.nvim_buf_get_mark(0, '[')
  local e = vim.api.nvim_buf_get_mark(0, ']')
  local text = table.concat(
    vim.api.nvim_buf_get_text(0, s[1]-1, s[2], e[1]-1, e[2]+1, {}), '')
  vim.system({ 'open', text }, { detach = true })
end
_G.MyOpenUrl = open_url_op

vim.keymap.set('n', 'gx', function()
  vim.o.operatorfunc = 'v:lua.MyOpenUrl'
  return 'g@'
end, { expr = true, desc = 'Open with system handler' })
vim.keymap.set('x', 'gx', ":<C-u>lua MyOpenUrl(vim.fn.visualmode())<CR>",
  { silent = true, desc = 'Open selection' })
```

Now `gxiW` opens the URL under cursor, `vipgx` opens whatever's selected.

> **Note:** Neovim 0.10+ ships `gx` already (calls `:!open`). If your `gx` works, override carefully — or pick a different LHS like `<Leader>cu`.

### Example C — When to use `mini.ai` instead

```lua
-- Inside a mini.ai opts table:
require('mini.ai').setup({
  custom_textobjects = {
    F = require('mini.ai').gen_spec.treesitter({  -- aF / iF — function via TS
      a = '@function.outer', i = '@function.inner',
    }),
    o = require('mini.ai').gen_spec.pair('"', '"'),  -- ao / io
  },
})
```

If the textobject fits a pair, regex, or treesitter capture: `mini.ai` is faster to write. If it needs custom logic (like indent traversal): write it with the `vim.keymap` approach.

## 6. Shortcuts to memorize

### ESSENTIAL
`g@ + 'opfunc'  vim.keymap.set({'o','x'}, ...)  vim.api.nvim_buf_get_mark(0,'[')  v:lua.<global_fn>`

### OPTIONAL
`vim.api.nvim_buf_get_text  vim.fn.visualmode()  vim.cmd('normal! ...')`

### ADVANCED
`mini.ai gen_spec.treesitter / .pair / .function_call  custom_textobjects`

## 7. Drills

Run each in your own Neovim. Confirm with `done N` / `stuck N <details>`.

1. Create `lua/custom/core/textobjects.lua` with Example A. Add `require('custom.core.textobjects')` to your `init.lua`. Restart. Verify `viI` selects an indent block in any Python file.
2. Add Example B's `gx` operator (use `<Leader>cu` if `gx` is taken). Place cursor on a URL in any text file. Verify `<Leader>cuiW` opens it.
3. Write a custom textobject `i;` / `a;` for "between semicolons on this line" (delete-friendly: `da;` should leave one `;`). Use `f;`/`F;` to find the bounds.
4. Write a tiny operator `gw` that wraps the operated range in backticks (`` ` ``). Test: `gwiw` wraps the current word.

## 8. Troubleshooting

- **"`g@` does nothing."** You forgot to set `vim.o.operatorfunc` *before* returning `g@`. The `<expr>` map runs in two phases: the function executes, sets the global, then `g@` enters operator-pending and waits for a motion.
- **"`v:lua.MyOpenUrl` errors with `E5560`."** `_G.MyOpenUrl` must be set before the keymap fires. Define the function module-load early.
- **"My textobject works in visual but not as `d{obj}`."** You bound only `x` mode, not `o`. Use `{ 'o', 'x' }`.
- **"Range is off-by-one."** `nvim_buf_get_text` is **exclusive** end column on the column dimension, **inclusive** end on rows. Check your indices.

## 9. Optional config edit

Propose creating `~/x/dotfiles/.config/nvim/lua/custom/core/textobjects.lua` (Example A above) and adding `require('custom.core.textobjects')` to `~/x/dotfiles/.config/nvim/init.lua` after the `core/keymaps` require. ASK before writing.

## 10. Next-step upgrades

- Move from per-language textobjects in Lua → treesitter `.scm` queries (Session 19). Same end result, scoped per-language, no Lua per-binding.
- Once you have 5+ custom textobjects, group them in `lua/custom/core/textobjects/` as one file per concept.

## 11. Connects to

Next: **Session 19 — Treesitter queries & plugin development.** Custom textobjects in pure Lua reach a ceiling at "depends on syntax". Treesitter queries pierce that ceiling: write captures in `.scm` and they apply per-language with zero Lua.
