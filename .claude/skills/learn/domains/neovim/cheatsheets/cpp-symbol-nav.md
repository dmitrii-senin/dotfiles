# C++ symbol navigation (CLion parity)

Lookup card for the moment your CLion muscle memory reaches for a keystroke that doesn't exist in Neovim. All keys reflect your 0.12+ config (Telescope-backed `gd`/`grr`/`gri`/`gO`/`gW`). Requires clangd attached.

## CLion -> Neovim mapping

| CLion action                  | CLion shortcut       | Neovim equivalent                                                | Notes |
|-------------------------------|----------------------|------------------------------------------------------------------|-------|
| Go to Definition              | `Cmd-B` / `Cmd-Click`| `gd`                                                             | Telescope picker when multiple matches |
| Go to Declaration             | `Cmd-Y`              | `gD`                                                             | Useful from `.cpp` back to `.h` decl |
| Go to Implementation          | `Cmd-Opt-B`          | `gri`                                                            | Concrete impls of virtual / abstract |
| Go to Type Definition         | `Ctrl-Shift-B`       | `<Leader>ft`                                                     | Telescope `lsp_type_definitions` |
| Find Usages                   | `Opt-F7`             | `grr`                                                            | Telescope picker; `<C-q>` -> quickfix |
| Call Hierarchy                | `Ctrl-Opt-H`         | `:lua vim.lsp.buf.incoming_calls()`                              | Bind to `<Leader>ci` for daily use |
| (outgoing calls)              | (in same panel)      | `:lua vim.lsp.buf.outgoing_calls()`                              | Bind to `<Leader>co` |
| Type Hierarchy (subtypes)     | `Ctrl-H`             | `:lua vim.lsp.buf.typehierarchy("subtypes")`                     | Bind to `<Leader>cs` |
| Type Hierarchy (supertypes)   | (same dialog)        | `:lua vim.lsp.buf.typehierarchy("supertypes")`                   | Bind to `<Leader>cS` |
| Switch Header/Source          | `Ctrl-Cmd-Up`        | `:LspClangdSwitchSourceHeader` (or `:ClangdSwitchSourceHeader`)  | Bind to `<Leader>ch` |
| Quick Documentation           | `F1`                 | `K`                                                              | Hover; press `K` twice to enter the float |
| Parameter Info                | `Cmd-P`              | `<C-s>` in insert mode                                           | `vim.lsp.buf.signature_help` |
| Rename                        | `Shift-F6`           | `grn`                                                            | Workspace-wide; preview with `grr` first |
| Code Action / Refactor This   | `Opt-Enter`          | `gra` or `<Leader>ca`                                            | Includes extract function, fix-it, IWYU |
| File Structure                | `Cmd-F12`            | `gO`                                                             | Telescope `lsp_document_symbols` |
| Workspace Symbol              | `Cmd-Opt-O`          | `gW`                                                             | Telescope `lsp_dynamic_workspace_symbols` |
| Recent Files                  | `Cmd-E`              | `<Leader>fo` or `:Telescope oldfiles`                            | |
| Go to Line                    | `Cmd-L`              | `:<n>` or `<n>G`                                                 | |
| Back / Forward                | `Cmd-[` / `Cmd-]`    | `<C-o>` / `<C-i>`                                                | Jump list, not history list |
| Reformat Code                 | `Cmd-Opt-L`          | `<Leader>cf`                                                     | conform.nvim; auto on save |

## Reading-an-unfamiliar-file routine

1. `gO` -- skim file structure (classes, methods)
2. `K` on any type to see its docs / declaration
3. `gd` on a method call -> jump into the implementation
4. Cursor on the function name -> `:lua vim.lsp.buf.incoming_calls()` to see who calls it
5. `<C-o>` repeatedly to walk back up your path

## Tracing a virtual call

1. Cursor on the abstract method declaration
2. `gri` -- Telescope shows every concrete implementation
3. Pick the one you care about, jump in
4. On the class name: `:lua vim.lsp.buf.typehierarchy("supertypes")` to confirm the inheritance chain

## Refactoring a field across an SBE message family

1. `grr` on the field name -- count the reference sites in the Telescope picker
2. `<C-q>` to dump them into quickfix (lets you scan all sites at once)
3. `grn` to rename -- clangd issues a workspace edit
4. `:G diff` (or `git diff`) to verify every site updated and no surprise files were touched

## When `gd` lands on the wrong thing

| Symptom                                | Recovery                                                        |
|----------------------------------------|-----------------------------------------------------------------|
| `gd` lands on primary template         | `gri` -- pick the right specialization from the impl list       |
| `gd` lands on header decl, you wanted impl | `gd` again from the decl; or `gri`                          |
| Multiple overloads in the Telescope picker | Type a fragment of the param signature in the prompt        |
| Clangd hasn't indexed yet              | `:LspInfo` -- check status; wait for background-index to finish |
| Wrong project root                     | `:lua vim.print(vim.lsp.get_clients({name="clangd"})[1].config.root_dir)` -- verify it points at the project, not `.git` parent |

## Include navigation (no LSP needed)

| Key       | Action                                                  |
|-----------|---------------------------------------------------------|
| `gf`      | open file under cursor (e.g. on `#include "foo.h"`)     |
| `<C-w>f`  | open under cursor in a split                            |
| `<C-w>gf` | open under cursor in a new tab                          |
| `:checkpath` | report unresolved includes for current buffer        |

Set `path` to cover system + project + generated include directories so `gf` works across the chain.

## Source of truth

Config: `~/x/dotfiles/.config/nvim/lua/plugins/lsp/` and `~/x/dotfiles/.config/nvim/lua/keymaps.lua`. If a key here disagrees with your live config, the config wins -- update this cheatsheet.
