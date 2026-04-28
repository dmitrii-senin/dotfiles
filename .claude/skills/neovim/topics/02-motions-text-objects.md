---
session: 02
title: Motions & Text Objects
phase: A
prerequisites: [1]
duration: 45 min
---

# Session 02 — Motions & Text Objects

## 1. Objective

Move and select by *structure*, not by character. After this session you can edit C++ template arguments, Python decorator stacks, and Rust match arms with surgical precision — without ever using the arrow keys.

## 2. Why it matters

C++: `ci<` to change a template argument. Python: `dap` to delete a function (paragraph). Rust: `ya{` to yank a match block. The motions/text-objects vocabulary is the difference between "I edit characters" and "I edit code."

## 3. Core concepts

### Motions (a position in the buffer)

| Motion         | Meaning                                                                     |
| -------------- | --------------------------------------------------------------------------- |
| `h j k l`      | char left/down/up/right                                                     |
| `w W`          | word / WORD start (WORD = whitespace-bounded)                               |
| `e E`          | word / WORD end                                                             |
| `b B`          | word / WORD back                                                            |
| `0 ^ $`        | line start (col 0) / first non-blank / line end                             |
| `f<x> F<x>`    | find next/prev `<x>` on current line                                        |
| `t<x> T<x>`    | till just before next/prev `<x>` on current line                            |
| `; ,`          | repeat last `f`/`t` forward / backward                                       |
| `gg G`         | top / bottom of buffer (`5G` jumps to line 5)                               |
| `% `           | matching paren/bracket/brace                                                |
| `* #`          | search forward / backward for word under cursor                             |
| `n N`          | repeat last search forward / backward                                       |
| `{ }`          | previous / next blank-line-bounded paragraph                                |
| `(` `)`        | previous / next sentence (rarely useful in code)                            |
| `[[` `]]`      | previous / next class start (treesitter-augmented in your config)           |
| `[m` `]m`      | previous / next function start (treesitter-augmented in your config)        |
| `<C-o> <C-i>`  | jump list back / forward (very used)                                        |
| `g; g,`        | change list back / forward (last edits)                                     |
| `''`  ` `` `   | last position before jump (line / exact col)                                 |
| `H M L`        | top / middle / bottom of visible screen                                     |
| `zz zt zb`     | center / top / bottom the current line on screen                            |

### Text objects (a range, used after an operator or `v`)

A text object has two flavors: `i<x>` (inner, excluding delimiters) and `a<x>` (around, including delimiters).

| Text obj            | Meaning                                                                |
| ------------------- | ---------------------------------------------------------------------- |
| `iw aw`             | word                                                                    |
| `iW aW`             | WORD (whitespace-bounded)                                               |
| `is as`             | sentence                                                                |
| `ip ap`             | paragraph                                                                |
| `i" a"`             | double-quoted string                                                    |
| `i' a'`             | single-quoted string                                                    |
| `` i` `` / `` a` `` | backtick string                                                          |
| `i( a(` or `i) a)`  | parens (use `b` and `B` historically: `dib` = `di(`)                    |
| `i[ a[` or `i] a]`  | square brackets                                                          |
| `i{ a{` or `i} a}`  | braces (also `iB` / `aB`)                                                |
| `i< a<`             | angle brackets — invaluable for C++ templates                           |
| `it at`             | XML/HTML tag (also useful for JSX/TSX)                                  |

**Treesitter-augmented (your config, see `treesitter.lua:80-99`):**

| Text obj       | Meaning                                                       |
| -------------- | ------------------------------------------------------------- |
| `if af`        | function inner / around                                        |
| `ic ac`        | class inner / around                                           |
| `ia aa`        | parameter (argument) inner / around                            |

## 4. Config notes

- `treesitter.lua:80-99` defines your `af`/`if`/`ac`/`ic`/`aa`/`ia` text-object selects with `lookahead = true`. Lookahead means `daf` works even if the cursor is between two functions — Vim jumps to the next one.
- `]m`/`[m`/`]]`/`[[` are also treesitter-driven and live in `treesitter.lua:101-126`. They `set_jumps = true`, so each motion adds to the jump list (good — `<C-o>` brings you back).
- The user's `options.lua:49` sets `jumpoptions = "view"` — the screen restores its scroll position when you jump back. That's a quality-of-life feature; don't unset it.

## 5. Concrete examples

### C++ — delete a template argument

```cpp
std::map<std::string, std::vector<int>> cache;
//          ^cursor here
```
Type `da<` → deletes `<std::string, std::vector<int>>` → leaves `std::map cache;`. Or `ci<` to replace the contents.

### Python — yank a function

```py
def fetch_user(user_id: int) -> User:
    ...   # 30 lines
    return user
```
Cursor anywhere inside, type `yaf` → yanks the entire function (treesitter `af`).

### Rust — change a struct field

```rs
struct Config {
    timeout: Duration,  // <- cursor here
    retries: u32,
}
```
Type `cia` → changes the parameter (`timeout: Duration`) → ready to type a replacement.

### Universal — jump to error

```
src/foo.rs:42:18: error: cannot find value `bar`
```
Yank with `0y$` (or `Y` if your `Y` is `y$`). Then `:e <C-r>"<C-w>` to jump.

## 6. Shortcuts to memorize

### ESSENTIAL
`w b e  0 ^ $  fF tT ;,  %  *  n N  gg G nG  {  }  H M L  zz zt zb  <C-o> <C-i>  iw aw  i" a"  i( a(  i{ a{  i< a<  it at  if af  ip ap`

### OPTIONAL
`g; g,  ''  `` ``  ic ac  ia aa  ]m [m  ]] [[`

### ADVANCED
Custom text objects via [`mini.ai`](https://github.com/echasnovski/mini.nvim) or [`nvim-various-textobjs`](https://github.com/chrisgrieser/nvim-various-textobjs) — *only if the built-ins + treesitter don't cover a recurring pain*. The user's config does not have these; do not add unless asked.

## 7. Drills

1. Open `lspconfig.lua`. Cursor on the word `clangd` in line 86. Use `*` then `n` repeatedly to count occurrences. Use `<C-o>` to return.
2. Same file, place cursor anywhere in the `vim.lsp.config("clangd", { cmd = {...} })` block. Use `vi{` to visually select the table. Use `vi(` to select inside the call. Use `va{` to include the braces.
3. Open `dap.lua`. Cursor inside the `dap.configurations.cpp` table. Use `vaf` to select the entire surrounding function (the `config = function() ... end`). Use `daf` to delete it (then `u` to undo!).
4. Open `treesitter.lua`. Use `]m` and `[m` to jump between function definitions. Use `<C-o>` to return.
5. Tabular drill: in any file, use `f`/`t` and `;` to navigate to specific characters on a long line without using `w`/`b`.

## 8. Troubleshooting

- **`af`/`if` doesn't work.** Treesitter not started for the buffer. Check `:Inspect` (treesitter inspect) and `:checkhealth nvim-treesitter`.
- **`[m`/`]m` jumps to weird places.** Confirm the parser is installed for the filetype: `:TSInstallInfo` (or in your case, `require('nvim-treesitter').install({'<lang>'})`).
- **`%` doesn't match my custom delimiters.** Set `b:match_words` in an ftplugin, or use the [`vim-matchup`](https://github.com/andymass/vim-matchup) plugin (optional).

## 9. Optional config edit

None for this session — your treesitter-textobjects setup is already excellent.

## 10. Next-step upgrades

- Once motions are reflex, you'll find yourself reading code by `]m`/`]]` instead of scrolling. Jump-list discipline (`<C-o>`/`<C-i>`) becomes addictive.
- Consider mapping a custom text object for "argument list" if you ever feel `aa`/`ia` is incomplete (e.g. for Python decorator stacks). But ASK first — most users don't need this.

## 11. Connects to

Next: **Session 3 — Operators, Registers, Macros**. You can move precisely now; next is composing those moves into reusable edits.
