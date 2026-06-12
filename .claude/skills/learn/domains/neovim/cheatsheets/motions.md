# motions, text objects, operators, registers

## Cursor motions

| Key | Motion |
|-----|--------|
| `h` `j` `k` `l` | left / down / up / right |
| `gj` `gk` | visual line down/up (your j/k do this when no count) |
| `w` `W` | next word / WORD start |
| `b` `B` | prev word / WORD start |
| `e` `E` | next word / WORD end |
| `ge` `gE` | prev word / WORD end |
| `0` `^` `$` | line start / first non-blank / line end |
| `f{c}` `F{c}` | find char forward / backward |
| `t{c}` `T{c}` | till char forward / backward |
| `;` `,` | repeat last f/F/t/T / reverse |
| `{` `}` | prev / next paragraph |
| `(` `)` | prev / next sentence |
| `%` | matching bracket |
| `gg` `G` | file start / end |
| `{n}G` `:{n}` | go to line n |
| `H` `M` `L` | screen top / middle / bottom |
| `C-d` `C-u` | half-page down / up |
| `C-f` `C-b` | full page down / up |
| `zz` `zt` `zb` | center / top / bottom cursor line |
| `C-o` `C-i` | jump list back / forward |
| `g;` `g,` | change list older / newer |

## Text objects (use after operator or in visual)

| Object | Inner (`i`) | Outer (`a`) |
|--------|-------------|-------------|
| word | `iw` | `aw` (includes surrounding space) |
| WORD | `iW` | `aW` |
| sentence | `is` | `as` |
| paragraph | `ip` | `ap` |
| `()` | `i)` `ib` | `a)` `ab` |
| `{}` | `i}` `iB` | `a}` `aB` |
| `[]` | `i]` | `a]` |
| `<>` | `i>` | `a>` |
| `""` | `i"` | `a"` |
| `''` | `i'` | `a'` |
| `` `` `` | `` i` `` | `` a` `` |
| tag | `it` | `at` |

### Treesitter text objects (your config)

| Object | Inner | Outer |
|--------|-------|-------|
| function | `if` | `af` |
| class | `ic` | `ac` |
| parameter | `ia` | `aa` |

Swap parameters: `<Leader>a` next, `<Leader>A` prev.

## Operators

| Key | Operator |
|-----|----------|
| `d` | delete |
| `c` | change (delete + insert) |
| `y` | yank |
| `gq` | format (wrap to textwidth) |
| `=` | auto-indent |
| `>` `<` | shift right / left |
| `gu` `gU` | lowercase / uppercase |
| `g~` | toggle case |
| `g@` | call operatorfunc |
| `!` | filter through external program |

Doubled operator = linewise: `dd` `cc` `yy` `gqq` `==` `>>` `<<` `guu` `gUU`.

## Composition: operator + motion/text-object

```
d2w          delete 2 words
ci"          change inside quotes
yap          yank around paragraph
gUiw         uppercase inner word
>i}          indent inside braces
daf          delete outer function (treesitter)
cia          change inner parameter (treesitter)
3dd          delete 3 lines
```

Count placement: `2dw` = `d2w`. Count on both multiplies: `2d3w` = delete 6 words.

## Registers

| Register | Name | Description |
|----------|------|-------------|
| `""` | unnamed | last d/c/y/s/x (your clipboard = unnamedplus, so this syncs) |
| `"0` | yank | last yank only (not affected by d/c) |
| `"1`-`"9` | numbered | last 9 deletes (1=newest, shift down) |
| `"a`-`"z` | named | user storage (lowercase=set, uppercase=append) |
| `"+` | clipboard | system clipboard (synced via unnamedplus) |
| `"*` | selection | primary selection (X11; same as + on macOS) |
| `"_` | black hole | discard, clobbers nothing |
| `"/` | search | last search pattern (read-only) |
| `".` | last insert | last inserted text (read-only) |
| `":` | command | last ex command (read-only) |
| `"%` | filename | current filename (read-only) |
| `"=` | expression | evaluate expression, paste result |

## Insert-mode register paste

`C-r {reg}` inserts register contents at cursor in insert mode.

```
C-r "        paste unnamed register
C-r 0        paste last yank
C-r +        paste system clipboard
C-r =2+2<CR> paste expression result (4)
C-r /        paste last search pattern
C-r %        paste current filename
```

## Common patterns

```
"_d{motion}     delete without clobbering unnamed register
"_dw            delete word, keep yank intact
"0p             paste last yank (ignores intermediate deletes)
"Ayy            append current line to register a
"ap             paste register a
"+y{motion}     explicit yank to system clipboard (redundant w/ unnamedplus)
diw"0P          replace word with last yank
```

Visual mode paste: `p` replaces selection with register but clobbers unnamed.
To paste repeatedly over selections: `"0p` or `"_dP`.
