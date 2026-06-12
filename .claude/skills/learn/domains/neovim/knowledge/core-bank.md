# Core Editing Topic Bank
Updated: 2026-05-31

## beginner

### The operator-motion grammar
Neovim's editing model is a composable language: [count] operator [count] motion. An operator (d, c, y, >, =) specifies _what_ to do, and a motion (w, $, }, f<char>) specifies _where_. Because operators and motions combine freely, learning 10 operators and 15 motions gives you 150 commands instead of 150 separate keybindings. Normal mode is not a restriction -- it is the state where you compose these verbs and nouns into precise, repeatable edits.
**Key concepts:** operator, motion, count, composability, normal mode as command language, text objects as nouns
**Tip:** Your config sets `timeoutlen = 300` (options.lua), which means multi-key operator sequences must be completed within 300ms. If you find yourself timing out on complex sequences like `gUiw`, you can temporarily increase timeoutlen while building muscle memory, then lower it back once fluent.
**Tool anchor:** `:help operator`, `:help motion.txt`
**Drill:** Open a C++ header file from your SBE codec project. Without using visual mode, perform these edits using only operator+motion: (1) delete from cursor to end of line, (2) change the word under cursor, (3) yank from cursor to the matching brace, (4) indent the current paragraph, (5) uppercase the current word. Name the exact keystrokes for each.
**Tags:** operator, motion, composability, grammar, normal-mode

### Character and line motions
The most fundamental motions move by character (h/l), line (j/k), and screen position. `0` goes to column 1, `^` to first non-blank, `$` to end of line. `H/M/L` jump to the top/middle/bottom of the visible screen. `gg` goes to line 1, `G` to last line, and `{count}G` or `:{count}` to a specific line. Because your config enables relativenumber, the line numbers in the gutter directly tell you the count needed for `{count}j` or `{count}k` jumps.
**Key concepts:** h/j/k/l, 0/^/$, H/M/L, gg/G, line addressing, relative line numbers as count hints
**Tip:** Your keymaps.lua remaps `j`/`k` to `gj`/`gk` when no count is given, so bare `j`/`k` move by display lines (useful for wrapped text) while `5j` still moves by buffer lines. This is the correct setup -- use counts for precise jumps and bare j/k for visual scanning.
**Tool anchor:** `:help left-right-motions`, `:help up-down-motions`
**Drill:** Open a 500+ line C++ source file. Starting from line 1: jump to line 42 using the most efficient motion, then go to the middle of the screen with one keystroke, then jump to the last line, then back to where you were. Time yourself and identify which motion you used for each jump. Now repeat the same sequence using only `j` with counts read from the relativenumber gutter.
**Tags:** motions, hjkl, line-navigation, relative-numbers, screen-position

### Word motions
`w` moves to the start of the next word, `b` to the start of the previous word, and `e` to the end of the current/next word. WORD motions (`W/B/E`) treat any non-blank sequence as a word, skipping over punctuation that `w/b/e` would stop at. In C++ code, `cw` on `std::vector` changes only `std` (stopping at `:`), while `cW` changes the entire `std::vector`. Counts compose: `3w` skips three words forward, and `d2W` deletes two WORDs.
**Key concepts:** word vs WORD, w/W/b/B/e/E, word boundaries, punctuation sensitivity, count composition
**Tip:** When editing SBE field names like `MDEntryType` or `SecurityID`, `w` treats camelCase transitions as the same word because there is no separator. Use `W` for these identifiers, or consider a CamelCase motion plugin if you frequently edit within camelCase boundaries.
**Tool anchor:** `:help word-motions`, `:help word`
**Drill:** Place your cursor on the first character of a CME MDP 3.0 template like `MDIncrementalRefreshBook46`. Use `w` repeatedly and note where it stops. Then go back and use `W` -- note the difference. Now delete to the end of the next WORD with `dW`, undo, and delete to the end of the next word with `dw`. Explain when you would prefer each in your C++ codebase.
**Tags:** word, WORD, word-motions, counts, cw-vs-cW

### Find and till on line
`f{char}` jumps forward to the next occurrence of `{char}` on the current line; `t{char}` jumps to just _before_ it. `F` and `T` search backward. After any f/t/F/T, `;` repeats the search in the same direction and `,` reverses it. These are some of the most powerful motions for precise intra-line editing: `dt)` deletes everything up to (but not including) the closing paren, `cf"` changes up to and including the next quote, and `vf;` visually selects through the next semicolon.
**Key concepts:** f/F/t/T, ;/,, operator+find composition, dt)/cf)/vf, intra-line precision
**Tip:** In C++ code with chained method calls like `book.getLevel(0).getPrice()`, use `f.` to jump to the first dot, then `;` to hop to each subsequent dot. Combine with operators: `ct.` changes everything up to the next dot, perfect for replacing one segment of a qualified name.
**Tool anchor:** `:help f`, `:help t`, `:help ;`
**Drill:** On the line `template<uint16_t BlockLength, uint16_t TemplateId, uint16_t SchemaId>`, position your cursor at the start. Use `f<` to jump to the angle bracket, then `dt>` to delete the first parameter. Undo and try `f,;` to jump to the second comma. Practice using `;` to chain through all commas, then use `ct,` to change just one parameter. Count how many keystrokes each approach takes.
**Tags:** find, till, f-t-semicolon, intra-line, operator-composition

### Basic text objects
Text objects define regions of text based on structure: `iw` is the inner word (no surrounding space), `aw` is "a word" (including trailing space). The same inner/around pattern applies to quotes (`i"/a"`), parentheses (`i(/a(`), braces (`i{/a{`), angle brackets (`i</a<`), and tags (`it/at`). Text objects only work with operators or in visual mode, not as standalone motions. They always select the complete structural unit regardless of cursor position within it, making them cursor-position-independent.
**Key concepts:** inner vs around, iw/aw, i"/a", i(/a(, i{/a{, i</a<, cursor-position independence, operator+textobject
**Tip:** Your treesitter-textobjects config adds structural text objects like `if` (inner function), `af` (around function), `ia` (inner argument/parameter), `aa` (around argument). These extend the same inner/around pattern to code structures. Use `cia` to change a function argument regardless of where your cursor sits within that argument.
**Tool anchor:** `:help text-objects`, `:help v_a`, `:help v_i`
**Drill:** In your C++ SBE decoder, find a function call like `encoder.encode(buffer, offset, length)`. Place your cursor anywhere on `offset`. Execute `cia` to change just that argument using your treesitter textobject. Undo. Now try `da(` to delete everything inside and including the parentheses. Undo. Try `di{` on a brace block. Note how text objects free you from caring about exact cursor position.
**Tags:** text-objects, inner, around, iw, aw, structural-selection

### The dot command
The dot command (`.`) repeats the last change -- the last sequence from entering insert mode (or the last operator+motion) through returning to normal mode. Designing edits to be "dot-friendly" means structuring your first edit so that `.` does exactly the right thing at the next location. For example, `ciw` + new text + Esc is dot-friendly because `.` will change whatever word the cursor is on, whereas `R` + retyping is not because the replacement length is baked in.
**Key concepts:** dot command, last change, dot-friendly edits, repeatable patterns, ciw+dot, A+dot
**Tip:** The most powerful dot pattern in day-to-day C++ editing is: search with `/pattern`, make your edit (e.g., `ciw` + new name), then `n` to jump to next match and `.` to repeat the edit. This gives you manual control over each replacement -- safer than `:%s` when some matches should be skipped.
**Tool anchor:** `:help .`, `:help repeat.txt`
**Drill:** In a C++ source file, rename a local variable that appears 8 times. First do it with `:%s/old/new/gc` and count the keystrokes. Then undo all and do it with `/old` + `ciwnew<Esc>` + `n.n.n.n.n.n.n.`. Compare the two approaches: which gives you more control? Which is faster when you want to skip some occurrences?
**Tags:** dot-command, repeatability, dot-friendly, change-repeat, efficiency

### Undo, redo, and undo tree
`u` undoes the last change and `C-r` redoes it. Unlike most editors that have a linear undo stack, Neovim maintains a full undo tree: if you undo three times and then make a new edit, the undone changes are not lost -- they become a branch you can revisit with `g-` (go to older state by time) and `g+` (go to newer state by time). Your config enables `undofile` with `undolevels = 10000`, meaning undo history persists across sessions and survives Neovim restarts.
**Key concepts:** u, C-r, undo tree vs undo stack, undo branches, g-/g+, persistent undo, undofile
**Tip:** Because your config sets `opt.undofile = true` and `opt.undolevels = 10000`, every file you edit has a persistent undo history saved in `~/.local/state/nvim/undo/`. This means you can close a C++ file, reopen it days later, and still undo changes from the previous session. Check `:echo &undodir` to see where the files live.
**Tool anchor:** `:help undo-tree`, `:help 'undofile'`, `:help g-`
**Drill:** Open any file and make five distinct edits (insert some text, delete a line, change a word, add a line, delete a word). Undo three times with `u`. Now make a completely different edit. You have created an undo branch. Use `g-` repeatedly to walk backward through time to your original state. Use `g+` to walk forward. Verify that both the undone branch and the new edit are accessible. Now close and reopen the file and confirm `u` still works from persistent undo.
**Tags:** undo, redo, undo-tree, persistent-undo, undofile, g-minus-g-plus

### Visual mode
Visual mode (`v` for characterwise, `V` for linewise, `C-v` for blockwise) lets you select a region first, then apply an operator. While normal mode's operator+motion is usually more efficient, visual mode excels when the target region is hard to express as a single motion. `gv` reselects the last visual selection, and `o` swaps the cursor to the other end of the selection so you can adjust both boundaries. After applying an operator, you return to normal mode automatically.
**Key concepts:** v/V/C-v, select-then-operate, gv reselect, o swap anchor, visual vs operator-motion tradeoffs
**Tip:** Your keymaps.lua remaps `<` and `>` in visual mode to `<gv` and `>gv`, which reselects after indenting. This is a common quality-of-life fix -- without it, visual mode deselects after the operator, and you would need `gv` + `>` to indent again. This makes repeated indentation of a block trivial: `V` select, then `>>>` for three levels.
**Tool anchor:** `:help visual-mode`, `:help v_o`, `:help gv`
**Drill:** Open a C++ file with a class definition. Use `V` to select the entire class body, then `>` to indent it. Note how the selection is preserved (thanks to your `>gv` mapping). Now use `C-v` (block visual) to select a column of spaces at the beginning of 10 lines and delete them with `d`. Use `gv` to reselect and `I` to insert a different prefix. Practice `o` to adjust selection boundaries in both directions.
**Tags:** visual-mode, characterwise, linewise, blockwise, gv, reselect

### Basic search and navigation
`/pattern` searches forward, `?pattern` searches backward. `n` repeats in the same direction, `N` reverses. `*` searches forward for the word under the cursor, `#` searches backward. Your config sets `ignorecase = true` and `smartcase = true`, meaning searches are case-insensitive unless you include an uppercase letter. `inccommand = "nosplit"` gives you a live preview of search matches as you type. Pressing `<Esc>` in normal or insert mode clears the highlight (your keymaps.lua maps Esc to `:noh`).
**Key concepts:** /, ?, n, N, *, #, ignorecase, smartcase, hlsearch, incsearch/inccommand
**Tip:** With `smartcase` enabled, searching `/encode` matches `encode`, `Encode`, and `ENCODE`, but `/Encode` matches only `Encode`. This is ideal for C++ where you might search for a method name case-insensitively but want to narrow to a specific casing. Use `\C` to force case-sensitive search regardless of smartcase.
**Tool anchor:** `:help /`, `:help 'smartcase'`, `:help 'inccommand'`
**Drill:** In a C++ file with mixed-case identifiers like `MessageHeader`, `messageHeader`, and `MESSAGE_HEADER`, search for `/message` and note which matches highlight. Then search for `/Message` and note the difference (smartcase in action). Use `*` on `MessageHeader` and observe that it wraps around the file. Press `<Esc>` to clear highlights (your mapping). Now search with `/\CMessage` to force exact case matching.
**Tags:** search, smartcase, ignorecase, hlsearch, inccommand, star-hash

### Insert mode essentials
`i` inserts before cursor, `a` after, `o` opens a new line below, `I` inserts at first non-blank, `A` appends at end of line, `O` opens above. Inside insert mode, `C-w` deletes the previous word, `C-u` deletes to the start of the line, and `C-o` lets you execute one normal-mode command before returning to insert mode. `C-r{register}` pastes a register's contents inline. These insert-mode shortcuts let you make corrections without leaving insert mode for trivial fixes.
**Key concepts:** i/a/o/I/A/O, C-w/C-u in insert, C-o one-shot normal, C-r register paste, insert-mode efficiency
**Tip:** `C-o` is powerful for one-shot corrections: if you are typing and realize you need to delete the line above, `C-o` + `kdd` does it without leaving insert mode. But beware: `C-o` breaks the undo sequence, so the change before and after `C-o` become separate undo steps. For dot-repeat purposes, minimize `C-o` usage.
**Tool anchor:** `:help inserting`, `:help i_CTRL-O`, `:help i_CTRL-R`
**Drill:** Open a new buffer and type a function signature. Without ever pressing `<Esc>`: use `C-w` to delete the last word you typed, `C-u` to delete back to the start of the line, `C-o` to jump to normal mode and delete the line above, then `C-r"` to paste the default register's contents. Practice the full cycle of insert-mode editing without returning to normal mode.
**Tags:** insert-mode, i-a-o, ctrl-w, ctrl-u, ctrl-o, ctrl-r

## intermediate

### Operators deep dive
Beyond the common `d/c/y`, Neovim has operators for formatting (`gq`), equalizing indent (`=`), shifting (`>/<`), uppercasing (`gU`), lowercasing (`gu`), and toggling case (`g~`). Doubling an operator applies it linewise: `dd` deletes a line, `yy` yanks a line, `gUU` uppercases the entire line. `D` is shorthand for `d$`, `C` for `c$`, and `Y` was remapped in Neovim to `y$` (unlike Vim's legacy `yy` behavior). Each operator follows the same grammar, so `gqap` formats a paragraph, `=i{` reindents a brace block, and `gUiw` uppercases a word.
**Key concepts:** d/c/y/gq/=/>/</gu/gU/g~, double-tap for linewise, D/C/Y shortcuts, operator consistency
**Tip:** `=` is underused but invaluable for C++ code formatting: `=i{` reindents the contents of the current brace block, and `gg=G` reindents the entire file. However, since your config has conform.nvim for autoformatting with clang-format, you may prefer `=` for quick local fixes and let conform handle full-file formatting on save.
**Tool anchor:** `:help operator`, `:help gq`, `:help =`
**Drill:** In a C++ source file: (1) use `gUiw` to uppercase a variable name, then `.` to repeat on another; (2) use `gqap` to reflow a multi-line comment to `textwidth`; (3) visually select 5 lines of poorly indented code and use `=` to fix indentation; (4) use `g~$` to toggle case from cursor to end of line. Verify each operator follows the same [operator][motion/textobject] grammar.
**Tags:** operators, gq, gU, gu, g-tilde, equal-indent, operator-grammar

### Registers
Every yank and delete goes into the unnamed register (`""`), the yank register (`"0`) always holds the last yank, and `"1`-`"9` form a delete history stack (each new delete pushes older ones down). Named registers `"a`-`"z` are user-controlled storage, and uppercase `"A`-`"Z` _append_ to the corresponding lowercase register. `"+` is the system clipboard (your config sets `clipboard = "unnamedplus"`, so `""` and `"+` are synced). `"_` is the black hole (delete without polluting registers). `".` holds last inserted text, `"%` the current filename, `"/` the last search pattern, `":` the last ex command.
**Key concepts:** "", "0, "1-"9, "a-"z append, "+, "_, special registers, clipboard sync, :reg
**Tip:** Since your config sets `clipboard = "unnamedplus"`, every `y`/`d`/`c` syncs to the system clipboard. This means `dd` overwrites your clipboard. To delete without clobbering the clipboard, prefix with the black hole register: `"_dd`. For staging multiple yanks, use named registers: `"ayiw` saves a word in register `a`, `"byy` saves a line in register `b`, then paste each with `"ap` or `"bp`.
**Tool anchor:** `:help registers`, `:reg`, `:help "0`
**Drill:** Yank a function name with `"ayiw`, then yank a different line with `"byy`. Delete three lines with `dd` (this goes into `""` and `"1`). Now paste: `"ap` for the function name, `"bp` for the line, `"1p` for the deleted lines. Inspect all registers with `:reg`. Use your Telescope register picker (`<Leader>fr`) to browse and paste from registers interactively.
**Tags:** registers, clipboard, named-registers, black-hole, yank-register, unnamedplus

### Macros
Record a macro with `q{register}`, execute keystrokes, then `q` to stop. Replay with `@{register}`, and `@@` repeats the last macro. For robust macros, start each iteration at a predictable position: `0` or `^` at the start, and end with `j` to move to the next line so `10@a` processes 10 lines. You can execute a macro on visual lines with `:norm @a` (or `:'<,'>norm @a`), which runs the macro on each selected line independently. Macros are just register contents, so you can yank a macro to edit it.
**Key concepts:** q{register}, @{register}, @@, :norm @a, robust macro patterns, j0 endings, macro as register
**Tip:** When editing repetitive C++ SBE field declarations (same pattern, different names), record a macro that transforms one line, ending with `j0` to position for the next. Then `20@a` processes 20 fields. If the macro should stop on error (e.g., search fails), that is the default behavior -- a failed search inside a macro aborts it, which is useful as a natural termination condition.
**Tool anchor:** `:help recording`, `:help @`, `:help :normal`
**Drill:** Create a file with 10 lines of the form `int fieldName = 0;`. Record a macro in register `q` that: (1) goes to the start of the line `0`, (2) changes `int` to `uint32_t` with `cw`, (3) goes to the `=` and changes `0` to `{}` with `f=lC{};`, (4) moves down with `j`. Replay with `9@q`. If a line breaks the pattern, observe how the macro halts. Edit the macro by pasting register q (`"qp`), modifying it, and yanking back (`"qyy`).
**Tags:** macros, recording, replay, norm-macro, register-editing, batch-editing

### Screen positioning
`zz` centers the current line on screen, `zt` moves it to the top, and `zb` to the bottom. `C-d`/`C-u` scroll half a screen down/up, and `C-f`/`C-b` scroll a full screen. Your config sets `scrolloff = 4`, which keeps 4 lines of context above and below the cursor at all times, preventing the cursor from reaching the very edge of the screen. Understanding these commands eliminates the habit of mashing `j/k` to reposition and lets you keep your eyes on the code rather than the cursor.
**Key concepts:** zz/zt/zb, C-d/C-u/C-f/C-b, scrolloff, screen awareness, centering after jumps
**Tip:** A productive habit is to follow any large jump (search, goto definition, quickfix navigation) with `zz` to center context around the landing point. Some users map `n` to `nzz` and `N` to `Nzz` to auto-center after every search match. Your `scrolloff = 4` already helps, but `zz` after `gd` (goto definition) is especially valuable when reading unfamiliar code.
**Tool anchor:** `:help scroll.txt`, `:help 'scrolloff'`, `:help zz`
**Drill:** Open a long C++ file (300+ lines). Jump to a function in the middle with `/function_name`. Note the cursor position on screen. Now press `zt` to bring it to the top, `zb` to the bottom, `zz` to center. Navigate through the file using only `C-d` and `C-u` (no j/k). Notice how `scrolloff = 4` ensures you always see context. Practice the pattern: `gd` (goto definition) then `zz` to center, and build this into muscle memory.
**Tags:** scrolling, zz, zt, zb, scrolloff, screen-positioning, C-d, C-u

### Treesitter text objects
Your config defines structural text objects via nvim-treesitter-textobjects: `af/if` for functions, `ac/ic` for classes, `aa/ia` for parameters/arguments. These work with any operator: `daf` deletes an entire function, `cia` changes a function argument, `yic` yanks a class body. The move mappings `]m/[m` jump between function starts and `]]/[[` between class starts, with `]M/[M` and `][/[]` for ends. The `<Leader>a`/`<Leader>A` mappings swap parameters, letting you reorder function arguments without cut-and-paste.
**Key concepts:** af/if, ac/ic, aa/ia, ]m/[m, ]]/[[, parameter swap, lookahead, treesitter structural editing
**Tip:** The `lookahead = true` setting in your treesitter-textobjects config means `daf` will delete the next function even if your cursor is not inside a function body -- it looks ahead to find the nearest one. This is convenient but can be surprising: always verify which function is highlighted before executing a destructive operator.
**Tool anchor:** `:help nvim-treesitter-textobjects`, `:help ]m`
**Drill:** Open a C++ file with multiple functions and a class. (1) Use `]m` to jump through function starts and `[m` to go back. (2) Position inside a function and `daf` to delete it entirely, then `u` to undo. (3) On a function call with 3 arguments, use `<Leader>a` to swap the second and third arguments, then `<Leader>A` to swap them back. (4) Use `vic` to visually select a class body. Compare the precision of treesitter text objects vs manual `V` + motion selection.
**Tags:** treesitter, text-objects, function-object, class-object, parameter-swap, structural-editing

### Search and substitute
`:s/old/new/` substitutes the first occurrence on the current line; add `g` flag for all occurrences on the line. `:%s/old/new/g` operates on every line in the file. Ranges like `:5,20s/` limit the scope, and `:'<,'>s/` works on a visual selection. The `c` flag prompts for confirmation at each match (`y/n/a/q/l`). Your `inccommand = "nosplit"` setting gives a live preview of substitutions as you type, highlighting what will change before you press Enter. Use `\v` (very magic) to avoid excessive backslash escaping in patterns.
**Key concepts:** :s/old/new/g, % scope, ranges, c confirm flag, \v very magic, inccommand live preview
**Tip:** With `inccommand = "nosplit"`, you get real-time visual feedback as you type `:%s/old/new/g` -- matches highlight and replacements appear inline before you commit. This is extremely valuable for C++ refactoring: you can see exactly which lines are affected, catch false positives, and adjust the pattern before executing. If the preview shows too many matches, narrow the range or add `c` for interactive confirmation.
**Tool anchor:** `:help :substitute`, `:help 'inccommand'`, `:help /\v`
**Drill:** In a C++ file, rename a variable from `msgSize` to `messageSize` using `:%s/msgSize/messageSize/gc` and observe the live preview. Then try a regex substitution: convert all `get_field()` getter calls to `field()` using `:%s/\vget_(\w+)/\1/gc`. Watch the inccommand preview update in real time. Practice using the confirmation prompt: `y` to replace, `n` to skip, `a` to replace all remaining.
**Tags:** substitute, search-replace, inccommand, very-magic, ranges, confirm-flag

### The global command (:g)
`:g/pattern/cmd` executes an ex command on every line matching the pattern. `:v/pattern/cmd` (or `:g!/pattern/cmd`) is the inverse, executing on non-matching lines. Common uses: `:g/TODO/d` deletes all TODO lines, `:g/^$/d` removes blank lines, `:g/pattern/m$` moves matching lines to end of file, and `:g/pattern/t.` copies matching lines below the current line. The global command processes lines top-to-bottom, and you can chain complex operations by combining with `:normal`.
**Key concepts:** :g/pattern/cmd, :v inverse, delete/move/yank/copy by pattern, :g + :norm, line processing order
**Tip:** For cleaning up C++ debug output, `:g/std::cout/d` removes all cout debug lines in one shot. For collecting scattered TODO comments, `:g/TODO/t$` copies them all to the end of the file without removing the originals. `:g/^#include/m0` moves all includes to the top of the file (processed in reverse order since each `:m0` pushes the previous one down).
**Tool anchor:** `:help :global`, `:help :v`
**Drill:** Create a test file with a mix of: function declarations, comments starting with `//`, blank lines, and lines containing `DEBUG`. (1) Use `:g/DEBUG/d` to remove all debug lines. Undo. (2) Use `:v/^\/\//d` to keep only comment lines. Undo. (3) Use `:g/^$/d` to remove blank lines. Undo. (4) Use `:g/void/norm A // TODO: add return type` to append a comment to every function returning void. Check the results after each command.
**Tags:** global-command, pattern-matching, bulk-editing, g-delete, g-move, g-norm

### Ex commands
Ex commands like `:m` (move), `:t` (copy/duplicate), `:d` (delete), and `:read` operate on line ranges. `:5m10` moves line 5 after line 10, `:5t10` copies line 5 after line 10, `:5,10d` deletes lines 5-10. `:norm` executes a normal-mode command on each line in a range: `:%norm A;` appends a semicolon to every line. Line addressing uses `.` (current), `$` (last), `%` (all), `'<,'>` (visual selection), and relative offsets like `.+3`. `:read !cmd` inserts command output below the cursor.
**Key concepts:** :m, :t, :d, :norm, line addressing, ranges, :read, :write range, ex command composition
**Tip:** `:t.` (copy current line below) is faster than `yyp` and does not touch any register, preserving your clipboard. For duplicating a line and modifying the copy, `:t.` followed by a change is cleaner than yank-paste-edit. Similarly, `:m+1` moves the current line down one position (swap with line below) without using registers.
**Tool anchor:** `:help :move`, `:help :copy`, `:help :normal`, `:help :range`
**Drill:** In a C++ header file: (1) use `:t.` to duplicate the current line and compare with `yyp` (check registers after each); (2) use `:5,10m$` to move lines 5-10 to the end; (3) use `:'<,'>norm I// ` to comment out a visual selection by prepending `// ` to each line; (4) use `:read !date` to insert the current date below the cursor; (5) use `:10,20w !pbcopy` (macOS) to pipe a line range to the clipboard.
**Tags:** ex-commands, move, copy, norm, line-addressing, ranges

### Count composition and efficiency
Counts can precede operators (`3dw` = delete 3 words), motions (`3w` = move 3 words), or both (`2d3w` = delete 6 words, though this is unusual). However, more keystrokes is not always worse: `dw...` (delete word, repeat three times) is sometimes preferable to `4dw` because you can stop after any repetition and undo one step at a time. The choice between counting and repeating depends on whether you know the exact count, how important fine-grained undo is, and whether you are setting up a dot-repeatable pattern.
**Key concepts:** count before operator, count before motion, count multiplication, count vs repeat tradeoffs, undo granularity
**Tip:** With `relativenumber` enabled in your config, you can instantly read the exact line count for vertical motions: the gutter shows how many lines away each line is. This makes `d12j` (delete 12 lines down) precise and fast. For horizontal motions, counts are harder to compute mentally -- prefer `f/t` for precision or `w/W` with small counts.
**Tool anchor:** `:help count`, `:help .`
**Drill:** Delete a 7-line block three ways: (1) `d7j` using the count from relativenumber, (2) `V6jd` using visual mode, (3) `dd......` with repeat. Time each approach. Now change 3 consecutive function arguments: try `3cia` (count + treesitter text object) vs `cia<Esc>...cia<Esc>...cia<Esc>`. Identify scenarios where counting wins and where repeating wins.
**Tags:** counts, efficiency, repeat-vs-count, relative-number, undo-granularity

### Paragraph, sentence, and section motions
`{` and `}` jump to the previous/next blank line (paragraph boundary), `(` and `)` jump by sentences (period followed by whitespace), and `[[`/`]]` jump by sections. In code, paragraphs correspond to blocks separated by blank lines (function bodies, class sections), making `{`/`}` an efficient way to hop between code blocks. Your treesitter config remaps `]]`/`[[` to class start navigation, which is more useful for C++ than the default section behavior. These motions work with operators: `d}` deletes to the next blank line, `y{` yanks the previous paragraph.
**Key concepts:** {/}, (/), [[/]], paragraph=blank-line-separated, sentence, section, code block navigation
**Tip:** In C++ files with consistent formatting (blank line between functions), `}` jumps to the next function boundary and `d}` deletes everything to the next blank line. Combine with `zz` for context: `}zz` jumps to the next block and centers it. For operator combinations, `dap` (delete around paragraph) is often more precise than `d}` because it includes the trailing blank line.
**Tool anchor:** `:help object-motions`, `:help {`, `:help ]]`
**Drill:** Open a C++ file with several functions separated by blank lines. Starting at the top: (1) use `}` repeatedly to jump through each function, then `{` to go back; (2) use `]]` and `[[` to jump by class starts (your treesitter mapping); (3) use `dap` to delete a function and its surrounding blank lines, then undo; (4) use `vap` to visually select a paragraph, then `gq` to reformat. Compare `}` with `]m` -- when do they land on the same line?
**Tags:** paragraph, sentence, section, block-navigation, object-motions

## advanced

### The cgn pattern
`cgn` combines the change operator with the `gn` motion (select the next search match). After searching for a pattern with `/` or `*`, `cgn` changes the next occurrence, and `.` repeats the change-next-match at each subsequent occurrence. Unlike `:s///gc`, the cgn pattern does not require a substitute command and works with complex motions and multi-line patterns. It is the most efficient surgical find-and-replace when you need to review each occurrence: `n` to preview, `.` to apply, or `n` to skip.
**Key concepts:** gn/gN motion, cgn, search-then-change, dot-repeat with gn, skip-or-apply workflow
**Tip:** For renaming a C++ variable that appears across multiple SBE message types, `*` on the variable (which sets the search register), then `cgn` + new name + `<Esc>`, then `n` to inspect each match and `.` to apply. This is strictly better than `:%s` with `c` flag because you stay in the buffer flow, see full context, and your cursor naturally moves through the code.
**Tool anchor:** `:help gn`, `:help v_gn`
**Drill:** In a C++ file, find a variable name like `seqNum` that appears 15 times. Use `*` to search for it, then `cgnsequenceNumber<Esc>` to change the first match. Now press `.` to change the next match, then `n` to skip one, then `.` to change the one after. Practice the skip-or-apply rhythm until all desired occurrences are renamed. Compare this workflow to `:%s/seqNum/sequenceNumber/gc` -- which feels more natural?
**Tags:** cgn, gn-motion, surgical-replace, dot-repeat, search-change

### Advanced macros
Recursive macros call themselves: `qaqqa...@aq` clears register `a`, starts recording, does the edit, calls `@a` recursively, and stops. The recursion halts when any command in the macro fails (e.g., a search finds no match). You can edit macro contents by pasting the register (`"ap`), editing the text, and yanking it back (`"ayy`). Alternatively, `:let @a = "..."` sets a register directly. For debugging, step through a macro by executing its contents one character at a time, or use `:norm @a` on a single line to test.
**Key concepts:** recursive macros, qaqqa, register editing, :let @a=, macro debugging, failure as termination
**Tip:** When processing a C++ file with an unknown number of SBE field definitions, a recursive macro is ideal: `qaqqa0f:dt,A,<Esc>j@aq`. The recursive call `@a` inside the recording means the macro runs until `j` fails (end of file) or `f:` fails (no colon on the line). This processes an arbitrary number of lines without knowing the count in advance.
**Tool anchor:** `:help q`, `:help :let-@`, `:help :normal`
**Drill:** Create a file with 20 lines of comma-separated key-value pairs like `name:value,extra`. Record a recursive macro that: clears register `a` with `qaq`, starts recording `qa`, changes the first `:` to ` = `, deletes everything after the comma, moves to the next line, calls `@a`, and stops with `q`. Execute with `@a` and watch it process all 20 lines. If it fails on line 12 due to a different format, paste the macro with `"ap`, fix it, yank back with `"ayy`, and retry.
**Tags:** recursive-macros, register-editing, let-register, macro-debugging, auto-termination

### Advanced substitute
The substitute command supports capture groups with `\(pattern\)` referenced as `\1`, `\2`, etc. in the replacement. The `\=` flag enables sub-replace-expressions: the replacement is a Vimscript/Lua expression evaluated for each match, enabling computed replacements. Lookahead `\(pattern\)\@=` and lookbehind `\(pattern\)\@<=` match positions without consuming text. With `\v` (very magic), you avoid most backslash escaping: `\v(\w+)_(\w+)` instead of `\(\w\+\)_\(\w\+\)`.
**Key concepts:** capture groups \(\)/\1, \= sub-replace-expression, lookahead/lookbehind, \v very magic, computed replacement
**Tip:** To convert C++ snake_case to camelCase in your SBE codec: `:%s/\v_(\l)/\u\1/g` captures the letter after each underscore and uppercases it with `\u`. To convert back: `:%s/\v(\u)/\_\l\1/g`. These regex patterns are essential for adapting between CME's naming conventions and your project's style guide. Use `inccommand` preview to verify before executing.
**Tool anchor:** `:help sub-replace-special`, `:help /\v`, `:help s/\=`
**Drill:** (1) Convert snake_case variable names to camelCase using capture groups: `:%s/\v_(\l)/\u\1/gc`. (2) Use sub-replace-expression to number lines: `:%s/^/\=line('.') . ': '/`. (3) Swap function arguments: on a line like `foo(a, b)`, use `:s/\v(\w+), (\w+)/\2, \1/`. (4) Use lookbehind to add `const` only after `int`: `:%s/\v(int )@<=(\w+)/const \2/gc`. Observe the inccommand preview for each.
**Tags:** substitute-advanced, capture-groups, sub-replace-expression, lookahead, lookbehind, very-magic

### Block visual mode mastery
`C-v` enters block (column) visual mode, selecting a rectangular region. `I` inserts text at the left edge of every selected line (applied on `<Esc>`), `A` appends at the right edge, `c` changes the selected block, and `d` deletes it. Block selections interact with `$` (extend to end of each line regardless of length) and virtualedit (your config sets `virtualedit = "block"`, allowing the cursor to move past end-of-line in block mode). This makes column editing, alignment, and multi-line insertion possible without macros.
**Key concepts:** C-v, block selection, I/A insert/append, c/d block operations, $ extend, virtualedit=block
**Tip:** Your config sets `virtualedit = "block"`, which means you can position the block cursor past the end of short lines -- essential for aligning columns when lines have different lengths. To add a comment column at position 60 on a set of lines of varying length: `C-v`, select the lines, `60|` to jump to column 60 (virtualedit lets you land there even on short lines), then `I// ` to insert.
**Tool anchor:** `:help blockwise-visual`, `:help 'virtualedit'`
**Drill:** Create a C++ enum with 10 members of different lengths. (1) Use `C-v` to select the first column of all 10 lines and `I  ` to indent them. (2) Select a rectangular region covering all the `=` signs and use `c` to change all values at once. (3) Use `C-v` + `$` to select from a column to end of each line (note the ragged selection) and `A` to append `// field` to every line. (4) With virtualedit, place the cursor past the end of a short line and insert text in a column that does not yet exist.
**Tags:** block-visual, column-editing, virtualedit, multi-line-insert, rectangular-selection

### The expression register ("=)
`C-r=` in insert mode or command-line mode opens the expression register, letting you type a Vimscript or Lua expression and insert its result. `:put =range(1,10)` inserts lines numbered 1-10. `C-r=system('date')` inserts the current date inline. The expression register can reference other registers, variables, and functions. In command-line mode, `C-r=expand('%:t')` inserts the current filename. This turns Neovim into a programmable text generator without leaving the editor.
**Key concepts:** "= expression register, C-r= in insert, :put =, computed values, inline evaluation, system() calls
**Tip:** When writing C++ test fixtures for SBE messages, you can generate field offset tables inline: in insert mode, `C-r=range(0, 36, 4)` inserts `[0, 4, 8, 12, 16, 20, 24, 28, 32, 36]`. For hex values, `:put =map(range(0,15), {_, v -> printf('0x%02X', v)})` generates a column of hex bytes. Combine with `:read !` for external tool output: `:read !python3 -c "print('\n'.join(str(i*4) for i in range(20)))"`.
**Tool anchor:** `:help "=`, `:help i_CTRL-R_=`, `:help :put`
**Drill:** (1) In insert mode, type `C-r=` and enter `42 * 7` to insert the computed result inline. (2) Use `:put =range(1,20)` to generate a numbered list. (3) In insert mode, use `C-r=system('git rev-parse --short HEAD')` to insert the current git commit hash. (4) Create a SBE-style offset table: `:put =map(range(0, 9), {_, v -> printf('  field_%d offset=%d', v, v*8)})`. Practice embedding computed values into code without leaving Neovim.
**Tags:** expression-register, computed-values, inline-evaluation, put-expression, system-calls

### Custom operators with g@/opfunc
You can create custom operators by setting `operatorfunc` and mapping to `g@`. When you press `g@{motion}`, Neovim calls your `operatorfunc` with the motion type (`char`, `line`, or `block`) and sets `'[`/`']` marks around the operated region. This lets you build operators that work with any motion or text object, following the same grammar as built-in operators. In Lua, use `vim.go.operatorfunc` and a named function, then map `g@` followed by optional motion hints.
**Key concepts:** g@, operatorfunc, '[/'] marks, motion type (char/line/block), custom operator pattern
**Tip:** A practical custom operator for C++ development: an operator that wraps the operated text in `std::move()`. Set operatorfunc to a function that reads the `'[` to `']` region, wraps it with `std::move(...)`, and replaces the original text. Then `g@iw` wraps a word, `g@i(` wraps parenthesized content, and it composes with any motion.
**Tool anchor:** `:help :map-operator`, `:help g@`, `:help operatorfunc`
**Drill:** Write a custom operator in your config that wraps the operated text in `/* */` comments: (1) define a Lua function that gets the text between `'[` and `']`, prepends `/* ` and appends ` */`; (2) set `vim.go.operatorfunc` to this function; (3) map a key (e.g., `gc`) to `g@`. Test it: `gciw` should comment a word, `gc$` should comment to end of line, `gcap` should comment a paragraph. Verify it works with visual mode too.
**Tags:** custom-operator, g-at, operatorfunc, composable-mapping, extensibility

### Custom text objects
Custom text objects are operator-pending (`o`) and visual (`x`) mode mappings that select a region of text. You define what "inner" and "around" mean for your custom structure by setting the visual selection programmatically. In Lua, use `vim.api.nvim_buf_get_lines()` to find boundaries and `vim.api.nvim_win_set_cursor()` + visual mode commands to select. Your treesitter-textobjects plugin already demonstrates this: `af/if` are custom text objects built on treesitter queries that select function nodes.
**Key concepts:** o-mode mappings, x-mode mappings, custom selection logic, treesitter queries for textobjects, inner/around convention
**Tip:** A useful custom text object for C++ is "inner/around template parameters": `i<` exists but only matches angle brackets literally, which fails on nested templates like `std::map<int, std::vector<double>>`. A treesitter-aware version would use the `template_argument_list` node to correctly handle nesting, which you can add as a custom query in your treesitter-textobjects config.
**Tool anchor:** `:help omap-info`, `:help textobjects`, `:help nvim-treesitter-textobjects-custom`
**Drill:** (1) Create a simple custom text object for C++ "include path" that selects the text between `<>` or `""` on an `#include` line. Define it as `o` and `x` mode mappings for `iI` and `aI`. (2) Test with `diI` to delete just the path, `ciI` to change it, `yaI` to yank with delimiters. (3) Examine your treesitter textobjects config to see how `@function.outer` is defined, and try adding a custom `@comment.outer` text object via a query file.
**Tags:** custom-text-objects, operator-pending, visual-mode-map, treesitter-queries, structural-selection

### Command-line window
`q:` opens the command-line window showing your ex command history as an editable buffer. `q/` and `q?` open the search history window. In any command-line prompt, `C-f` switches to the command-line window for full editing power (you can use motions, text objects, and even other commands to compose your command). Press `<CR>` on a line to execute it. This is invaluable for complex substitute commands: if your regex is almost right, `q:` lets you navigate to the previous attempt, edit it with full Neovim power, and re-execute.
**Key concepts:** q:, q/, C-f, command history as buffer, editing previous commands, execute with CR
**Tip:** When iterating on a complex `:s/` regex for refactoring C++ code, use `q:` to open command history, find your previous attempt, use normal editing commands to refine the pattern (e.g., `f/ci/` to change part of the regex), and press `<CR>` to re-execute. This is far faster than retyping or using `C-p` to recall and `C-b`/`C-f` to navigate within the command line.
**Tool anchor:** `:help cmdline-window`, `:help q:`, `:help c_CTRL-F`
**Drill:** (1) Run a complex substitute: `:%s/\v(\w+)_(\w+)\((\w+)\)/\2_\1(\3)/g`. (2) Press `q:` to open command-line window. (3) Navigate to the command you just ran and use `f/ci/` to change part of the pattern. (4) Press `<CR>` to execute the modified command. (5) Try `q/` to see your search history and edit a previous search pattern. (6) While typing a new `:s/` command, press `C-f` to switch to the command-line window mid-entry for easier editing.
**Tags:** command-line-window, command-history, q-colon, q-slash, regex-iteration

### :normal and scripted editing
`:norm {commands}` executes normal-mode commands on each line in a range. `:norm!` ignores user mappings, using only default Neovim behavior. Combined with `:g`, this becomes a scripted editing engine: `:g/pattern/norm! 0dwA;` finds all matching lines, deletes the first word, and appends a semicolon. For multi-line operations, `:norm` processes each line independently, which is more predictable than macros when line counts vary. This is the foundation of "edit as a program" thinking.
**Key concepts:** :norm, :norm!, :g + :norm, scripted editing, range operations, ignoring user mappings
**Tip:** When bulk-editing C++ SBE message field accessors, `:g/getter/norm! 0f(i const` finds every line containing "getter" and inserts ` const` before the opening parenthesis. The `!` in `:norm!` is critical: without it, your custom mappings may interfere. For example, if you have mapped `f` to something else, `:norm f(` would trigger your mapping instead of the built-in find.
**Tool anchor:** `:help :normal`, `:help :global`
**Drill:** Create a file with 20 C++ function declarations, some `const` and some not. (1) Use `:g/void/norm! A // void return` to annotate all void functions. (2) Use `:%norm! I//` to comment out the entire file. Undo. (3) Use `:'<,'>norm! 0f(a const` on a visual selection to add `const` after the parameter list of selected functions. (4) Compare `:norm` (uses your mappings) vs `:norm!` (ignores mappings) by trying both with your `j`/`k` remappings.
**Tags:** normal-command, scripted-editing, global-norm, bulk-transform, norm-bang

### Advanced repeat patterns
Beyond `.`, Neovim has several repeat mechanisms: `@:` repeats the last ex command, `:&&` repeats the last substitute with the same flags, and `&` on a line repeats the last substitute on the current line. For complex edits, designing for repeatability means choosing the right primitive: `.` for the last normal-mode change, `@:` for ex commands like `:m+1` or `:t.`, and `n.` for search-then-change patterns. Understanding which operations are "the last change" (and which are not) is key to efficient bulk editing.
**Key concepts:** @:, :&&, &, dot for normal changes, repeat hierarchy, designing repeatable edits
**Tip:** `@:` is powerful for incremental line operations: `:m+1` moves the current line down one, and `@:` repeats it. Each `@:` moves the line one more position down. Similarly, `:t.` duplicates the current line, and `@:` keeps duplicating. For your C++ workflow, `:m+1` with `@:` is a fast way to reorder function declarations without cut-and-paste.
**Tool anchor:** `:help @:`, `:help :&&`, `:help single-repeat`
**Drill:** (1) Run `:m+1` then press `@:` four times to move a line down by 5 positions total. (2) Run a substitute `:s/int/auto/` on one line, then use `&` on other lines to repeat the same substitution. (3) Design an edit that is dot-repeatable: `*cgnNewName<Esc>`, then use `n.` to repeat across the file. (4) Compare three repeat mechanisms on the task of appending `;` to 10 lines: `A;<Esc>j.` (dot), `:%norm! A;` (ex), and `:g/./norm! A;` (global). Which is fastest? Which gives finest control?
**Tags:** repeat, at-colon, ampersand, dot-repeat, bulk-editing, repeat-hierarchy
