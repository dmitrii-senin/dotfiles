# Motion Drill Corpus

Drills the `/neovim-mastery drill` and `warmup` modes pick from. Each entry is a short, self-contained exercise the coach reads aloud while the user practices in their own buffer. Acceptance is **self-reported** (`done <id>` / `stuck <id> <details>`) — the coach cannot verify cursor state directly.

## Conventions

- **id** — `<domain>-<NN>` (stable; used by `drill-state.md`).
- **setup** — required buffer state. If empty, "any code buffer" is fine.
- **prompt** — what to accomplish. Phrased as imperative.
- **target** — *minimal* keystrokes that solve it. Other paths are allowed; this is the gold standard.
- **accept** — observable confirmation (cursor pos, register state, buffer diff).
- **tags** — `level:{1,2,3}` (1=warmup, 2=core, 3=advanced) + key tags for indexing weak-key tracking.

## Domains

- `hd-*` — hjkl discipline (no-arrow, no-search shortcuts)
- `wm-*` — word motions (w/W/b/B/e/E/ge/f/F/t/T)
- `to-*` — text objects (aw/iw, a"/i", ab/ib, a]/i], at/it, ip/ap)
- `op-*` — operators (d/c/y/gu/gU/>/</~ + motion combinators)
- `ss-*` — search & substitute (/ ? * # :s :g :v very-magic)
- `mj-*` — marks & jumps (m/'/`/jumplist/changelist)
- `rg-*` — registers (" 0 + * _ named, :reg)
- `mc-*` — macros (qa/@a/q:/recursive)
- `ex-*` — ex commands (:g/:v/:norm/:argdo/:cdo/:bufdo)
- `fw-*` — folds & windows (z*, <C-w>*)
- `lsp-*` — LSP-driven motions (gd, grr, gri, gra, K, gO, ]d/[d)
- `ts-*` — treesitter / structural (vaf/vif, ]m/[m, swap, increment)

---

## hd — hjkl discipline

### hd-01 *(level:1, tags: hjkl)*
- **prompt**: Move cursor down 12 lines without using arrow keys, mouse, or `j` more than 3 times in a row.
- **target**: `12j`
- **accept**: cursor 12 lines below start; arrow keys not pressed.

### hd-02 *(level:1, tags: lines, count)*
- **prompt**: Jump to the 50th line of the buffer.
- **target**: `50G` *(or `:50<CR>`)*
- **accept**: `:echo line('.')` reports `50`.

### hd-03 *(level:1, tags: top-bottom)*
- **prompt**: Go to the very last line, then back to the very first line.
- **target**: `G` then `gg`
- **accept**: cursor on line 1.

### hd-04 *(level:2, tags: screen)*
- **prompt**: Without scrolling, move cursor to the top of the visible window, then middle, then bottom.
- **target**: `H`, `M`, `L`
- **accept**: cursor on line `winline()` reports 1, then ~half, then visible last.

### hd-05 *(level:2, tags: column, eol)*
- **prompt**: Go to first non-blank of current line, then to end of line, then to absolute column 0.
- **target**: `^`, `$`, `0`
- **accept**: cursor at col 0 last; verify with `:echo col('.')`.

### hd-06 *(level:2, tags: scroll)*
- **prompt**: Scroll the view so the current line is centered on screen, then top, then bottom.
- **target**: `zz`, `zt`, `zb`
- **accept**: line position on screen visibly changes; cursor row in buffer unchanged.

### hd-07 *(level:3, tags: paragraph)*
- **prompt**: Jump 3 paragraphs forward, then 3 paragraphs back.
- **target**: `3}` then `3{`
- **accept**: end at original cursor line.

---

## wm — word motions

### wm-01 *(level:1, tags: w, b)*
- **prompt**: From the start of a long line, advance to the start of the 4th word, then back to the 2nd word.
- **target**: `4w` then `2b`
- **accept**: cursor sits on the first character of the 2nd word.

### wm-02 *(level:1, tags: e, ge)*
- **prompt**: Land on the *last* character of the next word, then on the last character of the *previous* word.
- **target**: `e`, `ge`
- **accept**: confirm with `:echo getline('.')[col('.')-1]`.

### wm-03 *(level:2, tags: W, B, capital-word)*
- **prompt**: Advance to the next WORD (whitespace-separated), skipping punctuation. E.g. from `foo` in `foo.bar baz`, end on `baz`.
- **target**: `W`
- **accept**: cursor on `b` of `baz`, not `.` or `bar`.

### wm-04 *(level:1, tags: f, t)*
- **prompt**: Jump to the next semicolon on the line.
- **target**: `f;`
- **accept**: cursor on the `;`.

### wm-05 *(level:2, tags: F, T)*
- **prompt**: Jump backward to *just after* the previous opening paren on the same line.
- **target**: `T(`
- **accept**: cursor immediately right of the `(`.

### wm-06 *(level:2, tags: f, semicolon, comma)*
- **prompt**: After `f<char>` matches, jump to the *next* same match without retyping `<char>`. Then jump back.
- **target**: `;` then `,`
- **accept**: cursor advances/regresses one match.

### wm-07 *(level:2, tags: word-end)*
- **prompt**: Delete from cursor to end of current word, inclusive.
- **target**: `de`
- **accept**: word fragment from cursor onward removed.

### wm-08 *(level:3, tags: percent, brackets)*
- **prompt**: Jump to the matching brace/paren/bracket of the one under the cursor.
- **target**: `%`
- **accept**: cursor on the partner.

### wm-09 *(level:3, tags: matchpair, structural)*
- **prompt**: From inside a function call, jump to the *opening* `(` of the call.
- **target**: `[(`
- **accept**: cursor on `(`. *(or `F(` if same line).*

---

## to — text objects

### to-01 *(level:1, tags: iw, daw)*
- **prompt**: Delete the word under the cursor and the trailing space.
- **target**: `daw`
- **accept**: word + 1 space gone, cursor on next word.

### to-02 *(level:1, tags: iw, change)*
- **prompt**: Replace the word under the cursor with `replaced`.
- **target**: `ciw` then type `replaced<Esc>`
- **accept**: word swapped exactly; cursor in normal mode.

### to-03 *(level:1, tags: i", quotes)*
- **prompt**: Yank the contents of the nearest double-quoted string (excluding quotes).
- **target**: `yi"`
- **accept**: `:echo getreg('"')` shows string body without `"`.

### to-04 *(level:2, tags: a", quotes)*
- **prompt**: Delete the nearest double-quoted string *including* the quotes.
- **target**: `da"`
- **accept**: both `"` removed.

### to-05 *(level:2, tags: ib, parens)*
- **prompt**: From inside a `foo(arg1, arg2)`, select inside the parens (just `arg1, arg2`) into visual.
- **target**: `vi(` *(equivalent: `vib`)*
- **accept**: visual covers args only.

### to-06 *(level:2, tags: aB, braces)*
- **prompt**: Delete the entire `{ ... }` block under the cursor including the braces and the line they live on if they're alone.
- **target**: `daB` *(equivalent: `da{`)*
- **accept**: braces and content gone.

### to-07 *(level:2, tags: ip, paragraph)*
- **prompt**: Reformat the current paragraph (using the formatter) — operate on the paragraph text object.
- **target**: `gqip`
- **accept**: paragraph reflowed.

### to-08 *(level:3, tags: it, html-tag)*
- **prompt**: In an HTML/XML/JSX file, change the contents inside the nearest tag without deleting the tag itself.
- **target**: `cit`
- **accept**: tag preserved, content replaced.

### to-09 *(level:3, tags: as, sentence)*
- **prompt**: Delete the entire sentence under the cursor including its trailing space.
- **target**: `das`
- **accept**: sentence + space gone.

### to-10 *(level:3, tags: a], brackets)*
- **prompt**: Yank an array literal `[1, 2, 3]` including brackets.
- **target**: `ya]` *(equivalent: `ya[`)*
- **accept**: register contents include `[…]`.

---

## op — operators

### op-01 *(level:1, tags: dd, line)*
- **prompt**: Delete the current line entirely.
- **target**: `dd`
- **accept**: line removed; default register holds it.

### op-02 *(level:1, tags: yy, paste)*
- **prompt**: Duplicate the current line just below it.
- **target**: `yyp`
- **accept**: line repeated.

### op-03 *(level:1, tags: cc, change)*
- **prompt**: Replace the current line entirely with `pass` (Python) or `;`.
- **target**: `cc` then type the replacement
- **accept**: only new content remains on the line; cursor in insert→normal.

### op-04 *(level:2, tags: indent)*
- **prompt**: Indent the next 5 lines (including current).
- **target**: `5>>` *(or `V4j>`)*
- **accept**: 5 lines now one shiftwidth deeper.

### op-05 *(level:2, tags: case, gu, gU)*
- **prompt**: Uppercase the word under the cursor.
- **target**: `gUiw`
- **accept**: word fully uppercased.

### op-06 *(level:2, tags: dot, repeat)*
- **prompt**: Delete the word, then repeat the deletion 3 more times moving forward.
- **target**: `daw`, then `.` `.` `.`
- **accept**: 4 words removed.

### op-07 *(level:3, tags: yank-paste)*
- **prompt**: Yank a function body (between `{` and `}`), then paste it on the line below the closing brace.
- **target**: `yi{` (or `yaB`), `}p`
- **accept**: body duplicated below.

### op-08 *(level:3, tags: format, gq)*
- **prompt**: Reflow a comment block: position cursor on it and reformat to the current `textwidth`.
- **target**: `gqip` (or `gqap`)
- **accept**: lines wrap at `textwidth`.

### op-09 *(level:3, tags: visual-block, ctrl-v)*
- **prompt**: Insert `// ` at the start of the next 5 lines using visual block mode.
- **target**: `<C-v>4j`, `I// <Esc>`
- **accept**: prefix added to all 5 lines after `<Esc>`.

---

## ss — search & substitute

### ss-01 *(level:1, tags: search, /)*
- **prompt**: Search forward for `TODO`, jump to the next 2 matches, then back to the first.
- **target**: `/TODO<CR>`, `n`, `n`, `N`, `N`
- **accept**: end on the first match.

### ss-02 *(level:1, tags: star)*
- **prompt**: Highlight all occurrences of the word under the cursor and jump through them.
- **target**: `*`, then `n`/`N`
- **accept**: search register holds `\<word\>`.

### ss-03 *(level:2, tags: substitute, line)*
- **prompt**: On the current line, replace the first `foo` with `bar`.
- **target**: `:s/foo/bar/<CR>`
- **accept**: only the first `foo` on this line changed.

### ss-04 *(level:2, tags: substitute, global, file)*
- **prompt**: Replace every `foo` in the buffer with `bar`, ask confirmation each time.
- **target**: `:%s/foo/bar/gc<CR>`
- **accept**: prompted per match; only confirmed ones changed.

### ss-05 *(level:2, tags: very-magic)*
- **prompt**: Find lines that start with `def ` followed by a name and an open paren, using very-magic.
- **target**: `/\vdef \w+\(<CR>`
- **accept**: highlighted matches confined to function defs.

### ss-06 *(level:3, tags: visual-substitute)*
- **prompt**: Substitute only inside the current visual selection (replace `\t` with 4 spaces).
- **target**: select region with `V`, `:s/\t/    /g<CR>`
- **accept**: change confined to selection.

### ss-07 *(level:3, tags: g, ex)*
- **prompt**: Print every line containing `TODO`.
- **target**: `:g/TODO/p<CR>`
- **accept**: list of TODO lines in `:messages`.

### ss-08 *(level:3, tags: g, delete)*
- **prompt**: Delete every blank line in the buffer.
- **target**: `:g/^$/d<CR>`
- **accept**: zero blank lines remain.

### ss-09 *(level:3, tags: v, inverse)*
- **prompt**: Delete every line that does *not* contain `error`.
- **target**: `:v/error/d<CR>`
- **accept**: all remaining lines contain `error`.

---

## mj — marks & jumps

### mj-01 *(level:1, tags: mark, set)*
- **prompt**: Set mark `a` on the current line, move 20 lines away, then jump back to the *line* of mark `a`, then to the *exact position*.
- **target**: `ma`, `20j`, `'a`, then `\`a`
- **accept**: cursor at original col after backtick.

### mj-02 *(level:2, tags: jumplist)*
- **prompt**: After several large jumps (`/`, `G`), step backward through the jumplist 3 entries, then forward 1.
- **target**: `<C-o>` `<C-o>` `<C-o>` then `<C-i>`
- **accept**: cursor at second-to-last jump origin. Verify with `:jumps`.

### mj-03 *(level:2, tags: changelist)*
- **prompt**: Jump to the location of the last change, then the one before, then back forward.
- **target**: `g;`, `g;`, `g,`
- **accept**: visible cursor moves through past edit sites.

### mj-04 *(level:1, tags: last-edit)*
- **prompt**: Move to the position of the last insert/edit.
- **target**: `\`.`
- **accept**: cursor lands on last-modified char.

### mj-05 *(level:2, tags: visual-restore)*
- **prompt**: Re-select the most recent visual selection.
- **target**: `gv`
- **accept**: visual mode restored to prior selection bounds.

### mj-06 *(level:3, tags: global-mark)*
- **prompt**: Set a global (uppercase) mark `A` in this file, switch buffers, then jump back via the mark — it should reopen the original file.
- **target**: `mA`, `:e other.txt<CR>`, `'A`
- **accept**: original file reopened, cursor on marked line.

---

## rg — registers

### rg-01 *(level:1, tags: yank-register)*
- **prompt**: Yank the current line into register `a`.
- **target**: `"ayy`
- **accept**: `:echo getreg('a')` prints the line.

### rg-02 *(level:1, tags: paste-register)*
- **prompt**: Paste the contents of register `a` after the cursor.
- **target**: `"ap`
- **accept**: pasted text matches `getreg('a')`.

### rg-03 *(level:2, tags: black-hole)*
- **prompt**: Delete the current word **without** clobbering the unnamed register.
- **target**: `"_daw`
- **accept**: previous unnamed-register content intact (`:reg "`).

### rg-04 *(level:2, tags: system-clipboard)*
- **prompt**: Yank the current paragraph to the system clipboard.
- **target**: `"+yip`
- **accept**: paste outside Neovim recovers the paragraph.

### rg-05 *(level:2, tags: numbered-registers)*
- **prompt**: Inspect register `0` (last yank) and register `1` (last delete) using `:reg`.
- **target**: `:reg 0 1<CR>`
- **accept**: contents shown in command area.

### rg-06 *(level:3, tags: expression-register)*
- **prompt**: In insert mode, paste the result of `1+2`.
- **target**: in insert: `<C-r>=1+2<CR>`
- **accept**: `3` inserted.

### rg-07 *(level:3, tags: file-name-register)*
- **prompt**: In insert mode, paste the current file's path.
- **target**: in insert: `<C-r>%`
- **accept**: full filename appears at cursor.

---

## mc — macros

### mc-01 *(level:2, tags: record, replay)*
- **prompt**: Record a macro into register `q` that surrounds the current word in single quotes, then replay it on the next 3 words.
- **target**: `qq`, `viw<Esc>`, `\`<i'<Esc>\`>la'<Esc>`, `q`, then `w@q@q@q`
- **accept**: 4 words wrapped in quotes. *(target sequence is illustrative — any solution that records + replays counts.)*

### mc-02 *(level:2, tags: replay)*
- **prompt**: Replay the last macro 5 times.
- **target**: `5@@`
- **accept**: macro body executed 5x.

### mc-03 *(level:3, tags: command-window)*
- **prompt**: Open the command-line history window, find a previous `:s` substitution, edit it, and re-run.
- **target**: `q:`, navigate, edit, `<CR>`
- **accept**: substitution executed with edits.

### mc-04 *(level:3, tags: recursive-macro)*
- **prompt**: Record a macro that processes one line and *moves to the next line*, then make it recursive (calls itself) so a single `@a` runs to end of buffer.
- **target**: `qa<edits>j@aq` then `@a`
- **accept**: edits applied to all subsequent lines.

### mc-05 *(level:3, tags: visual-norm)*
- **prompt**: Apply the macro stored in `q` to every line of the current visual selection.
- **target**: select with `V…`, then `:'<,'>norm @q<CR>`
- **accept**: macro ran per line.

---

## ex — ex commands

### ex-01 *(level:2, tags: norm)*
- **prompt**: Append `;` to every line in the buffer.
- **target**: `:%norm A;<CR>`
- **accept**: every line now ends with `;`.

### ex-02 *(level:2, tags: g, norm)*
- **prompt**: On every line containing `TODO`, prefix it with `// REVIEW: `.
- **target**: `:g/TODO/norm I// REVIEW: <CR>`
- **accept**: prefix added only to TODO lines.

### ex-03 *(level:3, tags: argdo)*
- **prompt**: For every file in the current arglist, replace `oldName` with `newName` and save.
- **target**: `:argdo %s/oldName/newName/ge | update<CR>`
- **accept**: substitution applied across the arglist.

### ex-04 *(level:3, tags: bufdo)*
- **prompt**: Save every modified buffer.
- **target**: `:bufdo update<CR>` *(or `:wa`)*
- **accept**: no `[+]` modified marker on any buffer.

### ex-05 *(level:3, tags: cdo, quickfix)*
- **prompt**: After `:grep foo`, replace `foo` with `bar` in every quickfix entry and save.
- **target**: `:cdo s/foo/bar/g | update<CR>`
- **accept**: substitution applied per quickfix line.

### ex-06 *(level:3, tags: ranges, lambda)*
- **prompt**: Sort lines 10-25 by length.
- **target**: `:10,25 sort<CR>` *(or with `n` for numeric)*
- **accept**: lines reordered within range.

---

## fw — folds & windows

### fw-01 *(level:1, tags: fold-toggle)*
- **prompt**: Open all folds, then close all folds, then close the fold under the cursor.
- **target**: `zR`, `zM`, `zc`
- **accept**: fold under cursor collapsed; others collapsed.

### fw-02 *(level:2, tags: fold-jump)*
- **prompt**: Move down one fold, then back up one fold.
- **target**: `zj`, `zk`
- **accept**: cursor on the first/last line of the next/prev fold.

### fw-03 *(level:1, tags: window-split)*
- **prompt**: Split the current window vertically, then horizontally, then close the new horizontal split.
- **target**: `<C-w>v`, `<C-w>s`, `<C-w>c`
- **accept**: 2 windows remain (orig + vertical split).

### fw-04 *(level:2, tags: window-resize, window-equal)*
- **prompt**: Make all windows equal size, then make the current window the tallest available.
- **target**: `<C-w>=`, `<C-w>_`
- **accept**: layout changes accordingly.

### fw-05 *(level:2, tags: window-move)*
- **prompt**: Cycle through windows (next, then back).
- **target**: `<C-w>w`, `<C-w>W`
- **accept**: focus moves between windows.

---

## lsp — LSP-driven (0.11+ defaults)

### lsp-01 *(level:1, tags: hover, K)*
- **prompt**: Show hover documentation for the symbol under the cursor.
- **target**: `K`
- **accept**: floating doc window appears.

### lsp-02 *(level:1, tags: definition)*
- **prompt**: Jump to the definition of the symbol under the cursor, then back.
- **target**: `gd`, `<C-o>`
- **accept**: cursor lands on definition, then returns.

### lsp-03 *(level:2, tags: references)*
- **prompt**: Find all references to the symbol under the cursor.
- **target**: `grr`
- **accept**: quickfix or telescope lists references.

### lsp-04 *(level:2, tags: implementations)*
- **prompt**: Jump to implementations of the interface/trait method under the cursor.
- **target**: `gri`
- **accept**: quickfix or picker shows impls.

### lsp-05 *(level:2, tags: code-action)*
- **prompt**: Trigger code actions on the current line and pick the first one.
- **target**: `gra`, then select
- **accept**: action menu appears.

### lsp-06 *(level:2, tags: rename)*
- **prompt**: Rename the symbol under the cursor.
- **target**: `grn`, type new name, `<CR>`
- **accept**: every reference renamed.

### lsp-07 *(level:1, tags: outline)*
- **prompt**: Open the document symbol outline for the current buffer.
- **target**: `gO`
- **accept**: symbol picker / loclist appears.

### lsp-08 *(level:2, tags: diagnostic-jump)*
- **prompt**: Jump to the next diagnostic, then to the previous error-level diagnostic only.
- **target**: `]d`, `[D` *(or `:lua vim.diagnostic.jump({count=-1, severity=vim.diagnostic.severity.ERROR})`)*
- **accept**: cursor moves to a diagnostic location.

---

## ts — treesitter / structural

### ts-01 *(level:2, tags: vaf, function)*
- **prompt**: Visually select the entire function under the cursor.
- **target**: `vaf`
- **accept**: selection covers function header through closing brace.

### ts-02 *(level:2, tags: vif, function-body)*
- **prompt**: Visually select the *body* of the function under the cursor (no signature, no braces).
- **target**: `vif`
- **accept**: selection covers body lines only.

### ts-03 *(level:2, tags: next-function)*
- **prompt**: Jump to the start of the next function definition.
- **target**: `]m`
- **accept**: cursor on next function header.

### ts-04 *(level:3, tags: param-swap)*
- **prompt**: Swap the current function parameter with the next parameter.
- **target**: `<Leader>a` *(or whatever the swap-next mapping is — see `treesitter.lua`)*
- **accept**: parameters reordered, no syntax break.

### ts-05 *(level:3, tags: incremental-selection)*
- **prompt**: Use incremental selection to grow the visual selection from the symbol up through enclosing scopes.
- **target**: configured `init_selection` then `node_incremental` repeatedly *(check user's `treesitter.lua`)*
- **accept**: selection grows scope by scope.

---

## Index

Total drills: **70**
- hd: 7  • wm: 9  • to: 10  • op: 9  • ss: 9  • mj: 6
- rg: 7  • mc: 5  • ex: 6  • fw: 5  • lsp: 8  • ts: 5

Suggested **warmup pool** (level:1 only): `hd-01 hd-02 hd-03 wm-01 wm-04 to-01 to-02 to-03 op-01 op-02 op-03 ss-01 ss-02 mj-04 rg-01 rg-02 fw-01 fw-03 lsp-01 lsp-02 lsp-07`.

Suggested **daily core** (level:2): everything tagged `level:2`.

Suggested **stretch** (level:3): everything tagged `level:3`. Run only after the user has cleared most of `level:2`.

## Adding new drills

When a new drill is added, increment the per-domain counter, set `level`, tag any keys it exercises, add to `Index`. Do **not** renumber existing IDs — `drill-state.md` references them by stable ID.
