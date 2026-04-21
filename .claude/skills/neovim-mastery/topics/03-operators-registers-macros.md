---
session: 03
title: Operators, Registers, Macros
phase: A
prerequisites: [2]
duration: 45 min
---

# Session 03 — Operators, Registers, Macros

## 1. Objective

Compose edits with operators and registers; record macros for repetitive transforms; replay them across lines, files, or argument lists. After this session, "I'd have to do this 30 times" becomes a 5-second macro.

## 2. Why it matters

C++: rename a member across a class with macro + `*` + `cgn` + `.`. Python: convert old-style string formatting to f-strings across a file. Rust: turn a vector of `(K, V)` literals into a `HashMap` insert per line. Registers also let you keep a "scratch" yank separate from your main one — invaluable when you need to swap two pieces of code.

## 3. Core concepts

### Operators (deeper view)

| Operator | Action                                  | Notes                                                        |
| -------- | --------------------------------------- | ------------------------------------------------------------ |
| `d`      | delete (yanks to default register)      | `dd` = delete line; `D` = `d$`                               |
| `c`      | change (delete + insert)                | `cc` = change line; `C` = `c$`                               |
| `y`      | yank                                    | `yy` = yank line; `Y` = `y$` (set in many configs; verify yours) |
| `p P`    | paste after / before                    | Uses last yank/delete unless register specified              |
| `gq`     | format (uses `formatprg`)               | Often LSP-driven; combine with `ip` (paragraph)              |
| `=`      | re-indent                               | Useful in unindented JSON/YAML pastes                        |
| `>` `<`  | indent right / left                     | Visual: `>>` `<<` per line                                   |
| `~`      | toggle case                             | `g~`, `gu`, `gU` are operator forms                          |
| `gu gU`  | lowercase / uppercase                   | `guip` lowercases inner paragraph                            |
| `g?`     | rot13 (rare)                            | —                                                            |

**Operator + text object = surgical edit.** `gqap`, `gugW`, `=ip`, `<aB`.

### Registers

Vim has many registers. The ones you'll use:

| Register        | Purpose                                                                |
| --------------- | ---------------------------------------------------------------------- |
| `""`            | Default (last yank/delete)                                             |
| `"0`            | Last yank only (NOT polluted by deletes)                               |
| `"1`–`"9`       | Recent deletes (history)                                               |
| `"a`–`"z`       | Named, manual                                                          |
| `"A`–`"Z`       | Named, append-on-write                                                 |
| `"+`            | System clipboard (when `clipboard=unnamedplus`, this is also `""`)     |
| `"*`            | Selection clipboard (X11/Wayland; rarely used on macOS)                |
| `"_`            | Black hole (deletes that DON'T pollute any register)                   |
| `":`            | Last ex command                                                        |
| `"/`            | Last search                                                            |
| `".`            | Last inserted text                                                     |
| `"%`            | Current file path                                                      |
| `"#`            | Alternate file path                                                    |

**Use `"+y` to yank to clipboard explicitly** (only matters if you want to override `clipboard=unnamedplus`). **Use `"_d` to delete without polluting your yank** — this is the single most underused trick.

**View all registers:** `:reg` (or `:reg a b c` to filter).

### Macros

`q<reg>` start recording into register `<reg>`. `q` to stop. `@<reg>` to play. `@@` to repeat the last play. Macros are just text — you can edit them with `:let @a = '...'`.

**The killer recipe:**
1. Position cursor where the edit starts.
2. `qa` start recording into `a`.
3. Do the edit, ending with a motion to set up the next iteration (e.g. `j0`).
4. `q` to stop.
5. `5@a` to replay 5 times. Or `@@` to replay one.

**Visual macro replay:** select lines with `V`, then `:norm @a` runs `@a` on each line. (See Session 5 for `:norm`.)

## 4. Config notes

- `options.lua:15`: `clipboard = vim.env.SSH_TTY and "" or "unnamedplus"` — your default register and `"+` are unified locally; over SSH they're separated (so OSC52 can take over). Means `yy` already syncs with macOS clipboard locally.
- The user has no custom register-related maps — registers work as Vim defaults.

## 5. Concrete examples

### Delete-without-polluting

```
foo = some_function()
bar = important_value
```

You want to keep `important_value` as your latest yank. To delete `foo = some_function()`:

`"_dd` (delete the line into the black hole). Now `p` still pastes `important_value` — your useful yank is intact.

### Swap two adjacent functions

In a Lua file with two adjacent `function` blocks:
1. Cursor in first function. `vaf` selects it. `"ad` → deletes into register `a`.
2. Cursor in (now first) function. `vaf` selects it. `"bd` → deletes into register `b`.
3. `"bP` to paste `b` first, then `"aP` to paste `a`. Done.

(In practice, `dap`/`p` swaps work for paragraph-based code; the named-register version generalizes.)

### Macro: convert old C++ enum class members to snake_case (toy example)

Suppose you have:
```cpp
enum class Color { RedColor, BlueColor, GreenColor };
```
Cursor on `R` of `RedColor`:
1. `qa` start.
2. `gu1l` lowercase first char. `f` (capital A-Z if any) — but easier: `lguw` lowercase the rest of the word. Actually, you want a complete macro that handles snake-casing — that's better with `:s`.

Realistic macro instead — increment line numbers in a list:
```
log[1] = ...
log[1] = ...
log[1] = ...
```
1. Cursor on `1` of first line.
2. `qa` `<C-a>` (increment) `j` `q`.
3. `2@a` increments next two lines. Result: `log[1]`, `log[2]`, `log[3]`.

## 6. Shortcuts to memorize

### ESSENTIAL
`d c y p P  dd cc yy  D C Y  "0p "+y "_d  q<r> @<r> @@  <C-a> <C-x>  u <C-r>  .`

### OPTIONAL
`gqap gugW guu  ~ g~iw  :reg  "ay "ap  "_diw`

### ADVANCED
`:let @a = 'macro contents'   :let @a = @a . '\n' . 'more'   :norm @a   q:` (open command-line history window)

## 7. Drills

1. In any file, delete a line with `"_dd`. Then `p` and confirm your previous yank reappears.
2. Yank a line with `yy`. Delete several other lines with `dd`. Try `"0p` — should paste your original yank (deletes don't pollute `"0`).
3. Open a file with a numbered list. Record a macro that increments the number on the current line and moves down. Replay 5 times.
4. With three buffer-position markers (`ma`, `mb`, `mc` in different files), jump between them with `'a`, `'b`, `'c`. Confirm `<C-o>` retraces your steps.
5. Yank a function (`yaf`), open another file (`:e other.lua`), paste with `p`. Use `"+y` and verify pasting in another app (e.g. browser address bar) — confirms clipboard integration.

## 8. Troubleshooting

- **"My macro stops in the middle."** A motion in the macro failed silently (e.g. `f` couldn't find the char). Add `set nofoldenable` if folds interfere; record more carefully.
- **"`@@` doesn't replay."** You played a different register since. Use the explicit `@<r>` again.
- **"Yanks don't go to clipboard."** Verify `clipboard=unnamedplus` (your config sets it). On Linux, you also need `xclip` or `wl-clipboard` installed. macOS uses `pbcopy`.
- **"`<C-r>` doesn't redo."** In normal mode it does. In insert mode `<C-r><reg>` *inserts the contents of a register*. If you're in insert and want undo-like behavior, leave to normal first.

## 9. Optional config edit

None for this session.

Note for later: many users add a `<Leader>p` map for "paste from register `0`" (the un-polluted yank). Not needed if you remember `"0p`.

## 10. Next-step upgrades

- Once macros are reflex, half of what people use Python/sed scripts for becomes a 5-second `:norm @a` over a visual selection.
- For bigger transforms, jump straight to `:%s/...` (Session 5) — macros are best for *non-uniform* edits (e.g. each line gets a different number incremented).

## 11. Connects to

Next: **Session 4 — Buffers, Windows, Tabs**. Now that you can edit fluently, it's time to manage many files at once without losing your place.
