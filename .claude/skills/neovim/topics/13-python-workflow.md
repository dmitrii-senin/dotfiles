---
session: 13
title: Python Workflow
phase: D
prerequisites: [8, 9, 11]
duration: 60 min
---

# Session 13 — Python Workflow

## 1. Objective

Wire up a productive Python daily workflow: pyright/basedpyright + ruff (LSP + format), virtualenv detection, pytest via neotest (or terminal), debugpy via nvim-dap-python. After this session, your Python inner loop (edit → check → test → debug) is fast and the LSP knows about your venv.

## 2. Why it matters

Python's tooling is fragmented (mypy / pyright / pylance / basedpyright / ruff / black / isort / flake8 / pytest / unittest / coverage / debugpy). The right modern stack is small: **basedpyright + ruff + pytest + debugpy**. Your config has 3 of those wired; this session connects the dots and shows where to leave Neovim for the terminal.

## 3. Core concepts

### LSP — pyright vs basedpyright vs ruff

- **pyright** (Microsoft, type checker). Mature. Slow on huge repos. Default for type checking.
- **basedpyright** — fork of pyright, more permissive (e.g., catches more issues), faster, drop-in compatible. **Recommended swap.**
- **ruff** as an LSP. Provides lint diagnostics on save. Fast (Rust-based). Use *alongside* pyright/basedpyright.
- **ruff** as a formatter (your current usage via conform). Identical to `ruff format`, replaces black + isort.

**Pattern:** **basedpyright for types + ruff (LSP) for diagnostics + ruff (formatter) for format-on-save.**

### Virtualenv detection

LSPs need to know which Python interpreter you use (so they can resolve imports). Detection order:

1. `VIRTUAL_ENV` env var — if you `source .venv/bin/activate` BEFORE launching Neovim, pyright/basedpyright pick it up.
2. `.venv/` or `venv/` in project root — pyright auto-detects.
3. Explicit config — `vim.lsp.config('pyright', { settings = { python = { pythonPath = '/path/to/python' } } })`.

For workflows where you switch venvs mid-session, install [`venv-selector.nvim`](https://github.com/linux-cultist/venv-selector.nvim). OPTIONAL; your config doesn't have it.

### Linting (ruff)

Ruff replaces flake8 / pylint / pycodestyle / pydocstyle / many isort rules. Configure via `pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "B", "UP"]   # pycodestyle, pyflakes, isort, bugbear, pyupgrade
ignore = ["E501"]                            # line too long (let format handle it)
```

### Formatting

Your `conform.lua:20` already does `python = { "ruff_format" }`. That's the modern path — `ruff format` is the black-compatible formatter built into ruff, single binary, very fast.

### Testing — pytest

Two patterns:

**A) Terminal + pytest (the simple, honest path)**
```
:term pytest tests/test_foo.py::test_bar -x --ff -vv
```
or in a zellij pane. The `-x --ff` (stop on first fail, run failures first) loop is the canonical TDD inner loop.

**B) `neotest` + `neotest-python` (editor-integrated)**
- Discover tests in current file via tree.
- Run with `<Leader>tn` (nearest), `<Leader>tf` (file), `<Leader>tt` (all).
- Inline pass/fail markers in the gutter.
- Send failure output to a side panel.

Your config does NOT have neotest. Adding it is OPTIONAL; the terminal pattern is excellent.

### Debugging — debugpy via nvim-dap-python

Your `dap.lua:21` does `require("dap-python").setup("python3")`. This:
- Wires `debugpy` (must be installed: `pip install debugpy` per venv).
- Auto-creates configs for: launch current file, run pytest under cursor, run with args.
- Picks up the active venv automatically.

Maps inherited from `<Leader>db/dc/do/di/du` (your config).

### Testing-while-debugging

`require('dap-python').test_method()` runs the test under cursor in debugpy. Useful when one specific test fails mysteriously.

## 4. Config notes

- `lspconfig.lua:108` — `vim.lsp.config('pyright', {})`. Default config. Audit candidate: switch to basedpyright.
- `conform.lua:20` — `python = { "ruff_format" }`. Modern.
- `dap.lua:21` — `require("dap-python").setup("python3")`. Will use active venv.
- **Gaps:**
  - No ruff LSP (only as formatter).
  - No venv-selector (need to activate venv before launching nvim).
  - No neotest.

## 5. Concrete examples

### Set up a project

```bash
cd ~/projects/myapp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt debugpy pytest
nvim
```

Open a `.py` file. `:LspInfo` shows pyright attached with `root_dir` at the project. `gd`, `K`, `grr` all work.

### Run a single test from the editor (terminal pattern)

`:term pytest tests/test_foo.py::test_bar -vv`. Output streams in the buffer. `<Esc>` to scroll up; `<C-\><C-n>` to leave terminal-mode; `i` to re-enter and re-run with `↑` then `<CR>`.

### Run a test from the editor (DAP pattern)

Cursor on a `def test_*` body:
```
:lua require('dap-python').test_method()
```
Sets a breakpoint at the test entry. `<Leader>dc` to step. `<Leader>du` to show variables.

Or map it: `vim.keymap.set("n", "<Leader>dt", require('dap-python').test_method, { desc = "[D]ebug [T]est method" })`.

### Switch venvs mid-session (without venv-selector)

```
:lua vim.lsp.stop_client(vim.lsp.get_clients({ name = "pyright" }))
:lua vim.env.VIRTUAL_ENV = "/path/to/other/.venv"
:LspStart pyright
```

Awkward. If you do this often, install `venv-selector.nvim`.

### Type-check across project

`:lua vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })` → all errors → quickfix → `]q`/`[q` to navigate.

## 6. Shortcuts to memorize

### ESSENTIAL
`K gd grr gri gra grn gO gW`  (LSP defaults)
`<Leader>cf <Leader>cd`  (your maps: format + diagnostics)
`]e [e ]w [w ]d [d`  (diagnostic nav)
`<Leader>db dc do di du`  (DAP)
`:term pytest <args>`  (terminal test loop)

### OPTIONAL
`:lua require('dap-python').test_method()`  (debug test under cursor)
`:lua require('dap-python').test_class()`  (debug test class)
`:LspInfo`  (verify pyright is on the right venv)
`:Telescope diagnostics`  (browse all diagnostics with preview)

### ADVANCED
`vim.lsp.config('basedpyright', { settings = { basedpyright = { ... } } })`
Programmatic venv switching via autocmd on `DirChanged`

## 7. Drills

1. In a Python project with a venv, `source .venv/bin/activate && nvim`. Open a `.py`. `:LspInfo` — confirm pyright's `pythonPath` matches your venv.
2. Open a function with a typo (e.g. `import jjson` instead of `import json`). Confirm pyright reports the error. `]e` to jump to it. `gra` for code action (auto-import suggestions).
3. Run pytest in `:term` for a single test. Confirm pass/fail. `<C-\><C-n>` to leave terminal mode, `i` to re-enter.
4. Set a breakpoint in a function called by a test. `:lua require('dap-python').test_method()` from inside the test. Step into the function with `<Leader>di`.
5. (Optional) Install `<Leader>tn` for "test nearest": `vim.keymap.set("n", "<Leader>tn", require('dap-python').test_method, ...)`. Test it.

## 8. Troubleshooting

- **"pyright doesn't see my imports."** Wrong venv. `:LspInfo` shows `pythonPath`. Activate the right venv before launching, OR set explicitly via `vim.lsp.config`.
- **"Diagnostics are slow on a huge file."** Pyright re-checks on every keystroke. Consider basedpyright (faster) or set `pyright.disableLanguageServices = true` for very large files (loses some features).
- **"`debugpy` not found."** Per-venv install: `pip install debugpy` IN your project's venv.
- **"Tests show in terminal but neotest doesn't pick them up."** Neotest not installed (your case). Stick with terminal pattern, or add neotest as an audit upgrade.
- **"`ruff_format` says `command not found`."** `:MasonInstall ruff` (or `pip install ruff` in venv).

## 9. Optional config edit

**Switch pyright → basedpyright (MED-impact audit upgrade):**

```diff
--- a/.config/nvim/lua/custom/plugins/lspconfig.lua
+++ b/.config/nvim/lua/custom/plugins/lspconfig.lua
@@ -107,7 +107,7 @@
-    vim.lsp.config("pyright", {})
+    vim.lsp.config("basedpyright", {})
-    vim.lsp.enable({ "lua_ls", "clangd", "rust_analyzer", "pyright" })
+    vim.lsp.enable({ "lua_ls", "clangd", "rust_analyzer", "basedpyright" })
```

After applying: `:MasonInstall basedpyright`, then `:LspRestart`. Test with a file that has type errors.

**Add ruff as an LSP (HIGH-impact audit upgrade):**

```diff
--- a/.config/nvim/lua/custom/plugins/lspconfig.lua
+++ b/.config/nvim/lua/custom/plugins/lspconfig.lua
@@ -107,8 +107,9 @@
     vim.lsp.config("pyright", {})
+    vim.lsp.config("ruff", {})
-    vim.lsp.enable({ "lua_ls", "clangd", "rust_analyzer", "pyright" })
+    vim.lsp.enable({ "lua_ls", "clangd", "rust_analyzer", "pyright", "ruff" })
```

Then `:MasonInstall ruff`. ASK before applying either.

**Add `<Leader>tn` for test-nearest (debugpy):**

```diff
--- a/.config/nvim/lua/custom/plugins/dap.lua
+++ b/.config/nvim/lua/custom/plugins/dap.lua
@@ -10,6 +10,7 @@
       { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
       { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
       { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
+      { "<leader>tn", function() require("dap-python").test_method() end, desc = "Debug nearest test", ft = "python" },
     },
```

(Note: `<Leader>tn` is in the `<Leader>t*` toggle/test prefix — fits.)

## 10. Next-step upgrades

- **`venv-selector.nvim`** if you switch venvs mid-session.
- **`neotest` + `neotest-python`** for editor-integrated test discovery + run + jump-to-failure. Adds a panel UI.
- **`coverage.nvim`** for inline test coverage marks (gutter).

## 11. Connects to

Next: **Session 14 — Rust Workflow**. Different again: rust-analyzer's runnables/debuggables, inlay hints that earn their keep, cargo-driven feedback loops.
