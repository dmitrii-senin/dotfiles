# Text-Drill Corpus

Drills for `/neovim text-drill` mode. Each drill specifies a `before` buffer (with cursor `█`), an `after` target buffer (with final cursor `█`), and the gold-standard `target` keystrokes. The coach reads each drill, presents `before`/`after` to the user, the user replies with keystrokes, and the coach **simulates** the keystrokes against `before`, prints the resulting buffer, and grades against `after`.

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

### td-33 *(level:1, tags: motion, dollar, eol)*

**Before:**
```
foo bar █baz qux
```

**After:**
```
foo bar baz qu█x
```

- **target**: `$`

### td-34 *(level:1, tags: motion, zero, col-zero)*

**Before:**
```
    foo █bar baz
```

**After:**
```
█    foo bar baz
```

- **target**: `0`
- **notes**: `0` jumps to absolute column 0 (the leading space), unlike `^` which jumps to first non-blank.

### td-35 *(level:1, tags: motion, b, word-back)*

**Before:**
```
the quick brown fox █jumps
```

**After:**
```
the quick brown █fox jumps
```

- **target**: `b`

### td-36 *(level:2, tags: motion, B, capital-word)*

**Before:**
```
foo.bar.baz █qux
```

**After:**
```
█foo.bar.baz qux
```

- **target**: `B`
- **notes**: `B` jumps over WHITESPACE-separated WORDs; punctuation doesn't break the word.

### td-37 *(level:1, tags: motion, line-jump, count)*

**Before:**
```
line 1
line 2
█line 3
line 4
line 5
line 6
```

**After:**
```
line 1
line 2
line 3
line 4
█line 5
line 6
```

- **target**: `5G`

### td-38 *(level:2, tags: motion, screen, top)*

**Before:**
```
line 1
line 2
█line 3
```

**After:**
```
█line 1
line 2
line 3
```

- **target**: `H`
- **notes**: `H` jumps to top of visible screen; assumes the small buffer fits entirely on screen.

### td-39 *(level:2, tags: motion, screen, middle)*

**Before:**
```
line 1
line 2
line 3
line 4
█line 5
```

**After:**
```
line 1
line 2
█line 3
line 4
line 5
```

- **target**: `M`
- **notes**: `M` jumps to middle of visible screen.

### td-40 *(level:2, tags: motion, screen, bottom)*

**Before:**
```
█line 1
line 2
line 3
```

**After:**
```
line 1
line 2
█line 3
```

- **target**: `L`

### td-41 *(level:2, tags: motion, paragraph-back)*

**Before:**
```
hello world

next paragraph

last █one
```

**After:**
```
hello world

next paragraph
█
last one
```

- **target**: `{`
- **notes**: `{` jumps to the previous blank line; cursor lands at col 0 of the blank line.

### td-42 *(level:2, tags: motion, paragraph-forward)*

**Before:**
```
█first
second

next paragraph
```

**After:**
```
first
second
█
next paragraph
```

- **target**: `}`

### td-43 *(level:2, tags: motion, e, count, word-end)*

**Before:**
```
the █quick brown fox jumps
```

**After:**
```
the quick brown fo█x jumps
```

- **target**: `3e`
- **notes**: `3e` jumps to the end of the 3rd word ahead.

### td-44 *(level:2, tags: motion, ge, word-end-back)*

**Before:**
```
foo bar █baz qux
```

**After:**
```
foo ba█r baz qux
```

- **target**: `ge`
- **notes**: `ge` jumps back to the end of the previous word.

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

### td-45 *(level:1, tags: textobject, diw, inner-word)*

**Before:**
```
foo █bar baz
```

**After:**
```
foo █ baz
```

- **target**: `diw`
- **notes**: `diw` deletes only the word (no surrounding whitespace); cursor on the leading space that was after the deleted word.

### td-46 *(level:2, tags: textobject, ci', single-quote)*

**Before:**
```
name = '█Alice';
```

**After:**
```
name = 'Bo█b';
```

- **target**: `ci'Bob<Esc>`

### td-47 *(level:2, tags: textobject, di{, inner-braces)*

**Before:**
```
let arr = {█1, 2, 3};
```

**After:**
```
let arr = {█};
```

- **target**: `di{`
- **notes**: `di{` deletes contents inside braces; cursor on the closing `}`.

### td-48 *(level:2, tags: textobject, ci{, change-braces)*

**Before:**
```
fn foo() {█old}
```

**After:**
```
fn foo() {ne█w}
```

- **target**: `ci{new<Esc>`

### td-49 *(level:2, tags: textobject, dip, inner-paragraph)*

**Before:**
```
hello █world

next paragraph
```

**After:**
```
█

next paragraph
```

- **target**: `dip`
- **notes**: `dip` removes the paragraph but NOT the trailing blank line (vs `dap` which includes it).

### td-50 *(level:2, tags: textobject, vipd, visual-paragraph)*

**Before:**
```
first █line
second line
third line

other paragraph
```

**After:**
```
█
other paragraph
```

- **target**: `vipd`
- **notes**: `vip` selects inner paragraph (3 lines), `d` deletes the selection. Cursor lands on the resulting blank line.

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

### td-51 *(level:1, tags: operator, tilde, case-toggle)*

**Before:**
```
█hello
```

**After:**
```
H█ello
```

- **target**: `~`
- **notes**: `~` toggles case of char under cursor and moves right.

### td-52 *(level:2, tags: operator, tilde, count, case)*

**Before:**
```
█hello
```

**After:**
```
HELL█O
```

- **target**: `5~`
- **notes**: `5~` toggles 5 chars; cursor lands on the last toggled char (clamped to last col).

### td-53 *(level:2, tags: operator, dedent, shiftwidth)*

**Before:**
```
  █foo
```

**After:**
```
█foo
```

- **target**: `<<`
- **notes**: assume `shiftwidth=2`; `<<` removes one shiftwidth of indent. Cursor on first non-blank.

### td-54 *(level:2, tags: operator, c-dollar, change-eol)*

**Before:**
```
let foo = █bar;
```

**After:**
```
let foo = qu█x
```

- **target**: `c$qux<Esc>`
- **notes**: `c$` deletes from cursor to EOL and enters insert; type `qux`, `<Esc>` lands on `x`.

### td-55 *(level:2, tags: operator, d-dollar, delete-eol)*

**Before:**
```
█keepme; tail
```

**After:**
```
█
```

- **target**: `d$`
- **notes**: `d$` deletes from cursor to EOL; here it deletes the entire line content. Cursor on now-empty line at col 0.

### td-56 *(level:2, tags: operator, V, linewise-visual)*

**Before:**
```
keep
█delete
keep too
```

**After:**
```
keep
█keep too
```

- **target**: `Vd`
- **notes**: `V` enters linewise visual (selects current line), `d` deletes it.

### td-57 *(level:2, tags: operator, guu, lower-line)*

**Before:**
```
HELLO █WORLD AGAIN
```

**After:**
```
█hello world again
```

- **target**: `guu`
- **notes**: `guu` lowercases the entire line. Cursor lands at col 0.

### td-58 *(level:2, tags: operator, dot-repeat, daw)*

**Before:**
```
delete █one two keep
```

**After:**
```
delete █keep
```

- **target**: `daw.`
- **notes**: `daw` deletes "one ", `.` repeats the deletion on "two ".

### td-59 *(level:2, tags: operator, xp, swap-chars)*

**Before:**
```
the w█rod
```

**After:**
```
the wo█rd
```

- **target**: `xp`
- **notes**: classic swap-adjacent-chars idiom — `x` deletes char (into unnamed register), `p` pastes after.

### td-60 *(level:1, tags: operator, J, join-lines)*

**Before:**
```
foo █bar
baz qux
```

**After:**
```
foo bar█ baz qux
```

- **target**: `J`
- **notes**: `J` joins next line with single space; cursor lands on the joined space.

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

### td-61 *(level:1, tags: insert, i, insert-before)*

**Before:**
```
let foo = █bar;
```

**After:**
```
let foo = new█_bar;
```

- **target**: `inew_<Esc>`
- **notes**: `i` enters insert BEFORE cursor; type `new_`, `<Esc>` lands on `_`.

### td-62 *(level:1, tags: insert, I, line-start)*

**Before:**
```
    █foo bar
```

**After:**
```
    //█ foo bar
```

- **target**: `I// <Esc>`
- **notes**: `I` jumps to first non-blank then enters insert. After `<Esc>`, cursor on the trailing space.

### td-63 *(level:2, tags: insert, cw, change-word)*

**Before:**
```
let █foo = 1;
```

**After:**
```
let qu█x = 1;
```

- **target**: `cwqux<Esc>`
- **notes**: `cw` is special-cased to NOT include trailing whitespace (acts like `ce`).

### td-64 *(level:2, tags: insert, s, substitute-char)*

**Before:**
```
nad█i
```

**After:**
```
nad█a
```

- **target**: `sa<Esc>`
- **notes**: `s` deletes the char under cursor and enters insert (= `cl`).

### td-65 *(level:2, tags: insert, replace, count, r)*

**Before:**
```
█abc def
```

**After:**
```
XX█X def
```

- **target**: `3rX`
- **notes**: `3r<x>` replaces 3 chars under cursor with `<x>`; cursor lands on the last replaced position. Stays in normal mode.

### td-66 *(level:3, tags: insert, multi-line, newline)*

**Before:**
```
start█end
```

**After:**
```
start
mid
█end
```

- **target**: `i<CR>mid<CR><Esc>`
- **notes**: embedded `<CR>`s split the insertion across lines. No auto-indent assumed; `<Esc>` keeps cursor at col 0 of the line it lands on.

### td-67 *(level:1, tags: insert, A, append-eol-extended)*

**Before:**
```
foo bar █baz
```

**After:**
```
foo bar baz qu█x
```

- **target**: `A qux<Esc>`

### td-68 *(level:1, tags: insert, a, append-after-cursor)*

**Before:**
```
the fo█o.bar
```

**After:**
```
the foo█X.bar
```

- **target**: `aX<Esc>`
- **notes**: `a` enters insert AFTER cursor (one position right) — vs `i` which is BEFORE.

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

### td-69 *(level:2, tags: search, slash, forward)*

**Before:**
```
foo █bar baz bar qux
```

**After:**
```
foo bar baz █bar qux
```

- **target**: `/bar<CR>`
- **notes**: `/` searches forward starting AFTER cursor; finds the next `bar` after the current one.

### td-70 *(level:2, tags: search, question, backward)*

**Before:**
```
foo bar baz █qux end
```

**After:**
```
foo █bar baz qux end
```

- **target**: `?bar<CR>`
- **notes**: `?` searches backward.

### td-71 *(level:2, tags: search, n, repeat-search)*

**Before:**
```
█apple banana cherry banana
```

**After:**
```
apple banana cherry █banana
```

- **target**: `/banana<CR>n`
- **notes**: `n` repeats the last search forward; jumps to the second `banana`.

### td-72 *(level:2, tags: substitute, i-flag, case-insensitive)*

**Before:**
```
Foo foo FOO bar█
```

**After:**
```
█Bar foo FOO bar
```

- **target**: `:s/foo/Bar/i<CR>`
- **notes**: `i` flag = case-insensitive. First case-insensitive match (`Foo`) is replaced; cursor lands on start of substitution.

### td-73 *(level:3, tags: substitute, range, line-numbers)*

**Before:**
```
foo line 1
foo line 2
foo line 3
foo line █4
foo line 5
```

**After:**
```
foo line 1
bar line 2
bar line 3
█bar line 4
foo line 5
```

- **target**: `:2,4s/foo/bar/<CR>`
- **notes**: range `2,4` restricts substitution to lines 2-4. Cursor lands on the start of the last substitution.

### td-74 *(level:3, tags: search, very-magic, regex)*

**Before:**
```
█x = 1; y = 22; z = 333;
```

**After:**
```
x = 1; y = █22; z = 333;
```

- **target**: `/\v\d{2}<CR>`
- **notes**: `\v` = very-magic mode; `\d{2}` matches two consecutive digits. First match is `22`.

### td-75 *(level:2, tags: substitute, percent, gi-flags)*

**Before:**
```
Foo bar
foo BAR
█FOO bar
```

**After:**
```
xx bar
xx BAR
█xx bar
```

- **target**: `:%s/foo/xx/gi<CR>`
- **notes**: `%` = whole buffer; `g` = all matches per line; `i` = case-insensitive. Cursor lands on start of last substitution.

### td-76 *(level:2, tags: substitute, g-flag, current-line)*

**Before:**
```
foo bar foo baz █qux
```

**After:**
```
bar bar █bar baz qux
```

- **target**: `:s/foo/bar/g<CR>`
- **notes**: without `%`, `:s` operates on the current line only; `g` substitutes ALL matches on that line.

---

## Visual mode (td-77 — td-80)

### td-77 *(level:2, tags: visual, charwise, vt, delete)*

**Before:**
```
delete █one two three keep
```

**After:**
```
delete █keep
```

- **target**: `vtkd`
- **notes**: `v` enters charwise visual; `tk` extends selection up to (not including) `k`; `d` deletes the selection.

### td-78 *(level:2, tags: visual, linewise, V, delete)*

**Before:**
```
keep
█delete this
delete that
keep too
```

**After:**
```
keep
█keep too
```

- **target**: `Vjd`
- **notes**: `V` linewise visual (selects current line); `j` extends to next line; `d` deletes both.

### td-79 *(level:2, tags: visual, vi-quotes, delete)*

**Before:**
```
name = "█Alice";
```

**After:**
```
name = "█";
```

- **target**: `vi"d`
- **notes**: `vi"` selects inside double quotes; `d` deletes the selection. Cursor on closing `"`.

### td-80 *(level:3, tags: visual, gg, G, whole-buffer)*

**Before:**
```
█line 1
line 2
line 3
```

**After:**
```
█
```

- **target**: `ggVGd`
- **notes**: `gg` to top, `V` linewise visual, `G` to last line (extends selection), `d` deletes all. Buffer becomes a single empty line.

---

## Index

Total drills: **80**
- Motions: 20 (td-01..td-08, td-33..td-44)
- Text objects: 16 (td-09..td-18, td-45..td-50)
- Operators: 18 (td-19..td-26, td-51..td-60)
- Insert: 11 (td-27..td-29, td-61..td-68)
- Search & substitute: 11 (td-30..td-32, td-69..td-76)
- Visual mode: 4 (td-77..td-80)

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
