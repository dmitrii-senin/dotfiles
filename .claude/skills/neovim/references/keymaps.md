# Reference: Keymap Philosophy + the User's Taxonomy

The user's keymap taxonomy is **already established and consistent**. Future sessions must respect it. This file is the source of truth for "no drift" rule in `SKILL.md`.

## Philosophy

1. **Vim's defaults are the ground truth.** Don't remap until you've felt friction with them.
2. **One leader, one mental tree.** `<Space>` as `<leader>`, `\` as `<localleader>`. Group keymaps by *workflow*, not by *plugin*.
3. **Consistency over cleverness.** Once a prefix means a thing, it always means that thing.
4. **Discoverable, not magical.** which-key.nvim teaches; mute it once memorized.
5. **Three-tier rule.** A keymap earns adding only if it earns daily use. Otherwise leave it as a Vim-native command.
6. **Cap.** Aim for ≤25 leader-prefixed maps in active use. Above that, you stop recalling them.

## The user's leader taxonomy (DO NOT DRIFT)

Source: `~/x/dotfiles/.config/nvim/lua/custom/core/keymaps.lua` and the per-plugin `keys = {…}` specs.

| Prefix             | Domain                                  | Examples (illustrative)                                                    |
| ------------------ | --------------------------------------- | -------------------------------------------------------------------------- |
| `<Leader>b*`       | **Buffers**                             | `<Leader>bb` switch to alt, `<Leader>bD` delete buffer + window            |
| `<Leader>w*`       | **Windows**                             | `<Leader>ws` split below, `<Leader>wv` split right, `<Leader>wd` close     |
| `<Leader>l*`       | **Lists** (loclist + qf)                | `<Leader>ll` loclist, `<Leader>lq` quickfix                                |
| `<Leader>c*`       | **Code** (LSP, formatting, diagnostics) | `<Leader>cf` format, `<Leader>cd` line diagnostics, `<Leader>ca` code action (proposed), `<Leader>rn` rename (proposed — note: 0.11 default is `grn`) |
| `<Leader>x*`       | **Execute / scratchy run**              | `<Leader>xf` run-current-file (cpp/c/python/rust/lua), `<Leader>xx` run line as Lua |
| `<Leader>f*`       | **Find** (telescope + similar)          | `<Leader>ff` files, `<Leader>fg` grep, `<Leader>fb` buffers, `<Leader>fn` new file, `<Leader>ft` LSP type-def |
| `<Leader>d*`       | **Debug** (DAP)                         | `<Leader>db` toggle breakpoint, `<Leader>dc` continue, `<Leader>do` step over, `<Leader>di` step into, `<Leader>du` toggle UI |
| `<Leader>t*`       | **Toggle / Test**                       | `<Leader>th` toggle inlay hints; `<Leader>tn`/`<Leader>tf`/`<Leader>tt` reserved for test runs (when neotest is added) |
| `<Leader>h*`       | **Help / man**                          | `<Leader>hh` `:help` for `<cword>`, `<Leader>hH` for `<cWORD>`, `<Leader>hm` `:Man` for `<cword>`, `<Leader>hM` for `<cWORD>` |
| `<Leader><tab>*`   | **Tabs**                                | `<Leader><tab><tab>` new, `<Leader><tab>l` last, `<Leader><tab>o` close-other, `<Leader><tab>f` first, `<Leader><tab>]` next, `<Leader><tab>[` prev, `<Leader><tab>d` close |
| `<Leader>q*`       | **Quit**                                | `<Leader>qq` quit-all                                                      |
| `<Leader>L`        | Lazy menu                               | one-shot                                                                   |
| `<Leader>M`        | Mason menu                              | one-shot                                                                   |
| `<Leader>a` / `<Leader>A` | Treesitter swap-parameter (next/prev) | locked by treesitter-textobjects setup                              |
| `<Leader>` (no leader chord) | (reserved space — most root-level Vim defaults stay native) | — |

### Non-leader maps already in use

| Keys                 | Action                                                    |
| -------------------- | --------------------------------------------------------- |
| `<S-h>` / `<S-l>`    | Buffer prev / next                                        |
| `[b` / `]b`          | Buffer prev / next (alias)                                |
| `]q` / `[q`          | Quickfix next / prev                                      |
| `]e` / `[e`          | Diagnostic next / prev (ERROR severity, `vim.diagnostic.jump`) |
| `]w` / `[w`          | Diagnostic next / prev (WARN severity)                    |
| `]m` / `[m`          | Treesitter: next/prev function start (textobjects)        |
| `]M` / `[M`          | Treesitter: next/prev function end                        |
| `]]` / `[[`          | Treesitter: next/prev class start                         |
| `][` / `[]`          | Treesitter: next/prev class end                           |
| `aa` / `ia`          | Text object: parameter (around / inner)                   |
| `af` / `if`          | Text object: function (around / inner)                    |
| `ac` / `ic`          | Text object: class (around / inner)                       |
| `<C-h/j/k/l>`        | Window navigation (also via zellij-nav for terminal panes) |
| `<M-S-Up/Down/Left/Right>` | Window resize                                       |
| `<C-s>`              | Save in any mode                                          |
| `<esc>` (in n/i)     | Clear hlsearch + escape                                   |
| `j` / `k` (n/x)      | Up/down with `gj`/`gk` when no count (visual line nav)    |

### Default LSP keymaps (Neovim 0.11+, mostly inherited; some Telescope-overridden)

| Keys     | Action                                                                                |
| -------- | ------------------------------------------------------------------------------------- |
| `K`      | Hover (built-in)                                                                      |
| `gd`     | Definition (overridden → `telescope.lsp_definitions`)                                 |
| `gD`     | Declaration (`vim.lsp.buf.declaration`)                                               |
| `grr`    | References (overridden → `telescope.lsp_references`)                                  |
| `gri`    | Implementation (overridden → `telescope.lsp_implementations`)                         |
| `gra`    | Code action (built-in default)                                                        |
| `grn`    | Rename (built-in default)                                                             |
| `gO`     | Document symbols (overridden → `telescope.lsp_document_symbols`)                      |
| `gW`     | Workspace symbols (added → `telescope.lsp_dynamic_workspace_symbols`)                 |
| `<C-s>` (insert) | Signature help (default since 0.11)                                            |
| `<C-x><C-o>` | Manual omnifunc completion fallback (always available, even with native completion) |

## Rules for proposing a new map

1. **Check this file first.** If the prefix already has a meaning, your new map must fit that meaning.
2. **Prefer prefix consistency over keyboard ergonomics.** `<Leader>tn` (test-nearest) is better than `<Leader>n` even if `<Leader>n` is faster.
3. **Don't shadow Vim defaults** unless you know what you're shadowing and have a reason. Examples to keep sacred: `K`, `*`, `#`, `gq`, `gv`, `g;`, `g,`, `''`, `` `` ``, `zz/zt/zb`.
4. **Always include a `desc`.** It powers `which-key`, `:map`, and your future-self.
5. **For per-filetype maps**, use `vim.api.nvim_create_autocmd("FileType", ...)` or a `ftplugin/<lang>.lua` so they're scoped.

## Example of a CORRECT addition

> User asks: "Add a keymap to run the test under cursor in Python."
>
> Wrong: `<Leader>p` → "test under cursor" (collides with no prefix; opaque).
> Right: `<Leader>tn` → "run nearest test" (fits `<Leader>t*` toggle/test prefix; readable; future-compatible with `<Leader>tf` test-file and `<Leader>tt` test-all).

## Example of a CORRECT refusal

> User asks: "Bind Tab to switch buffers."
>
> Refuse — `<Tab>` collides with the jumplist (`<C-i>` = `<Tab>` in many terminals) and with completion menu navigation. Propose an alternative inside the existing taxonomy: `<S-l>` is already bound to next-buffer.

## Note on `<Leader>rn` and `<Leader>ca`

These are sometimes proposed for LSP rename / code action — but the user is on Neovim 0.11+ defaults `grn` and `gra`. Recommend `grn`/`gra` first; only add `<Leader>rn`/`<Leader>ca` if the user explicitly asks for the leader-prefix flavor.
