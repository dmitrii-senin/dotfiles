# Neovim Mastery Curriculum

A staged, 16-session ladder. Each session is a single topic file under `topics/`. Sessions are individually addressable — jump anywhere, but respect prereqs where listed.

## Phases

| Phase | Theme                          | Sessions |
| ----- | ------------------------------ | -------- |
| **A** | Foundations (no plugins)       | 1–5      |
| **B** | Modern Neovim configuration    | 6–7      |
| **C** | IDE features                   | 8–11     |
| **D** | Language workflows             | 12–14    |
| **E** | Operational mastery            | 15–16    |

## Sessions

| #   | Phase | Title                                       | Objective                                                                                  | Prereqs |
| --- | ----- | ------------------------------------------- | ------------------------------------------------------------------------------------------ | ------- |
| 01  | A     | Mental model & modal editing                | Internalize modes, the operator-motion grammar, and `:help` discipline.                    | —       |
| 02  | A     | Motions & text objects                      | Move and select by structure, not by character.                                            | 1       |
| 03  | A     | Operators, registers, macros                | Compose edits with operators and registers; record macros; replay edits.                   | 2       |
| 04  | A     | Buffers, windows, tabs                      | Build the right mental model: buffers are files, windows are viewports, tabs are layouts. | 1       |
| 05  | A     | Search, substitute, ex commands             | Drive bulk edits with `/`, `:s`, `:g`, `:norm`, `:argdo`, very-magic mode.                 | 2, 3    |
| 06  | B     | Lua config structure                        | Organize `init.lua` and `lua/` modules for clarity, lazy-loading, and 5-year maintainability. | —       |
| 07  | B     | Plugin architecture (lazy.nvim + vim.pack)  | Lazy-load by event/cmd/ft/keys; understand `vim.pack` as the 0.12 builtin alternative.     | 6       |
| 08  | C     | LSP, completion, diagnostics                | Master `vim.lsp.config`/`enable`, native `vim.lsp.completion`, `vim.diagnostic.jump`, and the 0.11+ default keymaps. | 6, 7    |
| 09  | C     | Treesitter & structural editing             | Use treesitter parsers and textobjects (`af/if/ac/ic/aa/ia`, `]m/[m`, swap) for real refactors. | 2, 8    |
| 10  | C     | Fuzzy finding & project navigation          | Be fluent with telescope pickers and the `:grep + quickfix` fallback.                      | 5, 8    |
| 11  | C     | Quickfix, location lists, project refactor  | Drive cross-file refactors with `:grep` → quickfix → `:cdo s/.../.../g | update`.          | 5, 10   |
| 12  | D     | C++ workflow                                | clangd + `compile_commands.json`, header/source switch, codelldb debug, build via overseer or `:make`. | 8, 9, 11 |
| 13  | D     | Python workflow                             | pyright/basedpyright, ruff (LSP + format), virtualenv detection, pytest via neotest, debugpy. | 8, 9, 11 |
| 14  | D     | Rust workflow                               | rust_analyzer (direct vs rustaceanvim tradeoff), inlay hints, `crates.nvim`, codelldb debug. | 8, 9, 11 |
| 15  | E     | Build / run / test / debug orchestration    | overseer.nvim, neotest, nvim-dap patterns shared across languages; when to leave for terminal. | 12, 13, 14 |
| 16  | E     | Git, performance, long-term config evolution | gitsigns + lazygit + diffview; `nvim --startuptime` and `:Lazy profile`; pruning conventions. | 7, 15   |

---

## Keyword map

When `$ARGUMENTS` is a keyword (not a number, not `list`/`audit`/`review`/`free`), resolve as follows. Match case-insensitively. If multiple keywords match, prefer the more specific session.

| Keyword(s)                                    | → Session |
| --------------------------------------------- | --------- |
| `mental`, `model`, `vim`, `modes`             | 1         |
| `motion`, `motions`, `textobject`, `textobjects` | 2      |
| `operator`, `operators`, `register`, `registers`, `macro`, `macros` | 3 |
| `buffer`, `buffers`, `window`, `windows`, `tab`, `tabs`, `layout` | 4 |
| `search`, `substitute`, `ex`, `regex`, `grep` (without `live`/`telescope`) | 5 |
| `lua`, `init.lua`, `config`, `structure`      | 6         |
| `plugin`, `plugins`, `lazy`, `lazy.nvim`, `vim.pack`, `pack` | 7 |
| `lsp`, `completion`, `diagnostic`, `diagnostics`, `clangd`, `pyright`, `rust-analyzer`, `rust_analyzer`, `mason` | 8 |
| `ts`, `treesitter`, `tree-sitter`, `parser`, `parsers`, `structural` | 9 |
| `telescope`, `fuzzy`, `picker`, `live_grep`, `find files` | 10 |
| `quickfix`, `qf`, `loclist`, `location`, `refactor`, `cdo`, `cfdo` | 11 |
| `cpp`, `c++`, `c`, `clang`, `cmake`          | 12        |
| `python`, `py`, `pyright`, `ruff`, `pytest`, `venv`, `virtualenv`, `debugpy` | 13 |
| `rust`, `cargo`, `rustaceanvim`, `crates`    | 14        |
| `dap`, `debug`, `debugger`, `codelldb`, `build`, `run`, `test`, `neotest`, `overseer`, `task` | 15 |
| `git`, `gitsigns`, `lazygit`, `diffview`, `perf`, `performance`, `startuptime`, `profile`, `evolution`, `prune` | 16 |

If a keyword is ambiguous (e.g., the user types `lsp clangd`), pick the more specific session (12 over 8). If it's unresolvable, list 2–3 candidate sessions and ask.

---

## Recommended starting points

- **From scratch (rare for this user):** Session 1.
- **The user's actual baseline (mature config, modern LSP API already wired):** Session 8 first, then 9 → 10 → 11 → 12/13/14 in any order, then 15 → 16.
- **Before any deep dive:** consider running `/neovim-mastery audit` once to surface the highest-leverage upgrades on the current config.
- **For a one-off question:** `/neovim-mastery free <question>` skips the curriculum entirely.

---

## Phase legend

- **A — Foundations.** Pure Vim. No plugins. The grammar that everything else builds on.
- **B — Modern configuration.** How to organize Lua and how to manage plugins (with lazy.nvim today and `vim.pack` as the 0.12 future).
- **C — IDE features.** The pieces that turn Neovim into an IDE: LSP, treesitter, fuzzy finding, project search.
- **D — Language workflows.** Per-language fluency for the user's stack (C++, Python, Rust).
- **E — Operational mastery.** Build/test/debug orchestration; git; performance; long-term care of the config itself.
