# Text-Drill Corpus

Drills for `/neovim-mastery text-drill` mode. Each drill specifies a `before` buffer (with cursor `█`), an `after` target buffer (with final cursor `█`), and the gold-standard `target` keystrokes. The coach reads each drill, presents `before`/`after` to the user, the user replies with keystrokes, and the coach **simulates** the keystrokes against `before`, prints the resulting buffer, and grades against `after`.

## Conventions

- **Cursor**: `█` (U+2588 FULL BLOCK) — replaces the underlying character. When the underlying char matters (e.g., punctuation), state it in the `notes`.
- **Whitespace**: tabs forbidden — use spaces. Significant trailing spaces are marked with `·` (U+00B7) and called out in `notes`.
- **IDs**: `td-NN` flat namespace (no domain prefix). Domain is a tag.
- **Tags**: one of `motion`, `textobject`, `operator`, `insert`, `substitute` + a level tag `level:1` / `level:2` / `level:3` + key tags for indexing weak keys.
- **target**: gold-standard minimal keystrokes. Other valid solutions are accepted at simulation time.
- **notes**: only present when an edge case or assumption matters (shiftwidth, special-case rule, etc.).

The coach **must** consult the **Simulator scope contract** in `SKILL.md` before grading. If the user's keystrokes contain out-of-scope tokens (macros, registers, `<C-v>`, etc.), refuse simulation per the protocol — do not guess.

---

## Motions (td-01 — td-08)

### td-01 *(level:1, tags: motion, hl, count)*

**Before:**
```
foo█barbaz
```

**After:**
```
foobar█baz
```

- **target**: `3l`

### td-02 *(level:1, tags: motion, eol, first-non-blank)*

**Before:**
```
    foo bar █baz
```

**After:**
```
    █foo bar baz
```

- **target**: `^`

### td-03 *(level:1, tags: motion, word, count)*

**Before:**
```
the █quick brown fox jumps
```

**After:**
```
the quick brown █fox jumps
```

- **target**: `2w`

### td-04 *(level:1, tags: motion, find)*

**Before:**
```
if (foo█.bar) return;
```

**After:**
```
if (foo.bar) return█;
```

- **target**: `f;`

### td-05 *(level:2, tags: motion, find, repeat-find)*

**Before:**
```
a, b, c█, d, e, f
```

**After:**
```
a, b, c, d, e█, f
```

- **target**: `f,;`
- **notes**: cursor starts on the `,` after `c`; `f,` finds the next `,` (after `d`); `;` repeats forward to the `,` after `e`.

### td-06 *(level:2, tags: motion, match-pair)*

**Before:**
```
if █(x > 0 && y < 1) {
```

**After:**
```
if (x > 0 && y < 1█) {
```

- **target**: `%`

### td-07 *(level:1, tags: motion, top-bottom)*

**Before:**
```
line 1
line 2
line 3
█line 4
line 5
```

**After:**
```
█line 1
line 2
line 3
line 4
line 5
```

- **target**: `gg`

### td-08 *(level:1, tags: motion, word-end)*

**Before:**
```
the █quick brown fox
```

**After:**
```
the quic█k brown fox
```

- **target**: `e`

---

## Text objects (td-09 — td-18)

### td-09 *(level:1, tags: textobject, daw, clean)*

**Before:**
```
foo █bar baz
```

**After:**
```
foo █baz
```

- **target**: `daw`
- **notes**: `daw` removes the word `bar` plus its trailing space; cursor lands on the first char of the next word.

### td-10 *(level:2, tags: textobject, daw, leading-space)*

**Before:**
```
foo bar █baz
```

**After:**
```
foo ba█r
```

- **target**: `daw`
- **notes**: end-of-line — no trailing space, so `daw` consumes the leading space; cursor lands on the last char of the preceding word.

### td-11 *(level:1, tags: textobject, ciw, change)*

**Before:**
```
foo █bar baz
```

**After:**
```
foo qu█x baz
```

- **target**: `ciwqux<Esc>`
- **notes**: `ciw` deletes only the word (no spaces) and enters insert; cursor lands on the last typed char after `<Esc>`.

### td-12 *(level:1, tags: textobject, ci", change, quotes)*

**Before:**
```
let name = "█Alice";
```

**After:**
```
let name = "Bo█b";
```

- **target**: `ci"Bob<Esc>`

### td-13 *(level:2, tags: textobject, da", quotes)*

**Before:**
```
name = "█Alice" + suffix
```

**After:**
```
name = █+ suffix
```

- **target**: `da"`
- **notes**: `da"` includes both quotes plus the trailing space; cursor lands on the next non-deleted char (`+`).

### td-14 *(level:1, tags: textobject, di(, parens)*

**Before:**
```
foo(█a, b, c)
```

**After:**
```
foo(█)
```

- **target**: `di(`
- **notes**: cursor lands on the closing `)`.

### td-15 *(level:2, tags: textobject, da{, braces)*

**Before:**
```
let arr = █{1, 2, 3};
```

**After:**
```
let arr = █;
```

- **target**: `da{`
- **notes**: removes `{1, 2, 3}` including both braces; cursor lands on `;`.

### td-16 *(level:2, tags: textobject, dap, paragraph)*

**Before:**
```
hello █world

next
```

**After:**
```
█next
```

- **target**: `dap`
- **notes**: `dap` removes the paragraph plus the trailing blank line.

### td-17 *(level:1, tags: textobject, ci(, change, parens)*

**Before:**
```
foo(█a, b, c)
```

**After:**
```
foo(█x)
```

- **target**: `ci(x<Esc>`
- **notes**: `ci(` deletes inner-paren content, enters insert; type `x`, `<Esc>` — cursor on `x`.

### td-18 *(level:2, tags: textobject, da[, brackets)*

**Before:**
```
arr = [█1, 2, 3];
```

**After:**
```
arr = █;
```

- **target**: `da[`

---

## Operators (td-19 — td-26)

### td-19 *(level:1, tags: operator, dd, line)*

**Before:**
```
keep me
█delete me
keep me too
```

**After:**
```
keep me
█keep me too
```

- **target**: `dd`

### td-20 *(level:2, tags: operator, D, line-end)*

**Before:**
```
prefix█keepme; tail
```

**After:**
```
prefi█x
```

- **target**: `D`
- **notes**: `D` is `d$`; deletes from cursor to end of line; cursor lands on the last remaining char.

### td-21 *(level:2, tags: operator, cc, change-line)*

**Before:**
```
keep
█delete this
keep
```

**After:**
```
keep
ne█w
keep
```

- **target**: `ccnew<Esc>`
- **notes**: no auto-indent in simulator — line starts at col 0.

### td-22 *(level:1, tags: operator, yyp, duplicate)*

**Before:**
```
foo
█bar
baz
```

**After:**
```
foo
bar
█bar
baz
```

- **target**: `yyp`

### td-23 *(level:2, tags: operator, count, word, d-motion)*

**Before:**
```
delete █one two three keep this
```

**After:**
```
delete █keep this
```

- **target**: `d3w`
- **notes**: deletes "one ", "two ", "three " (3 word advances including trailing whitespace); cursor lands on `k` of `keep`.

### td-24 *(level:2, tags: operator, gUiw, case)*

**Before:**
```
let █foo = bar;
```

**After:**
```
let █FOO = bar;
```

- **target**: `gUiw`

### td-25 *(level:1, tags: operator, r, replace-char)*

**Before:**
```
let foo = █bar;
```

**After:**
```
let foo = █Bar;
```

- **target**: `rB`
- **notes**: `r` replaces the single char under cursor and stays in normal mode; cursor stays.

### td-26 *(level:2, tags: operator, indent, shiftwidth)*

**Before:**
```
█let x = 1;
```

**After:**
```
  █let x = 1;
```

- **target**: `>>`
- **notes**: assume `shiftwidth=2` for this drill; cursor lands on the first non-blank.

---

## Insert mode (td-27 — td-29)

### td-27 *(level:1, tags: insert, o, open-below)*

**Before:**
```
█first line
last line
```

**After:**
```
first line
middl█e
last line
```

- **target**: `omiddle<Esc>`
- **notes**: no auto-indent in simulator — new line starts at col 0.

### td-28 *(level:1, tags: insert, O, open-above)*

**Before:**
```
first line
█last line
```

**After:**
```
first line
middl█e
last line
```

- **target**: `Omiddle<Esc>`

### td-29 *(level:1, tags: insert, A, append-eol)*

**Before:**
```
name = "Alic█e"
```

**After:**
```
name = "Alice"█;
```

- **target**: `A;<Esc>`
- **notes**: `A` jumps past the last char and enters insert; type `;`, `<Esc>` lands cursor on `;`.

---

## Search & substitute (td-30 — td-32)

### td-30 *(level:2, tags: substitute, s, line)*

**Before:**
```
foo bar foo baz█
```

**After:**
```
█qux bar foo baz
```

- **target**: `:s/foo/qux/<CR>`
- **notes**: replaces only the first `foo` on the current line; cursor lands on the first char of the replacement.

### td-31 *(level:2, tags: substitute, %s, global)*

**Before:**
```
foo bar █foo
baz foo
```

**After:**
```
qux bar qux
baz █qux
```

- **target**: `:%s/foo/qux/g<CR>`
- **notes**: cursor lands on the first char of the last substitution.

### td-32 *(level:2, tags: search, slash, change-word)*

**Before:**
```
foo █bar baz qux
```

**After:**
```
foo bar baz QUU█X
```

- **target**: `/qu<CR>cwQUUX<Esc>`
- **notes**: `/qu` jumps to `q` of `qux`; `cw` deletes the word (special case: no trailing whitespace), enter insert, type `QUUX`, `<Esc>` lands on `X`.

---

## Index

Total drills: **32**
- Motions: 8 (td-01..td-08)
- Text objects: 10 (td-09..td-18)
- Operators: 8 (td-19..td-26)
- Insert: 3 (td-27..td-29)
- Search & substitute: 3 (td-30..td-32)

Domain tag filter (used by `text-drill <domain>`):
- `motions` → `motion` tag
- `textobjects` → `textobject` tag
- `operators` → `operator` tag
- `insert` → `insert` tag
- `substitute` → `substitute` or `search` tag

## Adding new drills

1. Pick the next free `td-NN` ID. Do not renumber.
2. Tag with one primary domain (`motion`/`textobject`/`operator`/`insert`/`substitute`) + `level:N` + key tags.
3. Both `before` and `after` must contain exactly one `█`. Whitespace must be lossless (use `·` for trailing spaces and document in `notes`).
4. Verify the drill against the **Simulator scope contract** — if any token in `target` is out of scope, the drill belongs in `motion-corpus.md` (buffer-based), not here.
5. Add a row to `references/drill-state.md` with `box=1, attempts=0, last_seen=-`.
