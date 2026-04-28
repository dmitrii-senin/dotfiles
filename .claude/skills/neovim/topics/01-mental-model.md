---
session: 01
title: Mental Model & Modal Editing
phase: A
prerequisites: []
duration: 30 min
---

# Session 01 — Mental Model & Modal Editing

## 1. Objective

Internalize Vim's modal grammar so every keystroke later in the curriculum has a parseable structure. After this session you can describe what an "operator + motion" does without hesitation and read any line of `keymaps.lua` aloud.

## 2. Why it matters

Every advanced editing trick in C++/Python/Rust workflows — refactoring a `std::vector<T>`, reformatting a Python docstring, swapping match arms in Rust — is just composed operators and motions. If the grammar isn't internal, every shortcut feels like memorization. With it, new shortcuts derive themselves.

## 3. Core concepts

**Modes (the only ones that matter day-to-day):**

| Mode         | Triggered by         | What you do                                       |
| ------------ | -------------------- | ------------------------------------------------- |
| Normal       | `<Esc>`              | Move, operate, compose. Default home.             |
| Insert       | `i`/`a`/`o`/`A`/`I`/`O` | Type characters. Avoid living here.            |
| Visual       | `v`/`V`/`<C-v>`      | Select, then operate.                             |
| Operator-pending | After an operator (`d`, `c`, `y`, `gq`) | Vim is waiting for a motion.   |
| Command-line | `:`/`/`/`?`          | Run an ex command or search.                      |
| Terminal     | `:term` then `i`     | Send keys to a real shell. Leave with `<C-\><C-n>`. |

**The grammar:**

```
[count] operator [count] motion
```

Examples:
- `d2w` — delete 2 words.
- `c$` — change to end of line.
- `gqap` — `gq` (format) `ap` (a paragraph).
- `yi"` — yank inside `"…"`.
- `=ip` — re-indent inner paragraph.

**Operators (Tier ESSENTIAL):**
- `d` delete · `c` change · `y` yank · `gq` format · `=` indent · `>` shift right · `<` shift left.

**Motions** drive operators. They're covered in Session 2.

**The dot command (`.`)** repeats the last *change*. The single most undervalued key in Vim. Make every edit `.`-friendly.

**Counts** are a multiplier. `3d2w` = "do `d2w` three times" = delete 6 words.

## 4. Config notes

- Your `options.lua` already sets `g.mapleader = ' '` and `g.maplocalleader = '\\'`. These define the mental "extra modes" of `<Leader>` and `<localleader>`.
- `inccommand = nosplit` (line 48) lets you preview `:s/old/new/` substitutions live. Worth knowing because it makes Session 5 land harder.
- `clipboard = unnamedplus` (line 15) means yanks land in the system clipboard. This is a *choice* — many Vim users prefer to keep the system clipboard separate. The user has chosen integration.

## 5. Concrete examples

Open a Lua file in your config, e.g. `~/x/dotfiles/.config/nvim/lua/custom/core/keymaps.lua`. Try:

1. Place cursor on `map` on line 2. Type `*` — search forward for the next occurrence. Type `n` to jump again. `N` for previous.
2. Place cursor inside a `"…"` string. Type `ci"` — clears the string, leaves you in insert. Type a new value. `<Esc>`.
3. Position on a `function`. Type `}` — jump down to the next blank line. `{` jumps back. (Paragraph motion — not always perfect for code but it's the foundation `]m` improves on in Session 9.)
4. Type `dd` to delete a line, `p` to paste below. Or `dw` to delete a word, `p` to paste *after* the cursor (use `P` to paste *before*).
5. Make any small edit. Type `.` — Vim repeats it.

## 6. Shortcuts to memorize

### ESSENTIAL (memorize this week)
`<Esc>  i a o A I O  v V <C-v>  hjkl  w b e  0 ^ $  gg G  /  ?  n N  *  d y c  p P  u <C-r>  .  :`

### OPTIONAL (memorize after a week of use)
`fF tT  ;,  dt) ci( ci{ yi[  zz zt zb  <C-o> <C-i>  '' g; g,  m<x> '<x>`

### ADVANCED (later)
`q<x> @<x>  "<reg>  :norm  :argdo  :cdo  g/pat/cmd  :%!cmd`

## 7. Drills

Run each in your own repo. Confirm with `done N` or `stuck N <details>`.

1. Open any `.lua` file. Use only `hjkl`/`w`/`b`/`gg`/`G` to position the cursor on the first character of a chosen identifier near the end of the file. (No mouse, no `/`.)
2. Use `ci"` to change the value of a `desc = "…"` field somewhere in `keymaps.lua`. Then `u` to undo.
3. Practice `.`-friendliness: change one occurrence of `desc` to `description` using `cw`, then use `.` on three more occurrences (use `n` to jump between matches found via `*` first).
4. Open three Lua files in sequence. Use `<C-o>` and `<C-i>` to traverse the jump list.

## 8. Troubleshooting

- **"My `<Esc>` doesn't work."** Check `imap <Esc>` for an override. Your config maps `<Esc>` in normal+insert to clear hlsearch — that should be transparent.
- **"My counts behave weirdly with j/k."** Your config remaps `j`/`k` to `gj`/`gk` when no count is given (visual line nav). With a count, they revert to logical lines. That's the right behavior.
- **"`:help <topic>` opens then I'm lost."** Use `<C-]>` on a tag, `<C-t>` to pop back. `q` to close help.

## 9. Optional config edit

None for this session — your foundation options are already set well.

## 10. Next-step upgrades

- After internalizing the grammar, every plugin's docs read like English. You'll start seeing `c<text-object>` patterns everywhere.
- Once `.` becomes reflex, watch how often you compose `cw . . .` instead of `:s`.

## 11. Connects to

Next: **Session 2 — Motions & Text Objects**. Now that you know what an operator wants (a motion), it's time to learn the rich vocabulary of motions and text objects that make operators powerful.
