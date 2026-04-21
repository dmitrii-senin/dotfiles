# Reference: Customization Rules + Audit-Mode Upgrade Candidates

Two purposes:
1. **Customization rules** — how the coach should adapt recommendations along language / build-system / debugger axes.
2. **Audit upgrade candidates** — the concrete improvement list `/neovim-mastery audit` should produce against the user's current config, ranked by impact.

---

## Customization rules

### By language

**C++**
- LSP: `clangd` (already configured with `--background-index --clang-tidy --header-insertion=iwyu --completion-style=detailed --function-arg-placeholders --fallback-style=Google`).
- Compilation database: `compile_commands.json` is required for clangd to be useful. Generate via:
  - CMake: `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, then symlink `build/compile_commands.json` to project root.
  - Bazel: `bazel-compile-commands-extractor`.
  - Make / hand-rolled: `bear -- make`.
- Format: clang-format Google (already set).
- Debug: codelldb via nvim-dap (already wired).
- Quickfix discipline: clangd diagnostics flow into `vim.diagnostic`; jump with `]e/[e` and `]w/[w`.

**Python**
- LSP: `pyright` currently. Consider `basedpyright` as a more permissive, faster fork with extra checks.
- Lint + format: `ruff` is currently used as a *formatter only* (via conform). Consider also adding `ruff` as an LSP server (`vim.lsp.config('ruff', {})`) to get diagnostics-on-save without conform overhead.
- Virtualenv detection: pyright auto-detects `.venv/` in project root. For non-standard paths, consider `venv-selector.nvim` or a per-project `.python-version` symlink. The user does NOT currently use venv-selector.
- Test: pytest (no test runner integration yet — neotest-python would slot in).
- Debug: `nvim-dap-python` already wired with `python3` (will use `.venv/bin/python` if active).

**Rust**
- LSP: `rust_analyzer` directly (NOT rustaceanvim — keeps parity with how other LSPs are wired).
- Inlay hints: enable per-buffer via `vim.lsp.inlay_hint.enable()`; toggle `<Leader>th`.
- Cargo: TUI via `:term cargo build` in a zellij pane; or set up an overseer task. Don't try to redirect cargo output to quickfix — cargo's terminal output is rich and meant to be read.
- Crates: `crates.nvim` adds inline version info in `Cargo.toml`. Optional but useful.
- Debug: shared codelldb config with C++ (`dap.lua:43`).
- `checkOnSave = clippy` is already on. `cargo.allFeatures = true` and `procMacro.enable = true` also set.

### By build system

| Build system | `compile_commands.json` source                                             | Build invocation                            |
| ------------ | -------------------------------------------------------------------------- | ------------------------------------------- |
| **CMake**    | `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ln -sf build/compile_commands.json .` | `cmake --build build` or `:make` |
| **Bazel**    | `bazel run @bazel_compile_commands//:refresh`                              | `bazel build //...`                         |
| **Meson**    | meson generates it automatically in build dir; symlink to root             | `meson compile -C build`                    |
| **Cargo**    | n/a (rust_analyzer doesn't need one)                                       | `cargo build` / `cargo check`               |
| **Make**     | `bear -- make`                                                             | `:make` (uses `errorformat`)                |

### By debugger

| Debugger     | Best fit              | Adapter source                            | Notes                                                                                     |
| ------------ | --------------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------- |
| **codelldb** | C++, Rust on macOS+Linux | mason → `~/.local/share/nvim/mason/bin/codelldb` (already wired) | The user's default. Reliable, supports both C++ and Rust with shared config.        |
| **lldb-vscode** | C++ on macOS (fallback) | system `xcrun -f lldb-vscode`           | Use only if codelldb is unavailable.                                                       |
| **gdb**      | C++ on Linux          | system `gdb`                              | Use for kernel/embedded; otherwise codelldb is more ergonomic.                             |
| **debugpy**  | Python                | `pip install debugpy` per venv; `nvim-dap-python` wires it (already done) | Per-venv install. The user runs `python3` setup which picks up the active venv.  |

### By project type

- **Single-binary Rust crate** → cargo-direct workflow. No overseer needed. `:term cargo run` in a zellij pane.
- **Polyrepo CMake C++** → overseer.nvim with named tasks per build dir; or `:make` after pointing `makeprg` at the right invocation per-buffer.
- **Python monorepo with multiple `pyproject.toml`** → workspace-aware LSP `root_dir`. Configure pyright's `root_dir` in `vim.lsp.config('pyright', {root_dir = ...})` to use the nearest `pyproject.toml`.

### By preference

- **Minimal & owned (the user's path)** → grow the existing `~/x/dotfiles/.config/nvim/` config. Recommend additions one at a time with rationale.
- **Distro-based** → if explicitly requested, recommend Kickstart.nvim as a learning base or LazyVim as a productivity base. Not the user's path; mention only if asked.

---

## Audit-mode upgrade candidates

When `/neovim-mastery audit` runs, evaluate each candidate below against the user's current config. Rank by impact (HIGH / MED / LOW). Present a unified diff for any candidate the user wants to apply. **Never apply without confirmation.**

### HIGH

1. **Enable `vim.lsp.foldexpr` (LSP-driven folds).** ~5 lines added to `lspconfig.lua` LspAttach. Currently the user folds via treesitter only. LSP folding tracks semantic boundaries (functions, classes) more accurately, especially in Rust impl blocks and C++ template specializations.
2. **Drop `neo-tree.nvim` if oil.nvim covers your file-management needs.** The user has both. If oil is the primary explorer (default for dir navigation), neo-tree is a sidebar that probably never opens. ~1 file deletion.
3. **Add `ruff` as an LSP** (in addition to formatter via conform). Diagnostics-on-save without waiting for save-format. ~5 lines in `lspconfig.lua`.

### MED

4. **Try `basedpyright` instead of `pyright`** (one-line change in `lspconfig.lua:108` + mason install). Faster, more permissive, drop-in compatible.
5. **Wire `vim.snippet`** for built-in snippet expansion. Even one snippet (e.g. for Lua function templates) demonstrates the API. Decide later whether to add LuaSnip.
6. **Run `nvim --startuptime /tmp/startup.log` and `:Lazy profile`** once. If startup > 200ms, audit autocmd-on-FileType handlers and convert eager `lazy = false` plugins to event-based loading.

### LOW

7. **`vim.pack` exploration on a scratch config.** Not a migration — just know the surface so you understand the 0.12 direction.
8. **Add `nvim-treesitter-context`** for sticky function header. Useful in long C++ functions but adds visual noise. Optional taste call.
9. **Consider `crates.nvim`** for `Cargo.toml` inline version info. Niche but helpful when bumping deps.
10. **Add `diffview.nvim`** for three-way merge conflicts. Currently the user has lazygit (also good); diffview wins for in-buffer diff navigation.

### Discussion-only (don't change unless explicitly asked)

- **rustaceanvim wrapper.** Unnecessary if direct `vim.lsp.config('rust_analyzer', ...)` works for the user's flow. Adds an abstraction layer that diverges from how other LSPs are wired.
- **blink.cmp as a completion replacement.** Native `vim.lsp.completion.enable` is sufficient for most. blink.cmp wins for fuzzy matching and docs-popup tuning. Only swap if the user has a named complaint about native completion.
- **Switch zellij ↔ tmux.** No. The user runs zellij + zellij-nav. Don't suggest tmux.

---

## How `audit` should present results

Format the audit output as a Markdown table with: Rank | Tier | Candidate | Cost (lines / files touched) | Rationale | Action. End with a numbered prompt: "Want me to apply (1), (3), and (5)? Reply with the numbers." Wait for confirmation before any Edit/Write call.

After applying any change, refresh `references/current-config-snapshot.md` to reflect the new state.
